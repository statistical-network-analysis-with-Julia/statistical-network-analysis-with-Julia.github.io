"""Run with: python3 -B -m unittest discover -s tools/test -p 'test_*.py'."""

import contextlib
import http.client
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "preview_docs.py"
spec = importlib.util.spec_from_file_location("preview_docs", SCRIPT)
preview = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preview)


class PreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="combined docs preview ")
        cls.root = Path(cls.temp.name)
        cls.site = cls.root / preview.SITE_NAME
        recipe = cls.site / "tools/workspace/Project.toml"
        recipe.parent.mkdir(parents=True)
        recipe.write_bytes((SCRIPT.parent / "workspace/Project.toml").read_bytes())
        cls.workspace = preview.Workspace(cls.root)
        for package, build in cls.workspace.mounts.items():
            build.mkdir(parents=True)
            (build / "index.html").write_text(f"<html>{package or 'ecosystem'}</html>")
        cls.build = cls.site / "__site"
        (cls.build / "packages").mkdir()
        (cls.build / "packages/index.html").write_text("<html>package catalogue</html>")
        (cls.build / "empty").mkdir()
        (cls.build / "assets").mkdir()
        (cls.build / "assets/style.css").write_text("body {color: navy}")
        (cls.build / "assets/a ?#é.css").write_text("/* encoded asset */")
        (cls.build / "Project.toml").write_text("secret project source")
        (cls.build / "example.jl").write_text("error(\"do not serve source\")")
        (cls.build / ".hidden.html").write_text("hidden")
        (cls.root / "secret.html").write_text("outside build")
        (cls.build / "escape.html").symlink_to(cls.root / "secret.html")
        (cls.build / "escape-dir").symlink_to(cls.root, target_is_directory=True)
        (cls.build / "source-index").mkdir()
        (cls.build / "source-index/index.html").symlink_to(cls.build / "Project.toml")
        docs = cls.workspace.mounts["Networks.jl"]
        (docs / "guide").mkdir()
        (docs / "guide/topic").mkdir()
        (docs / "guide/topic/index.html").write_text("<html>pretty topic</html>")
        (docs / "flat.html").write_text("<html>flat topic</html>")
        (docs / "assets").mkdir()
        (docs / "assets/app.js").write_text("window.preview = true;")
        cls.handler = preview.handler_for(cls.workspace)
        cls.handler.log_message = lambda *args: None
        cls.server = preview.ThreadingHTTPServer(("127.0.0.1", 0), cls.handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()
        cls.temp.cleanup()

    def request(self, target, method="GET"):
        connection = http.client.HTTPConnection(*self.server.server_address, timeout=5)
        try:
            connection.request(method, target)
            response = connection.getresponse()
            return response.status, dict(response.getheaders()), response.read()
        finally:
            connection.close()

    def test_all_package_mounts_and_site(self):
        self.assertEqual(len(self.workspace.packages), 15)
        self.assertEqual(self.request("/")[2], b"<html>ecosystem</html>")
        for package in self.workspace.packages:
            for version in ("dev", "stable"):
                with self.subTest(package=package, version=version):
                    status, _, body = self.request(f"/{package}/{version}/?q=one")
                    self.assertEqual(status, 200)
                    self.assertEqual(body, f"<html>{package}</html>".encode())

    def test_canonical_redirects_preserve_query_and_encoding(self):
        cases = {
            "/Networks.jl?q=a%26b": "/Networks.jl/dev/?q=a%26b",
            "/Networks.jl/": "/Networks.jl/dev/",
            "/Networks.jl/dev?x=1": "/Networks.jl/dev/?x=1",
            "/packages?x=%2f..": "/packages/?x=%2f..",
            "/packages.html?q=1": "/packages/?q=1",
            "/Networks.jl/dev/guide/topic.html": "/Networks.jl/dev/guide/topic/",
            "/Networks.jl/stable/guide/topic": "/Networks.jl/stable/guide/topic/",
            "/Networks.jl/dev/flat/": "/Networks.jl/dev/flat.html",
            "/Networks.jl/dev/flat": "/Networks.jl/dev/flat.html",
        }
        for target, expected in cases.items():
            with self.subTest(target=target):
                status, headers, body = self.request(target)
                self.assertEqual(status, 301)
                self.assertEqual(headers["Location"], expected)
                self.assertEqual(body, b"")
                self.assertEqual(self.request(expected)[0], 200)

    def test_assets_pretty_and_flat_files(self):
        for target, content, mime in (
            ("/assets/style.css", b"body {color: navy}", "text/css"),
            ("/assets/a%20%3F%23%C3%A9.css?cache=a%2Fb", b"/* encoded asset */", "text/css"),
            ("/Networks.jl/dev/guide/topic/", b"<html>pretty topic</html>", "text/html"),
            ("/Networks.jl/stable/flat.html", b"<html>flat topic</html>", "text/html"),
            ("/Networks.jl/dev/assets/app.js", b"window.preview = true;", "javascript"),
        ):
            with self.subTest(target=target):
                status, headers, body = self.request(target)
                self.assertEqual(status, 200)
                self.assertEqual(body, content)
                self.assertIn(mime, headers["Content-Type"])
                self.assertEqual(int(headers["Content-Length"]), len(content))

    def test_head_has_get_headers_without_body(self):
        for target in ("/", "/assets/style.css", "/packages.html", "/missing", "/%2e%2e/secret.html",
                       "/Networks.jl/versions.js", "/Networks.jl/dev/siteinfo.js"):
            with self.subTest(target=target):
                get_status, get_headers, _ = self.request(target)
                status, headers, body = self.request(target, "HEAD")
                self.assertEqual(status, get_status)
                self.assertEqual(headers["Content-Length"], get_headers["Content-Length"])
                self.assertEqual(headers.get("Location"), get_headers.get("Location"))
                self.assertEqual(body, b"")

    def test_documenter_deployment_metadata_uses_local_aliases(self):
        for package in self.workspace.packages:
            with self.subTest(package=package):
                status, headers, body = self.request(f"/{package}/versions.js")
                self.assertEqual(status, 200)
                self.assertIn("javascript", headers["Content-Type"])
                self.assertIn(b'var DOC_VERSIONS = ["dev", "stable"];', body)
                for version in ("dev", "stable"):
                    status, _, body = self.request(f"/{package}/{version}/siteinfo.js?local=true")
                    self.assertEqual(status, 200)
                    self.assertIn(f'var DOCUMENTER_CURRENT_VERSION = "{version}";'.encode(), body)
                    self.assertIn(b'DOCUMENTER_IS_DEV_VERSION = true', body)
                # Synthetic metadata lives only on known, exact routes.
                self.assertEqual(self.request(f"/{package}/v0.2/siteinfo.js")[0], 404)
                self.assertEqual(self.request(f"/{package}/versions.js/")[0], 404)

    def test_traversal_symlinks_and_source_files_are_not_served(self):
        attacks = (
            "/../secret.html", "/%2e%2e/secret.html", "/Networks.jl/dev/../../secret.html",
            "/Networks.jl/dev/%2e%2e%2f%2e%2e/secret.html", "/assets/%5c..%5csecret.html",
            "/escape.html", "/escape-dir/secret.html", "/.hidden.html", "/%00.html",
            "/Project.toml", "/example.jl", "/Networks.jl/src/Networks.jl", "/empty/", "/source-index/",
            "//example.com/", "/assets/%FF.css", "/assets/%zz.css", "/a//b", "/a%0d%0aLocation:x",
        )
        for target in attacks:
            with self.subTest(target=target):
                status, headers, body = self.request(target)
                self.assertIn(status, (400, 403, 404))
                self.assertNotIn("Location", headers)
                self.assertNotIn(b"outside build", body)
                self.assertNotIn(b"secret project source", body)
                self.assertNotIn(b"Directory listing", body)

    def test_build_root_symlink_cannot_broaden_the_mount(self):
        build = self.workspace.mounts["NDTV.jl"]
        saved = build.with_name("saved-build")
        elsewhere = self.root / "outside-docs"
        elsewhere.mkdir()
        (elsewhere / "index.html").write_text("outside build")
        build.rename(saved)
        try:
            build.symlink_to(elsewhere, target_is_directory=True)
            self.assertEqual(self.request("/NDTV.jl/dev/")[0], 403)
        finally:
            build.unlink()
            saved.rename(build)

    def test_missing_build_explains_next_action(self):
        index = self.workspace.mounts["NDTV.jl"] / "index.html"
        contents = index.read_bytes()
        try:
            index.unlink()
            self.assertIn("NDTV.jl", self.workspace.missing_builds())
            status, _, body = self.request("/NDTV.jl/dev/")
            self.assertEqual(status, 404)
            self.assertIn(b"--build", body)
        finally:
            index.write_bytes(contents)

    def test_build_commands_cannot_inherit_deployment_environment(self):
        contaminated = {
            "PATH": os.environ["PATH"], "HOME": str(self.root), "JULIA_NUM_THREADS": "4",
            "CI": "woodpecker", "CI_SYSTEM_VERSION": "3", "TRAVIS_REPO_SLUG": "org/repo",
            "GITHUB_REPOSITORY": "org/repo", "GITHUB_TOKEN": "test-token",
            "GITLAB_CI": "true", "BUILDKITE": "true", "DOCUMENTER_KEY": "test-key",
            "DOCUMENTER_KEY_PREVIEWS": "test-key", "DOCS_PRETTY_URLS": "false",
        }
        with patch.dict(os.environ, contaminated, clear=True), patch.object(preview.subprocess, "run") as run:
            with contextlib.redirect_stdout(io.StringIO()):
                preview.build_docs(self.workspace)
        self.assertEqual(run.call_count, 16)
        for index, call in enumerate(run.call_args_list):
            command = call.args[0]
            env = call.kwargs["env"]
            self.assertEqual(env["DOCS_PRETTY_URLS"], "true")
            self.assertEqual(env["JULIA_NUM_THREADS"], "4")
            self.assertEqual(env["HOME"], str(self.root))
            self.assertFalse(any(key in env for key in contaminated if key.startswith(
                ("CI", "TRAVIS", "GITHUB", "GITLAB", "BUILDKITE", "DOCUMENTER"))))
            self.assertIn("--startup-file=no", command)
            self.assertIn("Pkg.instantiate()", command[4])
            self.assertTrue(call.kwargs["check"])
            if index:
                self.assertIn("auto_detect_deploy_system() === nothing", command[4])
                self.assertEqual(command[-1], str(call.kwargs["cwd"] / "docs/make.jl"))
                self.assertIn("include(ARGS[1])", command[4])
            else:
                self.assertIn("optimize(minify=false, prerender=false)", command[4])

    def test_build_failure_stops_before_later_packages_or_server(self):
        error = subprocess.CalledProcessError(1, ["julia"])
        with patch.object(preview.subprocess, "run", side_effect=error) as run:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(preview.main(["--root", str(self.root), "--build-only"]), 1)
        self.assertEqual(run.call_count, 1)


if __name__ == "__main__":
    unittest.main()
