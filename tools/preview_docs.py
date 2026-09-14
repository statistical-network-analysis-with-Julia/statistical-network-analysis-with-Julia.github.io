#!/usr/bin/env python3
"""Preview Franklin and all package documentation together (Python 3.11+).

Run from any directory. --build rebuilds first; --build-only builds and exits.
The workspace must already be prepared with tools/prepare_workspace.jl.
Both /Package.jl/dev/ and /Package.jl/stable/ show its local docs/build output;
these aliases do not represent distinct released versions.
"""

from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import mimetypes
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib
from urllib.parse import quote, unquote, urlsplit


SITE_NAME = "statistical-network-analysis-with-Julia.github.io"
DEFAULT_ROOT = Path(__file__).resolve().parents[2]
# Franklin can copy project files into __site. Only browser-facing output is
# served, even when a source/configuration file happens to be in a build tree.
WEB_SUFFIXES = frozenset({
    ".html", ".htm", ".css", ".js", ".json", ".xml", ".txt", ".inv",
    ".svg", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".avif", ".ico",
    ".woff", ".woff2", ".ttf", ".otf", ".eot", ".pdf", ".mp4", ".webm",
    ".ogg", ".mp3", ".wav", ".wasm",
})


class RouteError(Exception):
    def __init__(self, status: int, message: str):
        self.status = status
        self.message = message
        super().__init__(message)


class Workspace:
    def __init__(self, root: Path):
        self.root = root.expanduser().resolve()
        self.site = self.root / SITE_NAME
        recipe = self.site / "tools" / "workspace" / "Project.toml"
        with recipe.open("rb") as stream:
            project = tomllib.load(stream)
        self.packages = []
        for name in sorted(project["deps"]):
            directory = project["sources"][name]["path"]
            if directory != name + ".jl" or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*\.jl", directory):
                raise ValueError(f"Invalid package directory in {recipe}: {directory!r}")
            self.packages.append(directory)
        self.mounts = {"": self.site / "__site"}
        self.mounts.update({name: self.root / name / "docs" / "build" for name in self.packages})

    def missing_builds(self) -> list[str]:
        return [name or "Franklin site" for name, build in self.mounts.items()
                if not (build / "index.html").is_file()]

    def route(self, target: str) -> tuple[Path | bytes | None, str | None]:
        """Return a confined file, local metadata or a canonical redirect."""
        if any(ord(char) < 32 or ord(char) == 127 for char in target):
            raise RouteError(400, "Invalid control character in URL")
        try:
            url = urlsplit(target)
            if url.scheme or url.netloc or not target.startswith("/") or target.startswith("//"):
                raise ValueError("Expected an origin-relative URL")
            if re.search(r"%(?![0-9A-Fa-f]{2})", url.path):
                raise ValueError("Invalid percent escape")
            path = unquote(url.path, errors="strict")
        except (ValueError, UnicodeError) as error:
            raise RouteError(400, "Invalid request URL") from error
        if "\\" in path or any(ord(char) < 32 or ord(char) == 127 for char in path):
            raise RouteError(403, "Forbidden path")
        parts = path.strip("/").split("/") if path.strip("/") else []
        if any(part in (".", "..") or part.startswith(".") for part in parts):
            raise RouteError(403, "Forbidden path")
        if "//" in path:
            raise RouteError(400, "Repeated path separator")

        def redirect(destination: str) -> tuple[None, str]:
            location = quote(destination, safe="/-._~")
            return None, location + ("?" + url.query if url.query else "")

        package = parts[0] if parts and parts[0] in self.packages else ""
        build = self.mounts[package]
        if package:
            if len(parts) == 1:
                return redirect(f"/{package}/dev/")
            # Documenter references these scripts from makedocs output but only
            # writes them during deployment. Supply local aliases in memory;
            # do not deploy or modify package build directories to create them.
            if parts[1:] == ["versions.js"] and not path.endswith("/"):
                return b'// Both aliases show this local build.\nvar DOC_VERSIONS = ["dev", "stable"];\n', None
            if parts[1] not in ("dev", "stable"):
                raise RouteError(404, "Use the package's /dev/ or /stable/ preview")
            if parts[2:] == ["siteinfo.js"] and not path.endswith("/"):
                return (f'var DOCUMENTER_CURRENT_VERSION = "{parts[1]}";\n'
                        'var DOCUMENTER_IS_DEV_VERSION = true;\n').encode(), None
            relative = parts[2:]
        else:
            relative = parts
        candidate = build.joinpath(*relative)

        def confined(file: Path) -> Path:
            try:
                resolved = file.resolve()
            except (OSError, RuntimeError) as error:
                raise RouteError(403, "Forbidden path") from error
            # Keep the lexical build root: even a build-root symlink must not
            # silently turn the preview into a server for some other directory.
            if not resolved.is_relative_to(build):
                raise RouteError(403, "Path leaves the documentation build")
            return resolved

        candidate = confined(candidate)
        if candidate.is_dir():
            index = confined(candidate / "index.html")
            if index.is_file():
                if index.suffix.lower() not in WEB_SUFFIXES:
                    raise RouteError(404, "Only generated pages and web assets are served")
                if not path.endswith("/"):
                    return redirect(path + "/")
                return index, None
        elif candidate.is_file() and not path.endswith("/"):
            if candidate.suffix.lower() not in WEB_SUFFIXES:
                raise RouteError(404, "Only generated pages and web assets are served")
            return candidate, None

        # Preserve older .html links to Franklin/Documenter pretty-URL pages.
        if candidate.suffix.lower() == ".html":
            pretty_index = confined(candidate.with_suffix("") / "index.html")
            if pretty_index.is_file():
                return redirect(path[:-5] + "/")
        # Also support an existing non-pretty Documenter build. Redirecting to
        # its actual URL preserves the relative asset and navigation bases.
        if not candidate.suffix and relative:
            flat = confined(candidate.with_suffix(".html"))
            if flat.is_file():
                return redirect(path.rstrip("/") + ".html")
        if not (build / "index.html").is_file():
            raise RouteError(404, "Documentation has not been built; run tools/preview_docs.py --build")
        raise RouteError(404, "No generated page or asset exists at this URL")


def build_environment(source: dict[str, str] | None = None) -> dict[str, str]:
    """Remove Documenter's CI detectors and deployment credentials.

    Documenter auto_detect_deploy_system checks TRAVIS_REPO_SLUG,
    GITHUB_REPOSITORY, GITLAB_CI, BUILDKITE and CI (Woodpecker/Drone).
    Clear their families too, including tokens and preview deployment keys.
    """
    source = os.environ if source is None else source
    blocked = ("CI_", "TRAVIS_", "GITHUB_", "GITLAB_", "BUILDKITE_", "DOCUMENTER_")
    result = {key: value for key, value in source.items()
              if key not in ("CI", "TRAVIS", "GITLAB", "BUILDKITE")
              and not key.startswith(blocked)}
    result["DOCS_PRETTY_URLS"] = "true"
    return result


def build_docs(workspace: Workspace) -> None:
    env = build_environment()
    jobs = [(workspace.site, workspace.site,
             "using Pkg; Pkg.instantiate(); using Franklin; "
             "optimize(minify=false, prerender=false)", [])]
    for package in workspace.packages:
        repo = workspace.root / package
        jobs.append((repo, repo / "docs",
                     "using Pkg; Pkg.instantiate(); using Documenter; "
                     "Documenter.auto_detect_deploy_system() === nothing || "
                     "error(\"Local preview refuses a deployment environment\"); "
                     "include(ARGS[1])", [str(repo / "docs" / "make.jl")]))
    for cwd, project, code, arguments in jobs:
        print(f"Building {cwd.name} locally", flush=True)
        subprocess.run(["julia", "--startup-file=no", f"--project={project}",
                        "-e", code, *arguments], cwd=cwd, env=env, check=True)


def handler_for(workspace: Workspace) -> type[BaseHTTPRequestHandler]:
    class PreviewHandler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"
        server_version = "LocalDocsPreview/1"

        def do_HEAD(self):
            self._serve()

        def do_GET(self):
            self._serve()

        def _serve(self):
            try:
                # BaseHTTPRequestHandler normalizes a leading // in self.path;
                # retain the original target so that it cannot become a redirect.
                target = self.requestline.split()[1]
                file, location = workspace.route(target)
                if location is not None:
                    self.send_response(301)
                    self.send_header("Location", location)
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return
                assert file is not None
                if isinstance(file, bytes):
                    self.send_response(200)
                    self.send_header("Content-Type", "text/javascript; charset=utf-8")
                    self.send_header("Content-Length", str(len(file)))
                    self.send_header("Cache-Control", "no-cache")
                    self.send_header("X-Content-Type-Options", "nosniff")
                    self.end_headers()
                    if self.command != "HEAD":
                        self.wfile.write(file)
                    return
                with file.open("rb") as stream:
                    stat = os.fstat(stream.fileno())
                    mime = mimetypes.guess_type(file.name)[0] or "application/octet-stream"
                    if mime.startswith("text/"):
                        mime += "; charset=utf-8"
                    self.send_response(200)
                    self.send_header("Content-Type", mime)
                    self.send_header("Content-Length", str(stat.st_size))
                    self.send_header("Last-Modified", self.date_time_string(stat.st_mtime))
                    self.send_header("Cache-Control", "no-cache")
                    self.send_header("X-Content-Type-Options", "nosniff")
                    self.end_headers()
                    if self.command != "HEAD":
                        shutil.copyfileobj(stream, self.wfile)
            except RouteError as error:
                self.send_error(error.status, error.message)
            except (FileNotFoundError, IsADirectoryError):
                self.send_error(404, "Build output changed; refresh after the build finishes")
            except PermissionError:
                self.send_error(403, "Cannot read this build output")
            except (BrokenPipeError, ConnectionResetError):
                pass

    return PreviewHandler


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path,
                        default=Path(os.environ.get("SNWJ_ROOT", DEFAULT_ROOT)),
                        help="workspace containing the site and sibling packages")
    parser.add_argument("--port", type=int, default=8001,
                        help="loopback port (default: 8001)")
    build = parser.add_mutually_exclusive_group()
    build.add_argument("--build", action="store_true", help="build all documentation before serving")
    build.add_argument("--build-only", action="store_true", help="build all documentation and exit")
    args = parser.parse_args(argv)
    if not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    try:
        workspace = Workspace(args.root)
        if args.build or args.build_only:
            build_docs(workspace)
        missing = workspace.missing_builds()
        if missing:
            print("Missing builds: " + ", ".join(missing), file=sys.stderr)
            print("Prepare sibling checkouts with tools/prepare_workspace.jl, then run "
                  "python3 tools/preview_docs.py --build.", file=sys.stderr)
        if args.build_only:
            return 1 if missing else 0
        with ThreadingHTTPServer(("127.0.0.1", args.port), handler_for(workspace)) as server:
            print(f"Preview: http://127.0.0.1:{args.port}/ (PID {os.getpid()})", flush=True)
            print(f"{len(workspace.packages)} package routes: /Package.jl/dev/ and /stable/ "
                  "both use the local build. Ctrl-C stops the server.", flush=True)
            server.serve_forever()
    except KeyboardInterrupt:
        return 0
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"Preview failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
