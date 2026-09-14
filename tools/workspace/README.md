# A workspace for the network-analysis packages

Use Julia 1.12 or newer. These packages use sibling source checkouts during
unreleased development. From an empty directory:

```bash
git clone https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io
julia statistical-network-analysis-with-Julia.github.io/tools/prepare_workspace.jl "$PWD" --clone
julia --project=.snippet-env -e 'using Networks, SNA, ERGM, Siena, REM, Relevent'
```

The preparation script reads the package list from the adjacent `Project.toml`,
clones missing repositories, follows their local `[sources]` dependencies, and
develops them together in `.snippet-env`. Existing checkouts are used as they
stand; the script never pulls or resets them. It also installs dependencies used
by documentation examples. Network access is needed for first-time preparation.

For a smaller environment without documentation extras, copy this `Project.toml`
to the directory containing all 15 sibling checkouts and run
`julia --project=. -e 'using Pkg; Pkg.instantiate()'`. Its paths are relative to
that destination, not to `tools/workspace` itself. Do not overwrite an existing
workspace project without reconciling its dependencies.

These commands use the revisions currently available on GitHub. Record each
repository's `git rev-parse HEAD` and preserve the environment Manifest for a
reproducible analysis. Unpushed fixes in a local workspace are not installed by
this recipe. This is a source-checkout workflow, not a claim of registry release.
