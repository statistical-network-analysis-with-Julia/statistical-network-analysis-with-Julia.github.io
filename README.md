# Statistical Network Analysis with Julia — website

The umbrella website connects 15 Julia packages, their documentation and worked
network analyses. Built with Franklin.jl; individual package sites use Documenter.

**Published site:** <https://statistical-network-analysis-with-julia.github.io/>

## Preview the complete documentation locally

Use Julia 1.12+, Python 3.11+ and the sibling package checkouts. From this site
repository, prepare the shared environment, build the sites and start the preview:

```bash
julia tools/prepare_workspace.jl ..
python3 tools/preview_docs.py --build
```

Open <http://localhost:8001/>. The package directory links to the local package
sites, for example <http://localhost:8001/Networks.jl/dev/>. Their ecosystem footers
link back to the same umbrella preview. Both `/dev/` and `/stable/` show the
current local build; they are not separate release versions.

Add `--clone` to the workspace preparation command when checkouts are missing.
It preserves existing repositories. See [the workspace recipe](tools/workspace/README.md)
for a fresh workspace. Initial setup/builds need network access for dependencies.

With existing builds, `python3 tools/preview_docs.py` starts immediately. Use
`--port=8002` for another port, `--root=/path/to/workspace` for another workspace,
or `--build-only` to validate all sites and exit. The local build command clears
CI deployment configuration before running Documenter.

## Edit the umbrella site

For Franklin's automatic rebuilds while editing:

```bash
julia --project -e 'using Pkg; Pkg.instantiate()'
julia --project -e 'using Franklin; serve()'
```

Franklin uses <http://localhost:8000/> by default. Keep the combined server on
port 8001 to browse package links while Franklin updates `__site/`. Rebuild
package documentation after editing package pages:

```bash
cd ../Networks.jl
DOCS_PRETTY_URLS=true julia --project=docs docs/make.jl
```

The homepage lives in `index.md`; the package directory in `packages/index.md`;
installation guidance in `getting-started/index.md`. Shared umbrella styles and
behavior live in `_css/style.css`, `_assets/site.js` and `_layout/`.

## Maintain the package icons

Package sites use Documenter's default themes. The [canonical package icons](tools/docs-theme/README.md)
are copied into each package so it can build independently. After editing the icons:

```bash
julia tools/sync_documentation_theme.jl
julia tools/sync_documentation_theme.jl --check
```

Keep each package's `docs/make.jl` strict. Do not hand-edit generated `docs/build/`
or `__site/` files. Update `capabilities.md` through its generator.

## Validate and publish

See [tools/README.md](tools/README.md) for executable examples, capability checks,
benchmarks, isolated installation and local-preview tests. The site deploys
through `.github/workflows/deploy.yml` after a push to `main`. Package documentation
has separate workflows; coordinate changes across repositories before publishing.
Local builds and previews do not publish anything.
