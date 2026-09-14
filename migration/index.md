@def title = "Coming from statnet / RSiena"
@def hascode = true
@def mintoclevel = 2

# Coming from statnet / RSiena

This page maps the R workflows you already know — statnet's
`network`/`sna`/`ergm` stack, `RSiena`, and `relevent` — onto their Julia
equivalents, package by package and verb by verb. It ends with a
[complete worked example](#a_complete_worked_example) (loading a classic
dataset, describing it, fitting an ERGM by MCMC MLE, checking fit), and a list
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
   `stderror`, and `vcov` share function identities across packages. Likelihood,
   AIC and BIC are available only where defined for the estimator; Siena's
   Method of Moments has none. See the [generated accessor table](/capabilities/).
   `using ERGM, Siena, REM` together preserves the shared bindings.

\toc

## The package map

| R package | Julia package | Main entry points |
|:---|:---|:---|
| `network` | [Networks.jl](https://github.com/statistical-network-analysis-with-Julia/Networks.jl) | `network`, `network_from_matrix`, `load_dataset` |
| `sna` | [SNA.jl](https://github.com/statistical-network-analysis-with-Julia/SNA.jl) | `degree_centrality`, `gden`, `triad_census`, ... |
| `ergm` | [ERGM.jl](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl) | `ergm` / `fit_ergm`, `gof`, `simulate_ergm` |
| `ergm.count` | [ERGMCount.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl) | `ergm_count` |
| `ergm.ego` | [ERGMEgo.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl) | `ergm_ego`, `as_egodata` |
| `ergm.multi` | [ERGMMulti.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl) | `ergm_multi` |
| `ergm.rank` | [ERGMRank.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl) | `ergm_rank`, `as_rank_network` |
| `ergm.userterms` | [ERGMUserterms.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl) | `@ergm_term`, `validate_term`, `test_term` |
| `tergm` | [TERGM.jl](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl) | `stergm`, `gof`, `simulate_network_sequence` |
| `RSiena` | [Siena.jl](https://github.com/statistical-network-analysis-with-Julia/Siena.jl) | `siena_data`, `get_effects`, `fit_siena` / `siena07`, `gof` |
| `relevent` | [REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl) + [Relevent.jl](https://github.com/statistical-network-analysis-with-Julia/Relevent.jl) | `fit_rem`; `fit_relevent` / `rem_dyad` |
| `networkDynamic` | [NetworkDynamic.jl](https://github.com/statistical-network-analysis-with-Julia/NetworkDynamic.jl) | `DynamicNetwork`, `activate!`, `network_extract` |
| `tsna` | [TSNA.jl](https://github.com/statistical-network-analysis-with-Julia/TSNA.jl) | `t_sna_stats`, `earliest_arrival`, `forward_reachable_set` |
| `ndtv` | [NDTV.jl](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl) | `render_animation`, `filmstrip`, `timeline_plot` |

Use Julia 1.12 or newer and the published
[workspace recipe](https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io/tree/main/tools/workspace)
to clone the sibling repositories and prepare `.snippet-env`. The packages
remain unreleased; successful local snapshot validation does not establish a
registry release or make unpushed changes available to other users.

`using ERGM` and its variants re-export selected everyday network operations,
including construction, edge updates, attributes and datasets. Use
`using Networks` explicitly when you need its wider conversion and metadata API.
The module is `Networks`; `Network` is its network type.

## Networks: `network` → Networks.jl

| R (`network`) | Julia (Networks.jl) |
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
| `triad.census(net)` | `triad_census(net)` (edge-driven Batagelj–Mrvar algorithm) |
| `centralization(net, degree)` | `centralization(net, :degree)` (also `:betweenness`, `:closeness`, `:eigenvector`) |
| `qaptest(list(g1, g2), gcor, g1=1, g2=2)` | `qaptest(gcor, g1, g2; reps=1000)` |
| `netlm(y, x)` | `netlm(y, x)` (Dekker DSP default, `nullhyp=:qapy/:qapx/:classical`) |
| `netlogit(y, x)` | `netlogit(y, x)` |
| `geodist(net)` | `geodesic_distance(net)` |
| `component.dist(net)` | `component_dist(net)` — but see [differences](#what_still_differs_from_r) |
| `kcores(net)` | `kcores(net)` |
| `cutpoints(net)` | `cutpoints(net)` |
| `clique.census(net)` (maximal cliques) | `cliques(net)` |
| `sedist / equiv.clust / blockmodel` | `structural_equivalence` / `equiv_clust` / `blockmodel` |
| `rgraph(20, tprob=0.1)` | `rgraph(20; tprob=0.1)` |

SNA.jl compares these measures with provenanced R fixtures on selected
undirected, directed, and two-mode networks. The [capability matrix](/capabilities/)
reports the fixture versions and datasets; those checks do not establish
equivalence for every input.

## ERGMs: `ergm` → ERGM.jl

The R formula becomes a vector of term objects:

```r
# R
data(sampson)
fit <- ergm(samplike ~ edges + mutual + nodematch("group", diff=TRUE))
```

```julia
# Julia
using ERGM, Random               # ERGM re-exports common network operations

net = load_dataset(:sampson)     # statnet's samplike
levels = ["Loyal", "Outcasts", "Turks"]
fit = ergm(net, [Edges(); Mutual();
                 [NodeMatch(:group; diff=true, level=l) for l in levels]];
           method=:mcmle, rng=Xoshiro(7))
println(fit)
```

Fitted coefficient tables use Networks.jl's shared presentation layer.
Likelihood-based tables display estimates, standard errors, z values and
p-values; permutation tables label their reference distribution and resolution.

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
| `nodefactor("g")` | `NodeFactor(:g)` — expands to one statistic per level at model construction, first (sorted) level dropped, like R; `base=0` keeps all levels |
| `nodematch("x")` | `NodeMatch(:x)` |
| `nodematch("x", diff=TRUE)` | `[NodeMatch(:x; diff=true, level=l) for l in levels]` |
| *(count of mismatched edges)* | `NodeMismatch(:x)` |
| `absdiff("age")` | `AbsDiff(:age)` |
| `nodemix("g")` | `NodeMix(:g)` — expands to one statistic per mixing cell, first cell dropped, like R; `levels2` selects cells |
| `edgecov(m)` | `EdgeCov(m)` |
| `degree(0:2)` | `Degree(0:2)` — expands to one term per degree (undirected) |
| `idegree(d)` / `odegree(d)` | `IDegree(d)` / `ODegree(d)` (directed) |
| `gwesp(0.5, fixed=TRUE)` | `GWESP(0.5)` |
| `dgwesp(0.5, type="OSP", fixed=TRUE)` | `GWESP(0.5; type=:OSP)` (`:OTP`, `:ITP`, `:OSP`, `:ISP`) |
| `gwdsp(0.5, fixed=TRUE)` / `dgwdsp(...)` | `GWDSP(0.5)` / `GWDSP(0.5; type=:OSP)` |
| `gwdegree(0.5, fixed=TRUE)` | `GWDegree(0.5)` |
| `gwidegree(0.5, fixed=TRUE)` / `gwodegree(...)` | `GWIDegree(0.5)` / `GWODegree(0.5)` |

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

Variants share StatsAPI function names. The [generated table](/capabilities/) records which calls return a quantity, an explicit NaN, or are unavailable.

## Temporal ERGMs: `tergm` → TERGM.jl

| R (`tergm`) | Julia (TERGM.jl) |
|:---|:---|
| `stergm(nw_list, formation=~edges+mutual, dissolution=~edges, estimate="CMLE")` | `stergm(networks, [Edges(), Mutual()], [Edges()])` |
| `tergm(nw_list ~ Form(~edges) + Persist(~edges), estimate="CMLE")` | same — the dissolution model is parameterized as *persistence*, like `Persist()` |
| bootstrap SEs (`btergm`-style) | `stergm(...; se=:bootstrap, n_boot=200)` |
| `gof(fit)` | `gof(fit)` (`stergm_gof` remains an alias) |
| `simulate(fit)` | `simulate_network_sequence(model, init, n_steps, θ_form, θ_diss)` |

Estimation is conditional maximum pseudo-likelihood (CMPLE) on the
Krivitsky–Handcock formation (union) and dissolution (intersection)
networks — exact CMLE for dyad-independent models; MCMC-based CMLE and
EGMME are not implemented; `method=:cmle` and `TERGM.egmme` throw explicit errors. See the [worked STERGM example](/examples/modelling-network-change/).

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
| `sienaAlgorithmCreate(seed=42)` | `siena_algorithm(rng=MersenneTwister(42))` |
| `siena07(alg, data=dat, effects=eff)` | `fit_siena(data, effects; algorithm=alg)` (`siena07` is an alias) |
| `sienaAlgorithmCreate(cond=TRUE)` | `siena_algorithm(conditional=true)` (rates from phase-3 stopping times, in `result.rate_estimates`) |
| `sienaCompositionChange(...)` | `CompositionChange()` + `add_change!` + `add_composition_change!(data, cc)` |
| `sienaGOF(res, IndegreeDistribution, ...)` | `gof(result, IndegreeDistribution(:friendship); n_sim=100, rng=Xoshiro(2))` |

Effect names such as `:outdegree`, `:recip`, and `:transTrip` follow RSiena.
The package has 150+ implementations; reference parity is checked for **34
selected deterministic targets and one fitted s50 model**, not the whole catalogue.
Estimation uses simulated Method of Moments, capped Newton refinement, and an
independent final validation batch. A returned default fit must have every
convergence |t-ratio| < 0.1, `tconv_max` < 0.25, and an identifiable derivative.
Unconverged fits raise `SienaConvergenceError`; `allow_unconverged=true` returns
warning-bearing diagnostic results, which should not be used for inference.

The Networks bridge is an ordinary hard dependency. This example uses the
bundled s50 friendship panel and smoking covariate from the reference model:

```julia
using Networks, Siena, Random
s50 = load_dataset(:s50)
data = siena_data()
add_nodeset!(data, NodeSet(50))
add_dependent!(data, DependentNetwork(:friendship, s50.friendship))
add_covariate!(data, ConstantCovariate(:smoke1, s50.smoke[:, 1]))
effects = get_effects(data)
include_effects!(effects, :friendship,
    [:outdegree, :recip, :transTrip, :altsmoke1, :egosmoke1, :simsmoke1])
result = fit_siena(data, effects; rng=MersenneTwister(1),
                   algorithm=SienaAlgorithm(verbose=false))
@assert result.converged
println(result)
result.derivative_matrix
result.phase3_cov
```

Repeat independent seeds, inspect convergence and goodness of fit, and assess
whether the observation and effect assumptions suit the research question.
Conditional estimation uses finite-difference derivatives and can fail the
strict criteria on models where unconditional estimation succeeds. Raw D and
Sigma are exposed; standard errors use the sandwich `D⁻¹ Sigma D⁻ᵀ` without a
fixed ridge. Structural codes 10/11 describe determined ties, not missing ties.
Live-behavior selection effects, maximum likelihood and Bayesian estimation
remain outside the built-in supported workflow.

## Relational events: `relevent` → REM.jl / Relevent.jl

Two packages split R `relevent`'s territory. REM.jl holds the event
types, 25+ statistics, and a case-control-sampled estimator for long
event streams; Relevent.jl adds `rem.dyad`'s two exact full-risk-set
likelihoods (ordinal and interval timing) plus decay-weighted history
statistics.

| R (`relevent`) | Julia |
|:---|:---|
| event list `(time, sender, receiver)` | `Event(sender, receiver, time)`; `EventSequence(events)` |
| `rem.dyad(el, n, effects=..., ordinal=TRUE)` | `fit_relevent(events, stats, n)` (= `fit_obpm`) — exact ordinal likelihood; `rem_dyad` is an alias |
| `rem.dyad(el, n, effects=..., ordinal=FALSE)` | `fit_relevent(events, stats, n; ordinal=false)` (= `fit_timing`) — exponential-baseline interval timing, `t0` sets the observation onset |
| large-stream approximate fit (eventnet-style) | `fit_rem(seq, stats; n_controls=100)` — case-control conditional logit |
| `"FESnd"`, `"FERec"`, `"FEInt"` | `FESnd(actor)`, `FERec(actor)`, `FEInt(actor)` (one contrast per selected actor) |
| `"RRecSnd"`, `"RSndSnd"` (inverse recency ranks) | `RRecSnd(n_actors)`, `RSndSnd(n_actors)` |
| reciprocity effects | `Reciprocity()`, `PriorInteraction(halflife; direction=:incoming)` |
| `"PSAB-BA"` p-shifts | `PShift(:AB_BA)` or `PShift("PSAB-BA")` — all 13 Gibson shifts (`pshift_types()`) |
| `covar=list(CovSnd=z, ...)` | `CovSnd(z)`, `CovRec(z)`, `CovInt(z)` |
| `covar=list(CovEvent=x)` | `CovEvent(dyad_matrix)` (one static sender-by-receiver matrix) |
| `"OTPSnd"`, `"ITPSnd"`, `"ISPSnd"` | `OTPSnd(n_actors)`, `ITPSnd(n_actors)`, `ISPSnd(n_actors)` (R weighted-history definitions) |
| normalized degree effects | `NIDSnd(n_actors)`, `NIDRec(n_actors)`, `NODSnd(n_actors)`, `NODRec(n_actors)`, `NTDegSnd(n_actors)`, `NTDegRec(n_actors)` |
| `coef(fit)`, `summary(fit)` | `coef(fit)`, `stderror(fit)`, `println(fit)` |

```julia
using Networks, REM, Relevent
calls = load_dataset(:wtc_police_calls)
events = [Event(row[2], row[3], Float64(row[1])) for row in eachrow(calls.events)]
n_actors = calls.n_actors
# Catalogue constructors take the eligible universe, including nonparticipants.
recency = [RRecSnd(n_actors), RSndSnd(n_actors)]
normalized_degrees = [NIDSnd(n_actors), NIDRec(n_actors), NODSnd(n_actors),
                      NODRec(n_actors), NTDegSnd(n_actors), NTDegRec(n_actors)]
weighted_paths = [OTPSnd(n_actors), ITPSnd(n_actors), ISPSnd(n_actors)]
fit = fit_obpm(events, [PShift(:AB_BA), CovSnd(Float64.(calls.is_icr))], calls.n_actors)
println(fit)
```

The data contain 481 ordered calls and 37 eligible actors, including actors who
do not appear at event endpoints. The first column is an event index, so use an
ordinal model; it cannot justify a waiting-time likelihood. The
[worked REM example](/examples/modelling-interaction-events/) explains the risk
set and compares distinct specifications without implying causal effects.

For genuine elapsed-time data, `fit_timing` exposes the log-baseline first in
`coef`, `stderror`, `vcov`, and `coeftable`; legacy `.coefficients` and
`.std_errors` contain effects only. Timing likelihoods require statistics that
are constant between events: p-shifts, catalogue effects, and static covariates
qualify. Finite-half-life decay statistics vary inside the waiting interval and
are rejected by `fit_timing`; they remain available for ordinal/conditional
fits. Cumulative-history variants with `halflife=Inf` can be used for timing.
Tied events require an explicit supported
policy; default exact-order/time fits reject them. The R-named effects have
provenanced design fixtures. `FrPSndSnd`, `FrRecSnd`, `OSPSnd`, event-indexed
covariate arrays, and Bayesian fitting remain unsupported.

Both Relevent fitters reject a verified separating direction when no finite
maximum-likelihood estimate exists. This check does not detect every boundary
case; inspect convergence and uncertainty before interpreting coefficients.

REM's sampled likelihood uses a declared actor universe. Its Hessian reflects
the information lost through control sampling under correct specification;
`se=:sandwich` offers event-clustered score uncertainty. `se=:bootstrap` is
rejected. `control_draw_cov` reports redraw sensitivity and must not be added
as an allegedly omitted variance component.

## Dynamic networks: `networkDynamic` / `tsna` / `ndtv`

| R | Julia |
|:---|:---|
| `networkDynamic()` | `DynamicNetwork(10; observation_start=0.0, observation_end=100.0)` |
| `activate.vertices(nd, onset, terminus, v=1)` | `activate!(dnet, onset, terminus; vertex=1)` |
| `activate.edges(nd, onset, terminus, ...)` | `activate!(dnet, onset, terminus; edge=(1, 2))` |
| `is.active(nd, at=2, e=...)` | `is_active(dnet, 2.0; edge=(1, 2))` |
| `network.extract(nd, at=2)` | `network_extract(dnet, 2.0)` (returns a `Network`) |
| `network.collapse(nd, onset, terminus)` | `network_collapse(dnet; onset=onset, terminus=terminus)` |
| `as.networkDynamic(net)` | `as_dynamic_network(net)` |
| `get.edge.activity(nd)` | `get_edge_activity(dnet)` |
| `tSnaStats(nd, "gden")` | `t_sna_stats(dnet, times; measures=[:density])` |
| `tPath(nd, v=1, start=0)` | `earliest_arrival(dnet, 1, 0.0)` / `shortest_temporal_path(dnet, 1, 5, 0.0)` |
| `tReach(nd, v=1)` | `forward_reachable_set(dnet, 1, 0.0)` |
| `tEdgeFormationAt(nd, ...)` | `t_edge_formation(dnet, onset, terminus)` (also `t_edge_dissolution`, `t_edge_persistence`) |
| `render.animation(nd)` | `render_animation(dnet; n_frames=50)` then `export_movie` / `export_gif` |
| `render.d3movie(nd)` | `export_html(layout, "movie.html")` (self-contained HTML) |
| `filmstrip(nd)` | `filmstrip(dnet, times)` |
| `timeline(nd)` | `timeline_plot(dnet)` |

TSNA.jl and NDTV.jl now follow the rest of the ecosystem: snake_case
primary names (`t_sna_stats`, `earliest_arrival`, ...), with the R
tsna/ndtv camelCase spellings (`tSnaStats`, `earliestArrival`,
`transmissionTimeline`, ...) kept as exported aliases — your R muscle
memory keeps working, but new code can be idiomatic Julia.

Temporal density uses active vertices by default; pass `active_only=false` for
the full actor universe. Reciprocity defaults to `method=:dyadic`, including
null dyads; use `:edgewise` for the fraction of reciprocated edges. Queries
reject unobserved dyads unless `missing=:face` is explicit. Centrality vectors
retain original actor indexing. `length(path)` counts edges; unreachable paths
return `nothing`. Date/DateTime durations are converted to seconds where scalar
rates or durations are reported. `MDSLayout` is the deterministic classical-MDS
layout; the deprecated `KKLayout` alias does not implement Kamada–Kawai.

## What still differs from R

The following differences reflect the September continuation:

- **Model syntax:** pass typed terms instead of an R formula. `fit_ergm` defaults
  to MPLE; request `method=:mcmle` for likelihood fitting of dependent models.
  MCMLE includes a Monte Carlo covariance component; `bridge_rungs=0` skips
  bridge likelihood evaluation and makes likelihood criteria unavailable.
- **ERGM coverage:** curved estimation, bipartite ERGM terms, offsets, and
  general `constraints=` remain unavailable. Two-mode networks are supported
  in Networks/SNA but explicitly refused by these ERGM fitters.
- **Rank models:** swap-MPLE is a pseudo-likelihood, while `method=:mcmle`
  estimates the ranking likelihood. They are different objectives, even when
  numerical estimates happen to coincide.
- **Missing observations:** ERGM MPLE excludes masked dyads. ERGM MCMLE rejects
  them by default; `missing=:mle` integrates over missing ties using free and
  constrained chains. `missing=:condition_on_face` fixes stored values and is a
  different approximation. Siena lacks missing-tie estimation, and REM assumes
  observed event histories. Structural zeros/ones are not missing ties.
- **Siena:** Method of Moments only, with strict convergence failure. The
  reference checks cover selected effects and one unconditional model.
  Endowment/creation effects simulate but do not estimate; interactions and
  built-in live-behavior selection remain unavailable. Conditional fits need
  their own convergence and scientific assessment.
- **SNA:** strong directed component defaults and all-actor closeness now match
  the stated R conventions. Weighted shortest paths, full R equivalence
  catalogues, and large sparse spectral/flow solvers remain gaps. QAP Wald
  inference requires identifiable fits in every permutation; separation fails
  explicitly rather than silently dropping replications.
- **TERGM:** CMPLE, exact for dyad-independent formulas; dependent CMLE and
  EGMME are unavailable. Dissolution-model coefficients describe persistence;
  prefer the `persistence_coef` and `persistence_se` accessors.
- **Relevent:** the effect and time-data limitations above still apply. No
  implementation should be treated as complete R feature parity merely
  because selected golden fixtures pass.

Where R semantics and an earlier version of these packages disagreed
(the `nodematch` `diff` keyword, directed GWESP's shared-partner
definition, doubled undirected degree, `sna`-style graph-level indices),
the packages now follow R; statistics that intentionally deviate carry
different names (e.g. the legacy either-direction directed GWESP is
`GWESP(0.5; type=:union)`, printed as `gwesp.union.fixed.0.5`, so it can
never be confused with statnet's `gwesp.fixed.0.5`).

These realignments are version-0.2 behavior changes: if you have code
written against the 0.1 packages (rather than against R), see the
[consolidated 0.2.0 release notes](/post/2026-07-12-changelogs-0.2.0/) —
every package repository now carries a `CHANGELOG.md` listing its breaking
changes with one-line migration hints (e.g.
[ERGM.jl's](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl/blob/main/CHANGELOG.md)).

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

In Julia:

```julia
using ERGM, SNA, Random          # ERGM re-exports common network operations

flo = load_dataset(:florentine_marriage)
println((nv(flo), ne(flo)))
println("density = ", round(gden(flo), digits=4))

deg = degree_centrality(flo)
fam = vertex_attribute_vector(flo, :name, String)
for v in sortperm(deg, rev=true)[1:3]
    println(fam[v], "  degree = ", Int(deg[v]))
end
```

Fit the ERGM by MCMC maximum likelihood (`GWESP` makes the model
dyad-dependent, so we skip MPLE):

```julia
result = ergm(flo, [Edges(), NodeCov(:wealth), GWESP(0.5)];
              method=:mcmle, rng=Xoshiro(42))
println(result)
```

Inspect the wealth and shared-partner coefficients with their uncertainty.
An association with wealth does not establish a causal effect, and a small
shared-partner coefficient does not establish absence of social closure.
Continue with the shared StatsAPI accessors and simulation diagnostics:

```julia
println("coef = ", round.(coef(result), digits=4))
println("se   = ", round.(stderror(result), digits=4))

g = gof(result; n_sim=100, rng=Xoshiro(1))
deg_panel = only(s for s in g.statistics if s.name == "degree")
println("degree GOF p-values (degree 0-6): ",
        round.(deg_panel.p_values[1:7], digits=2))

sims = simulate_ergm(result; n_sim=3, rng=Xoshiro(2))
println("simulated densities: ", round.(gden.(sims), digits=3))
```

Assess the simulated distributions, including features not directly fitted.
GOF p-values alone cannot establish that a model is correct; estimates and
diagnostics vary with Monte Carlo draws. Further workflows include
panels over time → [TERGM.jl](/examples/modelling-network-change/),
actor-oriented dynamics → Siena.jl (above), event streams →
[REM.jl](/examples/modelling-interaction-events/).
