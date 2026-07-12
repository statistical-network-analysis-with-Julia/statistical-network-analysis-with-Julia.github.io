# Documentation snippet checker

`check_snippets.jl` executes every fenced ` ```julia ` code block in the
ecosystem's Markdown documentation — each package repo's `README.md` and
`docs/src/**`, plus this site's own pages — and prints a pass/fail report
with `file:line` locations for anything that throws.

Blocks in one file run sequentially in a single fresh sandbox module (so a
page's later blocks can use variables defined earlier on the page), with
REPL soft scope. A block is skipped when:

- it is fenced as ` ```julia-repl ` (REPL transcripts),
- the line immediately above the fence contains `<!-- skip-check -->`,
- it mutates a Pkg environment (`Pkg.add`, `Pkg.develop`, ...) — install
  instructions, which would modify the shared checker environment,
- it is clearly output-only (preceded by an "Output:" label, or it does not
  parse as Julia — the latter are listed as warnings so genuinely broken
  examples still surface).

Each file's blocks execute in a temporary scratch directory, so examples
that write files (Pajek export, rendered animations, ...) do not pollute
the repos.

## Running locally

The script needs a Julia environment in which all the local (unregistered)
packages are `develop`ed. Build one once, then point `--project` at it:

```bash
SNWJ_ROOT=/path/to/monorepo/root      # dir containing Network.jl, ERGM.jl, ...
julia -e '
  using Pkg
  Pkg.activate(joinpath(ENV["SNWJ_ROOT"], ".snippet-env"))
  for d in readdir(ENV["SNWJ_ROOT"]; join=true)
      isfile(joinpath(d, "Project.toml")) || continue
      endswith(d, ".github.io") && continue
      Pkg.develop(path=d)
  end
  Pkg.add(["DataFrames", "Graphs"])   # extras some snippets use
'
```

Then run the checker (positional arguments are substring filters on file
paths; with no arguments every file is checked — expect a long run, some
examples do real MCMC):

```bash
SNWJ_ROOT=/path/to/monorepo/root \
julia --project=$SNWJ_ROOT/.snippet-env tools/check_snippets.jl

# only ERGM.jl's getting-started page:
julia --project=$SNWJ_ROOT/.snippet-env tools/check_snippets.jl ERGM.jl/docs getting_started
```

If `SNWJ_ROOT` is unset, the script assumes this site repo sits directly
inside the monorepo root and uses the repo's parent directory.

The script exits non-zero when any file fails, so it can gate CI.

## CI wiring (deferred)

The monorepo root is **not itself a git repository** — the packages are
independent repos that reference each other via `[sources]` path
dependencies — so there is no single place to hang a cross-repo workflow
today. Options for later:

1. Per-package workflows that `git clone` the sibling repos next to the
   package checkout to reconstruct the monorepo layout, then run this
   script filtered to that package's own docs.
2. A dedicated "ecosystem CI" repo (or this site repo) with a scheduled
   workflow that clones all package repos side by side and runs the full
   sweep.

Until one of those lands, run the script locally before publishing doc
changes.
