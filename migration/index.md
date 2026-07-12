@def title = "Coming from statnet / RSiena"
@def hascode = true
@def mintoclevel = 2

# Coming from statnet / RSiena

This page maps the R workflows you already know — statnet's
`network`/`sna`/`ergm` stack, `RSiena`, and `relevent` — onto their Julia
equivalents, package by package and verb by verb. It ends with a
[complete worked example](#a_complete_worked_example) (loading a classic
dataset, describing it, fitting an ERGM by MCMC MLE, checking fit) whose
output was produced by running the code on this page, and an honest list
of [what still differs from R](#what_still_differs_from_r).

Three conventions carry most of the translation:

1. **Terms are typed values, not formula symbols.** Where R writes
   `net ~ edges + mutual + nodecov("wealth")`, Julia passes a vector of
   term objects: `[Edges(), Mutual(), NodeCov(:wealth)]`. Term options are
   keyword arguments to the constructor (`GWESP(0.5; type=:OSP)`).
2. **Attribute names are `Symbol`s** (`:wealth`), not strings, and R's
   dot-separated names become snake_case (`network.extract` →
   `network_extract`, `component.dist` → `component_dist`).
3. **Model accessors are the shared StatsAPI generics.** `coef`,
   `stderror`, `vcov`, `loglikelihood`, `aic`, `bic` work on every fitted
   model object in the ecosystem and compose with `StatsBase`, `GLM`,
   etc. — `using ERGM, Siena, REM` together is safe.

\toc

## The package map

| R package | Julia package | Main entry points |
|:---|:---|:---|
| `network` | [Network.jl](https://github.com/statistical-network-analysis-with-Julia/Network.jl) | `network`, `network_from_matrix`, `load_dataset` |
| `sna` | [SNA.jl](https://github.com/statistical-network-analysis-with-Julia/SNA.jl) | `degree_centrality`, `gden`, `triad_census`, ... |
| `ergm` | [ERGM.jl](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl) | `ergm` / `fit_ergm`, `gof`, `simulate_ergm` |
| `ergm.count` | [ERGMCount.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl) | `ergm_count` |
| `ergm.ego` | [ERGMEgo.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl) | `ergm_ego`, `as_egodata` |
| `ergm.multi` | [ERGMMulti.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl) | `ergm_multi` |
| `ergm.rank` | [ERGMRank.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl) | `ergm_rank`, `as_rank_network` |
| `ergm.userterms` | [ERGMUserterms.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl) | `@ergm_term`, `validate_term`, `test_term` |
| `tergm` | [TERGM.jl](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl) | `stergm`, `stergm_gof`, `simulate_network_sequence` |
| `RSiena` | [Siena.jl](https://github.com/statistical-network-analysis-with-Julia/Siena.jl) | `siena_data`, `get_effects`, `siena07`, `siena_gof` |
| `relevent` | [REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl) + [Relevent.jl](https://github.com/statistical-network-analysis-with-Julia/Relevent.jl) | `fit_rem`; `fit_obpm`, `fit_timing` |
| `networkDynamic` | [NetworkDynamic.jl](https://github.com/statistical-network-analysis-with-Julia/NetworkDynamic.jl) | `DynamicNetwork`, `activate!`, `network_extract` |
| `tsna` | [TSNA.jl](https://github.com/statistical-network-analysis-with-Julia/TSNA.jl) | `tSnaStats`, `earliestArrival`, `forwardReachableSet` |
| `ndtv` | [NDTV.jl](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl) | `render_animation`, `filmstrip`, `timeline_plot` |

The packages are not yet in the General registry: clone the repositories
side by side and `Pkg.develop` them (Network.jl first, then SNA/ERGM/
NetworkDynamic, then their dependents — each README has the ordered
one-liner). All packages require Julia 1.12+.

A convenience worth knowing from day one: `using ERGM` (and the ERGM
variants) re-exports the whole Network.jl API, so a single `using ERGM`
gives you `network`, `add_edge!`, attribute setters, and `load_dataset`.

## Networks: `network` → Network.jl

| R (`network`) | Julia (Network.jl) |
|:---|:---|
| `network.initialize(16)` | `network(16)` (directed by default, like R) |
| `network(16, directed=FALSE)` | `network(16; directed=false)` |
| `network(A, directed=FALSE)` | `network_from_matrix(A; directed=false)` |
| `as.network(el, matrix.type="edgelist")` | `network_from_edgelist(el)` |
| `add.edges(net, 1, 9)` | `add_edge!(net, 1, 9)` |
| `delete.edges(...)` | `rem_edge!(net, 1, 9)` |
| `net %v% "wealth" <- w` | `set_vertex_attribute!(net, :wealth, w)` |
| `net %v% "wealth"` | `vertex_attribute_vector(net, :wealth, Int)` |
| `get.vertex.attribute(net, "wealth")[9]` | `get_vertex_attribute(net, :wealth, 9)` |
| `set.edge.attribute(net, "w", 3, e)` | `set_edge_attribute!(net, :w, i, j, 3)` |
| `network.size / network.edgecount / network.density` | `network_size` / `network_edgecount` / `network_density` (or `nv`, `ne`) |
| `as.matrix(net)` | `as_matrix(net)` |
| `as.edgelist(net)` | `as_edgelist(net)` |
| `read.paj("flo.net")` | `read_pajek("flo.net")` |
| `net[1, 2] <- NA` (missing dyad) | `set_missing_dyad!(net, 1, 2)` |
| `data(flomarriage)` | `load_dataset(:florentine_marriage)` |

`load_dataset` also bundles `:florentine_business` (statnet
`flobusiness`) and `:sampson` (statnet `samplike`), with the same vertex
attributes as the R originals.

`Network` implements the Graphs.jl `AbstractGraph` interface with
directedness as a *type parameter* (`Network{Int, false}` is undirected),
so Graphs.jl generics dispatch correctly on it.

## Describing networks: `sna` → SNA.jl

| R (`sna`) | Julia (SNA.jl) |
|:---|:---|
| `degree(net, gmode="graph")` | `degree_centrality(net)` (single-counted on undirected networks, like R) |
| `degree(net, cmode="indegree")` | `degree_centrality(net; mode=:in)` |
| `betweenness(net)` | `betweenness_centrality(net)` |
| `closeness(net)` | `closeness_centrality(net)` |
| `evcent(net)` | `eigenvector_centrality(net)` |
| `bonpow(net)` | `bonacich_power(net)` |
| `gden(net)` | `gden(net)` (alias: `density`) |
| `grecip(net)` | `grecip(net)` |
| `gtrans(net)` | `gtrans(net)` (alias: `transitivity`) |
| `mutuality(net)` | `mutuality(net)` |
| `dyad.census(net)` | `dyad_census(net)` |
| `triad.census(net)` | `triad_census(net)` |
| `geodist(net)` | `geodesic_distance(net)` |
| `component.dist(net)` | `component_dist(net)` — but see [differences](#what_still_differs_from_r) |
| `kcores(net)` | `kcores(net)` |
| `cutpoints(net)` | `cutpoints(net)` |
| `clique.census(net)` (maximal cliques) | `cliques(net)` |
| `sedist / equiv.clust / blockmodel` | `structural_equivalence` / `equiv_clust` / `blockmodel` |
| `rgraph(20, tprob=0.1)` | `rgraph(20; tprob=0.1)` |

The values agree with R: SNA.jl's test suite pins `gden`, `gtrans`,
centrality scores, and the dyad/triad censuses to golden-master values
computed with `sna` 2.8.

## ERGMs: `ergm` → ERGM.jl

The R formula becomes a vector of term objects:

```r
# R
data(sampson)
fit <- ergm(samplike ~ edges + mutual + nodematch("group", diff=TRUE))
```

```julia
# Julia
using ERGM, Random               # ERGM re-exports the Network.jl API

net = load_dataset(:sampson)     # statnet's samplike
levels = ["Loyal", "Outcasts", "Turks"]
fit = ergm(net, [Edges(); Mutual();
                 [NodeMatch(:group; diff=true, level=l) for l in levels]];
           method=:mcmle, rng=Xoshiro(7))
println(fit)
```

Output:

```
ERGM Results
============
Method: mcmle
Log-likelihood: -132.4494
AIC: 274.9, BIC: 293.52
Converged: true

Coefficients:
------------------------------------------------------------
edges                   -2.2411     0.2342        0.0 ***
mutual                    1.364     0.4972     0.0061 **
nodematch.group.Loyal     1.6726     0.3532        0.0 ***
nodematch.group.Outcasts      2.834     0.7633     0.0002 ***
nodematch.group.Turks     2.1938     0.4022        0.0 ***
------------------------------------------------------------
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

Note the one real semantic difference in that translation: the term
system is one-statistic-per-term, so R's `nodematch(diff=TRUE)` — which
silently expands into one statistic per attribute level — is written as
an explicit comprehension over levels. `NodeMatch(:group; diff=true)`
without a `level` throws an error explaining exactly this.

### Term translation

| R term | Julia term |
|:---|:---|
| `edges` | `Edges()` |
| `mutual` | `Mutual()` (directed networks only — errors on undirected, like R) |
| `triangle` | `Triangle()` |
| `kstar(2)` | `Kstar(2)` |
| `twopath` | `TwoPath()` |
| `nodecov("wealth")` | `NodeCov(:wealth)` |
| `nodefactor("g")` | `NodeFactor(:g; level="a")` — one term per (non-base) level |
| `nodematch("x")` | `NodeMatch(:x)` |
| `nodematch("x", diff=TRUE)` | `[NodeMatch(:x; diff=true, level=l) for l in levels]` |
| *(count of mismatched edges)* | `NodeMismatch(:x)` |
| `absdiff("age")` | `AbsDiff(:age)` |
| `edgecov(m)` | `EdgeCov(m)` |
| `gwesp(0.5, fixed=TRUE)` | `GWESP(0.5)` |
| `dgwesp(0.5, type="OSP", fixed=TRUE)` | `GWESP(0.5; type=:OSP)` (`:OTP`, `:ITP`, `:OSP`, `:ISP`) |
| `gwdegree(0.5, fixed=TRUE)` | `GWDegree(0.5)` |

Model construction *validates terms against the network*: a typo'd
attribute (`NodeCov(:welth)`) throws an `ArgumentError` listing the
attributes that do exist, instead of silently fitting a zero column.

### Estimation and post-estimation

| R (`ergm`) | Julia (ERGM.jl) |
|:---|:---|
| `summary(net ~ edges + triangle)` | `summary_stats(net, [Edges(), Triangle()])` |
| `fit <- ergm(net ~ ...)` | `fit = ergm(net, terms; method=:mcmle)` |
| MPLE: `ergm(..., estimate="MPLE")` | `ergm(net, terms)` (`method=:mple` is the default; see below) |
| `summary(fit)` | `println(fit)` |
| `coef(fit)` / `vcov(fit)` | `coef(fit)` / `vcov(fit)` (StatsAPI, plus `stderror`) |
| `logLik(fit)`, `AIC(fit)`, `BIC(fit)` | `loglikelihood(fit)`, `aic(fit)`, `bic(fit)` |
| `gof(fit)` | `gof(fit; n_sim=100)` (degree, ESP, geodesic distance) |
| `simulate(fit, nsim=10)` | `simulate_ergm(fit; n_sim=10)` |
| `mcmc.diagnostics(fit)` | `mcmc_diagnostics(fit)` |
| `control.ergm(MCMC.burnin=...)` | keywords: `mcmle(model; burnin=..., interval=..., n_samples=..., rng=...)` |

Unlike R `ergm()`, which picks MCMC MLE automatically for dyad-dependent
models, `ergm(net, terms)` defaults to MPLE for every model and *tells
you* when that matters: a fit containing dyad-dependent terms prints a
warning that the pseudolikelihood standard errors are suspect and points
to `method=:mcmle` and `se=:bootstrap`. The MCMLE itself follows
statnet's algorithmic standards: Hummel step-length control,
Hotelling-T²-based convergence, dyad-count-scaled MCMC defaults, and a
path-sampling (bridge) log-likelihood for AIC/BIC.

### The ERGM variants

| R call | Julia call |
|:---|:---|
| `ergm(net ~ sum, response="w", reference=~Poisson)` | `ergm_count(net, [SumTerm()]; reference=PoissonReference())` |
| `ergm.ego(egodata ~ edges + nodematch("x"))` | `ergm_ego(egodata, [EgoEdges(), EgoNodeMatch(:x)])` |
| `ergm.multi` multilayer models | `ergm_multi(mnet, [LayerEdges(1), MultiplexMutual(1, 2), ...])` |
| `ergm.rank` | `ergm_rank(rnet, [RankDeference(), ...])` |
| `ergm.userterms` (C skeleton + rebuild) | `@ergm_term` macro, then `validate_term` / `test_term` — plain Julia, no recompilation |

Every variant's result type supports the same StatsAPI accessors.

## Temporal ERGMs: `tergm` → TERGM.jl

| R (`tergm`) | Julia (TERGM.jl) |
|:---|:---|
| `stergm(nw_list, formation=~edges+mutual, dissolution=~edges, estimate="CMLE")` | `stergm(networks, [Edges(), Mutual()], [Edges()])` |
| `tergm(nw_list ~ Form(~edges) + Persist(~edges), estimate="CMLE")` | same — the dissolution model is parameterized as *persistence*, like `Persist()` |
| bootstrap SEs (`btergm`-style) | `stergm(...; se=:bootstrap, n_boot=200)` |
| `gof(fit)` | `stergm_gof(fit)` |
| `simulate(fit)` | `simulate_network_sequence(model, init, n_steps, θ_form, θ_diss)` |

Estimation is conditional maximum pseudo-likelihood (CMPLE) on the
Krivitsky–Handcock formation (union) and dissolution (intersection)
networks — exact CMLE for dyad-independent models; MCMC-based CMLE and
EGMME are not implemented (`method=:cmle` falls back to CMPLE with a
warning). See the [worked STERGM example](/examples/modelling-network-change/).

## SAOMs: `RSiena` → Siena.jl

The workflow is a deliberate mirror of RSiena's:

| RSiena | Siena.jl |
|:---|:---|
| `sienaDataCreate(...)` | `data = siena_data()` + `add_nodeset!` / `add_dependent!` / `add_covariate!` |
| `sienaDependent(array)` | `DependentNetwork(:name, waves)` — waves are matrices **or `Network` objects** |
| `sienaDependent(mat, type="behavior")` | `DependentBehavior(:name, waves)` |
| `coCovar(v)` / `varCovar(m)` | `ConstantCovariate(:name, v)` / `VaryingCovariate(:name, m)` |
| `coDyadCovar(m)` | `ConstantDyadCovariate(:name, m)` (also accepts a `Network`) |
| `getEffects(data)` | `effects = get_effects(data)` |
| `includeEffects(eff, transTrip, recip)` | `include_effects!(effects, :friendship, [:transTrip, :recip])` |
| `sienaAlgorithmCreate(seed=42)` | `siena_algorithm(seed=42)` |
| `siena07(alg, data=dat, effects=eff)` | `siena07(data, effects; algorithm=alg)` |
| `sienaGOF(res, IndegreeDistribution, ...)` | `siena_gof_indegree(result, data, :friendship)` |

Effect shortnames are RSiena's (`:outdegree`, `:recip`, `:transTrip`,
`:cycle3`, `:inPop`, `:egoX`, `:simX`, `:avAlt`, ... — 150+ effects), and
the target statistics are validated against RSiena's `getTargets` to six
decimals on the `s50` data. Estimation is unconditional Method of
Moments with the RSiena publication standards for convergence (every
|t-ratio| < 0.1 and `tconv.max` < 0.25), score-function derivative
estimation, and standard errors from all phase-3 simulations.

Since a `Vector` of `Network` objects converts directly (a package
extension activates when Network.jl is loaded), you can describe
cross-sections with SNA.jl and model their dynamics with Siena.jl without
touching a matrix. A minimal round trip — three synthetic waves, two
effects (this is a mechanics demo on random data, so the estimates
themselves are uninteresting):

```julia
using Network, Siena, Random

rng = Xoshiro(11)
wave1 = network(25; directed=true)
for i in 1:25, j in 1:25
    i != j && rand(rng) < 0.06 && add_edge!(wave1, i, j)
end
waves = [wave1]
for _ in 2:3                       # each later wave toggles 40 random dyads
    w = copy(waves[end])
    for _ in 1:40
        i, j = rand(rng, 1:25), rand(rng, 1:25)
        i == j && continue
        has_edge(w, i, j) ? rem_edge!(w, i, j) : add_edge!(w, i, j)
    end
    push!(waves, w)
end

data = siena_data()
add_nodeset!(data, NodeSet(25))
add_dependent!(data, DependentNetwork(:friendship, waves))  # Network panel — no matrices
effects = get_effects(data)
include_effects!(effects, :friendship, [:outdegree, :recip])
alg = siena_algorithm(seed=42, phase3_iterations=200, verbose=false)
result = siena07(data, effects; algorithm=alg)
println(result)
```

Output:

```
SAOM Estimation Results
=======================
Converged: true (max |t-ratio| = 0.086, overall max convergence ratio = 0.169)
Iterations: 450

Rate Parameters:
----------------
Rate friendship (period 1)     1.3505 (0.2655)
Rate friendship (period 2)     1.3998 (0.2546)

Objective Function Parameters:
------------------------------
outdegree                      0.1369 (0.2845)
recip                          0.1494 (0.4151)
```

RSiena's structural zeros/ones (10/11 coding) are supported in the wave
matrices; conditional estimation, maximum likelihood, and Bayesian
estimation are not (see [differences](#what_still_differs_from_r)).

## Relational events: `relevent` → REM.jl / Relevent.jl

Two packages split R `relevent`'s territory. REM.jl holds the event
types, 25+ statistics, and a case-control-sampled estimator for long
event streams; Relevent.jl adds `rem.dyad`'s two exact full-risk-set
likelihoods (ordinal and interval timing) plus decay-weighted history
statistics.

| R (`relevent`) | Julia |
|:---|:---|
| event list `(time, sender, receiver)` | `Event(sender, receiver, time)`; `EventSequence(events)` |
| `rem.dyad(el, n, effects=..., ordinal=TRUE)` | `fit_obpm(events, stats, n)` — exact ordinal likelihood |
| `rem.dyad(el, n, effects=..., ordinal=FALSE)` | `fit_timing(events, stats, n)` — exponential-baseline interval timing |
| large-stream approximate fit (eventnet-style) | `fit_rem(seq, stats; n_controls=100)` — case-control conditional logit |
| `"FESnd"` / inertia effects | `Repetition()`, `InertiaStatistic`, `PriorInteraction(halflife)` |
| `"RRecSnd"`, `"RSndSnd"` (recency) | `RecencyStatistic`, `LocalInertia(halflife)` |
| reciprocity effects | `Reciprocity()`, `PriorInteraction(halflife; direction=:incoming)` |
| triadic effects | `TransitiveClosure()`, `CyclicClosure()`, `SharedSender()`, `SharedReceiver()` |
| degree effects | `SenderActivity()`, `ReceiverPopularity()`, `SendingCapacity(halflife)`, ... |
| `coef(fit)`, `summary(fit)` | `coef(fit)`, `stderror(fit)`, `println(fit)` |

```julia
using REM, Relevent, Random

rng = Xoshiro(3)
events = [Event(rand(rng, 1:6), rand(rng, 1:6), Float64(t)) for t in 1:120]
events = filter(e -> e.sender != e.receiver, events)

# rem.dyad(..., ordinal=TRUE) equivalent: exact ordinal likelihood, full risk set
stats = [PriorInteraction(20.0), PriorInteraction(20.0; direction=:incoming)]
fit = fit_obpm(events, stats, 6)
println(fit)
```

Output:

```
Ordinal Butts-Park Model Results
================================
N actors: 6
N events: 103
Log-likelihood: -349.5015
Converged: true

Coefficients:
  prior_interaction_outgoing      -0.0308 (SE: 0.1759)
  prior_interaction_incoming       0.2147 (SE: 0.1655)
```

For a substantive REM analysis (simulate with known effects, recover
them), see the [worked REM example](/examples/modelling-interaction-events/).
Gibson's participation-shift (p-shift) effects and the `CovSnd`/`CovRec`/
`CovInt` covariate blocks are not implemented yet; nodal covariate
effects go through `SenderAttribute`/`ReceiverAttribute`/`AttributeMatch`
instead.

## Dynamic networks: `networkDynamic` / `tsna` / `ndtv`

| R | Julia |
|:---|:---|
| `networkDynamic()` | `DynamicNetwork(10; observation_start=0.0, observation_end=100.0)` |
| `activate.vertices(nd, onset, terminus, v=1)` | `activate!(dnet, onset, terminus; vertex=1)` |
| `activate.edges(nd, onset, terminus, ...)` | `activate!(dnet, onset, terminus; edge=(1, 2))` |
| `is.active(nd, at=2, e=...)` | `is_active(dnet, 2.0; edge=(1, 2))` |
| `network.extract(nd, at=2)` | `network_extract(dnet, 2.0)` (returns a `Network`) |
| `network.collapse(nd, onset, terminus)` | `network_collapse(dnet, onset, terminus)` |
| `as.networkDynamic(net)` | `as_dynamic_network(net)` |
| `get.edge.activity(nd)` | `get_edge_activity(dnet)` |
| `tSnaStats(nd, "gden")` | `tSnaStats(dnet, times; measures=[:density])` |
| `tPath(nd, v=1, start=0)` | `earliestArrival(dnet, 1, 0.0)` / `shortestTemporalPath(dnet, 1, 5, 0.0)` |
| `tReach(nd, v=1)` | `forwardReachableSet(dnet, 1, 0.0)` |
| `tEdgeFormation(nd)` | `tEdgeFormation(dnet)` |
| `render.animation(nd)` | `render_animation(dnet; n_frames=50)` then `export_movie` / `export_gif` |
| `render.d3movie(nd)` | `export_html(layout, "movie.html")` (self-contained HTML) |
| `filmstrip(nd)` | `filmstrip(dnet, times)` |
| `timeline(nd)` | `timeline_plot(dnet)` |

TSNA.jl and NDTV.jl deliberately keep R tsna/ndtv's camelCase names
(`tSnaStats`, `earliestArrival`) since those APIs *are* the migration
target; everything else in the ecosystem is snake_case.

## What still differs from R

Honest divergences to keep in mind — the things most likely to bite a
statnet/RSiena user. (This list reflects the packages as of July 2026;
each item is also documented at the API it concerns.)

- **No formula interface.** Models are specified as vectors of term
  objects, never `net ~ edges + ...`. This is a deliberate design choice
  (terms are ordinary values you can build programmatically), not a
  missing feature.
- **`fit_ergm` defaults to MPLE**, where R `ergm()` chooses MCMC MLE
  automatically for dyad-dependent models. You must ask for
  `method=:mcmle` yourself; dyad-dependent MPLE fits print a warning
  about their standard errors and offer `se=:bootstrap` as a middle
  ground. MCMLE standard errors come from the inverse Fisher information
  of the final MCMC sample and do not add statnet's separate
  MCMC-error component.
- **`nodematch(diff=TRUE)` and `nodefactor` expand manually.** One term
  object per attribute level (see the comprehension idiom above); R
  expands levels automatically inside one formula term.
- **ERGM term coverage is narrower than statnet's.** Notably missing:
  `degree(k)`/`idegree`/`odegree` spectrum terms, `gwidegree`/
  `gwodegree`, `gwdsp`, `nodemix`, curved-ERGM estimation
  (`gwesp(fixed=FALSE)` — only fixed-decay geometrically weighted terms
  exist), offsets, and `constraints=`.
- **Directed GOF is coarser than statnet's.** `gof` reports a single
  `:degree` distribution based on out-neighbors (no idegree/odegree
  split), and its `:esp` distribution counts either-direction shared
  partners even if the model used a typed (OTP/ITP/OSP/ISP) `GWESP` —
  whereas statnet's directed GOF ESP is OTP-based. The fitted GWESP
  *statistics* themselves match statnet's definitions.
- **`component_dist` uses weak components** on directed networks, where
  R `sna::component.dist` defaults to `connected="strong"`.
- **Missing data is narrower than in R.** `Network` supports missing
  (unobserved) dyad masks: MPLE excludes masked dyads from the
  pseudo-likelihood, and MCMLE *conditions on their face values* with a
  one-time warning — an approximation, not statnet's full missing-data
  MLE. Siena.jl supports RSiena's structural zeros/ones (10/11 coding)
  in data, simulation, and moment statistics, but `NA` ties and
  composition change are not handled in estimation. REM.jl assumes
  fully observed event streams.
- **Siena.jl estimates by unconditional Method of Moments only.**
  Conditional estimation, Maximum Likelihood, and Bayesian estimation
  are not implemented; endowment/creation effects simulate but do not
  estimate; `include_interaction!` does not exist yet. Convergence
  criteria and derivative estimation follow RSiena's published
  standards (t-ratios < 0.1, `tconv.max` < 0.25, score-function
  derivatives).
- **TERGM is CMPLE-only** (exact CMLE for dyad-independent formulas);
  no MCMC CMLE or EGMME.
- **relevent gaps**: no p-shift effects, no `CovSnd`/`CovRec`/`CovInt`
  blocks, no tie-correction for simultaneous events in the ordinal
  likelihood (ties are ranked arbitrarily, with a warning).

Where R semantics and an earlier version of these packages disagreed
(the `nodematch` `diff` keyword, directed GWESP's shared-partner
definition, doubled undirected degree, `sna`-style graph-level indices),
the packages now follow R; statistics that intentionally deviate carry
different names (e.g. the legacy either-direction directed GWESP is
`GWESP(0.5; type=:union)`, printed as `gwesp.union.fixed.0.5`, so it can
never be confused with statnet's `gwesp.fixed.0.5`).

## A complete worked example

The classic first statnet session — load Florentine marriage data,
describe it, fit an ERGM, check fit — translated end to end. In R:

```r
library(ergm)
data(florentine)
summary(flomarriage)
sna::degree(flomarriage, gmode="graph")
fit <- ergm(flomarriage ~ edges + nodecov("wealth") + gwesp(0.5, fixed=TRUE))
summary(fit)
gof(fit)
simulate(fit, nsim=3)
```

In Julia (the output below is what this code actually prints):

```julia
using ERGM, SNA, Random          # ERGM re-exports the Network.jl API

flo = load_dataset(:florentine_marriage)
println((nv(flo), ne(flo)))
println("density = ", round(gden(flo), digits=4))

deg = degree_centrality(flo)
fam = vertex_attribute_vector(flo, :name, String)
for v in sortperm(deg, rev=true)[1:3]
    println(fam[v], "  degree = ", Int(deg[v]))
end
```

Output:

```
(16, 20)
density = 0.1667
Medici  degree = 6
Guadagni  degree = 4
Strozzi  degree = 4
```

Fit the ERGM by MCMC maximum likelihood (`GWESP` makes the model
dyad-dependent, so we skip MPLE):

```julia
result = ergm(flo, [Edges(), NodeCov(:wealth), GWESP(0.5)];
              method=:mcmle, rng=Xoshiro(42))
println(result)
```

Output:

```
ERGM Results
============
Method: mcmle
Log-likelihood: -51.5584
AIC: 109.12, BIC: 117.48
Converged: true

Coefficients:
------------------------------------------------------------
edges                   -2.5532       0.54        0.0 ***
nodecov.wealth           0.0105      0.005     0.0361 *
gwesp.fixed.0.5         -0.0229     0.2741     0.9333
------------------------------------------------------------
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

Wealth attracts marriage ties (as in every statnet tutorial); there is
no extra triadic closure beyond it. Post-estimation works exactly as the
R muscle memory expects, through the StatsAPI verbs and `gof`/
`simulate_ergm`:

```julia
println("coef = ", round.(coef(result), digits=4))
println("se   = ", round.(stderror(result), digits=4))

g = gof(result; n_sim=100, rng=Xoshiro(1))
println("degree GOF p-values (degree 0-6): ",
        round.(g.results[:degree].p_values[1:7], digits=2))

sims = simulate_ergm(result; n_sim=3, rng=Xoshiro(2))
println("simulated densities: ", round.(gden.(sims), digits=3))
```

Output:

```
coef = [-2.5532, 0.0105, -0.0229]
se   = [0.54, 0.005, 0.2741]
degree GOF p-values (degree 0-6): [1.0, 1.0, 0.54, 0.24, 1.0, 0.5, 0.62]
simulated densities: [0.158, 0.142, 0.142]
```

No GOF p-value flags a misfit, and simulated networks reproduce the
observed density (0.167). From here, the corresponding R-to-Julia moves
are: panels over time → [TERGM.jl](/examples/modelling-network-change/),
actor-oriented dynamics → Siena.jl (above), event streams →
[REM.jl](/examples/modelling-interaction-events/).
