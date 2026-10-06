# Continuous integration across the package repositories

Each package is its own repository with two workflows: `CI.yml` runs its test
suite and `Documentation.yml` builds and publishes its Documenter site.
NetworkCore.jl and ERGM.jl also carry `Downstream.yml`. This page describes how
these workflows fit together and which secrets they need.

## The sibling layout

The packages find each other through `[sources]` path entries such as
`NetworkCore = {path = "../NetworkCore.jl"}`. A runner starts with a single checkout,
so every workflow checks the package out at `path: <Pkg>.jl` and then runs one
step, **Reconstruct the ecosystem layout from [sources]**. The step:

- parses every `Project.toml` in the repository (the package, `docs/`,
  `benchmark/`, `examples/…`) with Julia's TOML parser;
- clones the current `main` of each sibling that `[sources]` names, and then the
  siblings those siblings depend on, until the set is closed;
- checks each clone's package name and UUID;
- prints the revision of every checkout to the log and the job summary, so a
  run can be reproduced.

The step text is identical in every package. Its template is
[`workflows/layout-step.yml`](workflows/layout-step.yml); the whole
`Documentation.yml` is generated from
[`workflows/Documentation.yml`](workflows/Documentation.yml), and `Downstream.yml`
from [`workflows/Downstream.yml`](workflows/Downstream.yml). After editing a
template, update every package and verify the result:

```bash
julia tools/sync_workflows.jl ..            # rewrite the generated parts
julia tools/sync_workflows.jl .. --check    # fail on any difference
```

The sync rewrites only the block between `# >>> ecosystem layout` and
`# <<< ecosystem layout` in `CI.yml`. The rest of `CI.yml` belongs to the
package: thread settings, benchmark gates and extra test steps. `--check` also
fails if a workflow still uses an older clone mechanism (a literal
`for pkg in …` loop, a `sed` pipeline or a `checkout_sources.jl` script).
Adding a `[sources]` dependency needs no workflow change.

Two more rules hold the layout together, and the sync reports a breach in either
mode (it never rewrites a `Project.toml`):

- **Every sibling in a `[sources]` table is a `path` entry** that resolves to the
  sibling's checkout, in every `Project.toml` of the repository (the package,
  `docs/`, `benchmark/`, `examples/…`). The layout step clones only path
  sources, so a `url`/`rev` source, which a Pkg command can write without
  notice, would make CI and the workspace test against the published `main` of
  that sibling instead of the checkout beside it.
- **Only NetworkCore.jl and ERGM.jl carry the Downstream workflow** (`DOWNSTREAM`
  in `sync_workflows.jl`). A copy elsewhere, under any file name, would dispatch
  the dependents from the wrong repository.

`--check` also requires every package's `CI.yml` to run at least one cell with
`JULIA_NUM_THREADS` set to 4, because the thread-count-independence testsets
prove nothing on one thread. NDTV and ERGMUserterms are exempt
(`SINGLE_THREADED` in `sync_workflows.jl`): their suites spawn no tasks.

## When package CI runs

| Trigger | What it tests |
|:---|:---|
| Push to `main`, a `v*` tag, a pull request | the change, against the siblings' current `main` |
| Nightly `schedule` (staggered, 01:07–03:47 UTC) | the package against whatever its siblings became |
| `workflow_dispatch` | on demand, and from `Downstream.yml` (below) |

The matrix is Julia 1.12, the current release and nightly on Linux; 1.12 and the
current release on Windows and on macOS (native Apple silicon). The nightly
cells use `continue-on-error`, so a regression in Julia nightly shows in the
run without turning the badge red.

GitHub disables a scheduled workflow after 60 days without repository
activity. Re-enable it from the Actions tab, or with
`gh workflow enable CI.yml --repo statistical-network-analysis-with-Julia/<Pkg>.jl`.

## Downstream dispatch

A change to NetworkCore.jl can break any other package, and a change to ERGM.jl any
of its dependents. When CI passes on a push to `main` of either package, its
`Downstream.yml` reads every organisation repository's `Project.toml`, finds
the packages whose `[sources]` reach the changed package, and starts their
`CI.yml` with `gh workflow run`. A package is included when it reaches the
changed package through `[deps]`, or names it, or one of those dependents, in
`[weakdeps]` or test-only `[extras]`.

The job then **waits for the dispatched runs** (polling once a minute, for up to
`WAIT_MINUTES`, 320 by default, within the job's 340-minute timeout) and writes a
table of every dependent and its CI conclusion, with links, to the job summary.
It fails unless every dependent was dispatched and its run concluded `success`,
so the Downstream status of a NetworkCore.jl or ERGM.jl push says whether the
new `main` broke a dependent. Nightly Julia cells are `continue-on-error` in the
dependents, so they do not fail this aggregate.

Starting a workflow in another repository, and reading its runs, needs a token. Create a fine-grained
personal access token, or a GitHub App token, with:

- **Resource owner:** `statistical-network-analysis-with-Julia`
- **Repository access:** all repositories, or at least every package
- **Permissions:** *Actions: Read and write*, *Contents: Read-only*,
  *Metadata: Read-only*

Store it as the secret `DOWNSTREAM_DISPATCH_TOKEN` on the organisation, or on
NetworkCore.jl and ERGM.jl:

```bash
gh secret set DOWNSTREAM_DISPATCH_TOKEN --org statistical-network-analysis-with-Julia \
    --repos NetworkCore.jl,ERGM.jl
```

Without the secret the job **fails**, and its summary reads "Downstream CI: NOT
DISPATCHED": a downstream check that did not run must not look like one that
passed. A package whose `CI.yml` has no `workflow_dispatch` trigger, or whose
dispatch fails, is listed as NOT DISPATCHED and fails the job too. You can also
run the dispatch by hand from the Actions tab of NetworkCore.jl or ERGM.jl.

## Coverage

Coverage is collected on one cell per package (Linux, Julia 1.12), and only
when the repository can read a `CODECOV_TOKEN` secret. Codecov refuses tokenless
uploads from these repositories, so without the token the cell skips coverage
altogether rather than instrument the suite and discard the result. With the
token, a failed upload fails the job (`fail_ci_if_error: true`). Pull requests
from forks cannot read secrets and skip coverage.

To enable it, add the repositories to Codecov and store the organisation upload
token:

```bash
gh secret set CODECOV_TOKEN --org statistical-network-analysis-with-Julia --visibility all
```

## Site checks across repositories

The site repository's [`ecosystem.yml`](../.github/workflows/ecosystem.yml)
runs daily, after the packages' nightly CI, and on changes to `tools/`:

- `sync_workflows.jl --check`: the package workflows match the templates,
  sibling sources are path sources, and only NetworkCore.jl and ERGM.jl carry
  `Downstream.yml`;
- `check_coload.jl`: all packages load together, no exported name is bound to
  different objects, and `Test.detect_ambiguities` finds nothing across them;
- `check_clean_depot.jl --source=committed`: every committed package installs
  and loads in an empty depot, in dependency order.

The weekly `snippets.yml`, `capability-matrix.yml` and `benchmarks.yml`
workflows execute the documentation, regenerate the capability page and run
the benchmark gates. [`README.md`](README.md) describes each tool.

## Action versions

The workflows use the current major version of each action:
`actions/checkout@v7`, `julia-actions/setup-julia@v3`,
`julia-actions/cache@v3`, `julia-actions/julia-processcoverage@v1`,
`codecov/codecov-action@v7`, `actions/upload-pages-artifact@v5` and
`actions/deploy-pages@v5`. All run on Node 24. `setup-julia@v3` refuses x64
Julia on Apple silicon unless forced, which is why the macOS cells use
`aarch64`. Dependabot keeps the site's own workflows current; when it bumps an
action, bump the templates in `tools/workflows/` and re-run the sync.
