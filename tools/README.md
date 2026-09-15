# Ecosystem development and validation

These tools expect the 15 independent Julia package checkouts beside this site
repository. `SNWJ_ROOT` selects their parent directory; by default it is the
site's parent. Use Julia 1.12 or newer. The [workspace recipe](workspace/README.md)
provides the package environment and instructions for a fresh checkout.

## Prepare a workspace

From this site directory, prepare existing sibling checkouts:

```bash
julia tools/prepare_workspace.jl ..
```

Add `--clone` to fetch missing repositories. The script reads the package list
from `tools/workspace/Project.toml`, follows local source dependencies, develops
all packages together, and installs documentation dependencies into
`../.snippet-env`. Existing checkouts are preserved. The recipe uses available
GitHub revisions; unpushed local changes require the local checkouts.

## Execute documentation

```bash
julia --project=../.snippet-env tools/check_snippets.jl
julia --project=../.snippet-env tools/check_snippets.jl SNA.jl/
julia --project=../.snippet-env tools/check_snippets.jl ERGM.jl/docs/src/getting_started.md
```

The checker executes fenced `julia` blocks in every package README,
`docs/src/` page, and site page. Blocks within a file share a fresh module and
run in order, with REPL soft scope. File-writing examples use temporary scratch
directories. Full sweeps include real fitting, simulation, and animation, so
allow several minutes.

The NDTV animation-export examples require `ffmpeg` for movies and ImageMagick
(`magick` or `convert`) for GIFs on `PATH`, with SVG input support. On Ubuntu,
install them with `sudo apt-get install ffmpeg imagemagick librsvg2-bin`.
The last package supplies ImageMagick's `rsvg-convert` SVG renderer. The executable
documentation workflow installs these dependencies and checks SVG-to-GIF
conversion before running the examples.

A malformed or failing Julia block fails the command. Only explicit
`julia-repl` transcripts, `<!-- skip-check -->` blocks, environment-mutating
installation instructions, and labeled output are skipped. Use these markers
for their stated purpose; do not hide failing executable examples.

Package path filters match the repository boundary (`SNA.jl/` excludes
`TSNA.jl/`). Other filters use substring matching. Multiple filters are combined
with OR; a filter matching no Markdown files fails. Test the gate itself with:

```bash
julia tools/test/runtests.jl
```

`.github/workflows/snippets.yml` runs the complete sweep for site pushes,
pull requests, weekly schedules, and manual dispatch. Package-only changes are
picked up by the scheduled check; coordinated unpublished changes must also be
validated locally.

## Generate capability and parity tables

```bash
julia --project=../.snippet-env tools/generate_capability_matrix.jl
julia --project=../.snippet-env tools/generate_capability_matrix.jl --check
```

Never edit `capabilities.md` manually. The generator fits small models and
queries `Networks.fit_metadata`, executes StatsAPI accessors, reads golden
fixture provenance, and queries `supports_missing` plus `missing_policies`.
A failed model probe fails generation. Small successful probes establish the
reported API behavior, not general scientific validity.

`--check` compares the generated page with the existing file. Numeric literals in the
self-reported fit caveats are normalized to tolerate Monte Carlo jitter.
Other content, including fixture versions, data scales, and scientific thresholds,
is compared exactly. Changed caveats, accessor availability and fixture additions
still fail.
`.github/workflows/capability-matrix.yml` runs this check. `--out=/tmp/cap.md`
writes an alternate preview.

## Check isolated installation

```bash
julia tools/check_clean_depot.jl --source=working-tree --keep
julia tools/check_clean_depot.jl --source=committed --package=TSNA --keep
```

The default is `--source=committed`. Working-tree mode snapshots tracked changes
and unignored new files; it does not commit the real repositories. Both modes
install Git snapshots in dependency order from separate directories in a new
Julia process with an empty depot and restricted load path. The worker rejects
developed dependencies or sources resolved into the live workspace.

`--package=Name` includes its local dependency closure; repeat it for multiple
packages. `--keep` retains revisions, configuration, and `results.toml` evidence.
Failures retain evidence automatically. `--registry=URL` instead tests named
packages from that registry. Local snapshot success does not demonstrate
registry publication or availability of unpushed changes.

## Run performance gates

```bash
julia tools/run_benchmarks.jl --regressions-only
julia tools/run_benchmarks.jl
julia tools/run_benchmarks.jl ERGM Siena
```

Each suite uses its own benchmark environment. The fast mode runs dedicated
`regression_tests.jl` files. Full mode also runs `benchmarks.jl`, including its
embedded scaling assertions, and prints median times, allocations, and a
pass/fail summary. Package filters are substrings; only packages with the
relevant benchmark entrypoint are covered.

`.github/workflows/benchmarks.yml` runs dedicated regression gates on pushes
and pull requests, plus full suites weekly and on manual dispatch. Absolute
timings depend on hardware and load; inspect scaling and allocation gates.

## Prepare a release

```bash
julia tools/setup_registry.jl
```

This is a dry run. It reports package order and readiness for a LocalRegistry.
Registration uses committed Git state and is a separate release action:
`--register` creates registry content. Review the script's options and coordinate
package revisions before release. Passing local validation does not tag,
publish, register, or deploy any package.

## Preview umbrella and package documentation together

With prepared sibling checkouts and Python 3.11+, run from the site directory:

```bash
python3 tools/preview_docs.py --build
```

This builds Franklin and all 15 strict Documenter sites, then serves
<http://localhost:8001/>. `/Package.jl/dev/` routes to that package's local
`docs/build/`; `/stable/` is an alias of the same local build. Source repositories
and directory listings are not served. Package and umbrella links share one
origin, including Documenter's local version navigation.

Use `--build-only` to build and exit, or omit `--build` to serve existing output.
`--root` selects a sibling workspace and `--port` changes the listening port;
the server binds to loopback. The build command sanitizes CI/deployment settings
and refuses a detected Documenter deployment environment. It does not publish.

Run the routing, isolation and build-command checks with:

```bash
python3 -m unittest discover -s tools/test -p 'test_preview_docs.py'
```

The package sites use Documenter's default themes and their own checked-in SVG
logos and favicons. Synchronize or check the [canonical icons](docs-theme/README.md)
with the existing command (which also detects retired custom-theme assets):

```bash
julia tools/sync_documentation_theme.jl
julia tools/sync_documentation_theme.jl --check
```
