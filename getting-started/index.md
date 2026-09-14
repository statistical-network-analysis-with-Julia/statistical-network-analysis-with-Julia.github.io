@def title = "Get started"
@def hascode = true

# Your first network analysis

Set up the Julia workspace, load a bundled dataset, and choose the next step
for your research question. No data download is needed for the first example.

## 1. Set up the workspace

Use **Julia 1.12 or newer**, Git, and a terminal. The current 0.2.0 packages
are under development and are **not yet in Julia's General registry**. The
shared setup installs sibling source checkouts and the dependencies used by
these examples.

Run these commands from a directory where you want to keep the project:

```bash
mkdir network-analysis
cd network-analysis
git clone https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io
julia statistical-network-analysis-with-Julia.github.io/tools/prepare_workspace.jl "$PWD" --clone
julia --project=.snippet-env
```

The last command opens Julia in the prepared environment. The first setup
needs network access. Already have the sibling repositories? Run the preparation
command from their parent directory; it preserves existing checkouts. Keep the
repository directory names intact because local dependencies use these paths.

This recipe installs revisions currently available on GitHub. Local fixes
that have not been pushed are available only in the workspace containing them.
See the [workspace recipe](https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io/tree/main/tools/workspace)
for environment details.

## 2. Describe a real network

Paste this into Julia. The Florentine marriage dataset records ties among
16 Renaissance families.

```julia
using Networks, SNA

net = load_dataset(:florentine_marriage)
families = vertex_attribute_vector(net, :name, String)
centrality = degree_centrality(net)
most_connected = argmax(centrality)

println("Density: ", gden(net))
println("Most connected family: ", families[most_connected])
println("Degree: ", centrality[most_connected])
```

The density is approximately **0.167**. The Medici have the highest degree,
with **six** marriage ties. These are descriptive properties of the observed
network; they do not establish why the ties formed.

Continue with [the full structural analysis](/examples/describing-network-structure/)
to explore centrality, compare marriage and business ties, and use QAP inference.

## 3. Choose your next step

| Your question or data | Start here |
|---|---|
| How do I create networks or import attributes? | [Networks.jl](/Networks.jl/dev/getting_started/) |
| What patterns characterize an observed network? | [SNA.jl](/SNA.jl/dev/getting_started/) |
| Which configurations are associated with binary ties? | [The ERGM example](/examples/modelling-cross-sectional-data/) |
| How do ties change across observed waves? | [The network-change example](/examples/modelling-network-change/) |
| Who interacts next, given the interaction history? | [The event-model example](/examples/modelling-interaction-events/) |
| Do I have counts, rankings, egocentric or multilayer data? | [The package directory](/packages/?group=ergm) |
| How do I handle activity spells, paths or animations? | [Packages for networks over time](/packages/?group=dynamics) |

Coming from statnet or RSiena? The [R migration guide](/migration/) maps familiar
functions to supported Julia workflows and lists important differences.

## 4. Make the analysis reproducible

Keep your analysis scripts, the environment's `Project.toml` and `Manifest.toml`,
and the revision of each package checkout. Source files in developed packages
can change independently of the Manifest: record commits with `git rev-parse HEAD`
and preserve any uncommitted changes used in the analysis.

Pass an explicit RNG to stochastic routines, for example `rng=Xoshiro(42)` after
`using Random`. Before interpreting coefficients, inspect convergence, estimator
metadata and the package's missing-data and observation-window policies.
[Capabilities and limitations](/capabilities/) distinguishes implemented methods,
uncertainty conventions and validated R comparisons.

## Troubleshooting

- **Package not found:** start Julia from the workspace directory with
  `julia --project=.snippet-env`; a different active environment will not see
  these developed packages.
- **A sibling path does not exist:** keep names such as `Networks.jl` intact and
  rerun the preparation command with `--clone` to fetch missing repositories.
- **A fitting call refuses the data or fails to converge:** read the reported
  diagnostic and the estimator's guide. More iterations cannot resolve a
  mathematically unidentified or separated model.
