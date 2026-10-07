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
   `coefnames` (R's `names(coef(fit))`), `stderror`, `vcov` and `coeftable`
   share function identities across packages. Likelihood,
   AIC and BIC are available only where defined for the estimator; Siena's
   Method of Moments has none. See the [generated accessor table](/capabilities/).
   `using ERGM, Siena, REM` together preserves the shared bindings.

## The package map

| R package | Julia package | Main entry points |
|:---|:---|:---|
| `network` | [NetworkCore.jl](https://github.com/statistical-network-analysis-with-Julia/NetworkCore.jl) | `network`, `network_from_matrix`, `load_dataset` |
| `sna` | [SNA.jl](https://github.com/statistical-network-analysis-with-Julia/SNA.jl) | `degreecent`, `betweenness`, `gden`, `triad_census`, `qaptest`, ... |
| `ergm` | [ERGM.jl](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl) | `ergm` / `fit_ergm`, `gof`, `simulate_ergm` |
| `ergm.count` | [ERGMCount.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl) | `ergm_count` |
| `ergm.ego` | [ERGMEgo.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl) | `ergm_ego`, `as_egodata` |
| `ergm.multi` | [ERGMMulti.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl) | `ergm_multi` |
| `ergm.rank` | [ERGMRank.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl) | `ergm_rank`, `as_rank_network` |
| `ergm.userterms` | [ERGMUserterms.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl) | `@ergm_term`, `validate_term`, `test_term` |
| `tergm` | [TERGM.jl](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl) | `stergm`, `gof`, `simulate_stergm` |
| `RSiena` | [Siena.jl](https://github.com/statistical-network-analysis-with-Julia/Siena.jl) | `siena_data`, `get_effects`, `fit_siena` / `siena07`, `gof` |
| `relevent`, `remstats` | [REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl) + [Revel.jl](https://github.com/statistical-network-analysis-with-Julia/Revel.jl) | `fit_rem`; `fit_revel` / `revel`, `effect_catalogue` |
| `networkDynamic` | [DynamicNetworks.jl](https://github.com/statistical-network-analysis-with-Julia/DynamicNetworks.jl) | `DynamicNetwork`, `activate!`, `network_extract` |
| `tsna` | [TSNA.jl](https://github.com/statistical-network-analysis-with-Julia/TSNA.jl) | `t_sna_stats`, `earliest_arrival`, `forward_reachable_set` |
| `ndtv` | [NDTV.jl](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl) | `render_animation`, `filmstrip`, `timeline_plot` |

Use Julia 1.12 or newer and the published
[workspace recipe](https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io/tree/main/tools/workspace)
to clone the sibling repositories and prepare `.snippet-env`. The packages
remain unreleased; successful local snapshot validation does not establish a
registry release or make unpushed changes available to other users.

`using ERGM` and its variants re-export selected everyday network operations,
including construction, edge updates, attributes and datasets. Use
`using NetworkCore` explicitly when you need its wider conversion and metadata API.
The module is `NetworkCore`; `Network` is its network type.

## Renamed packages and removed names

Two packages were renamed before their first release: **Networks.jl is now
NetworkCore.jl** and **NetworkDynamic.jl is now DynamicNetworks.jl**. Write
`using NetworkCore` and `using DynamicNetworks`; the types (`Network`,
`BipartiteNetwork`, `DynamicNetwork`) and every function keep their names.
`Networks` is an unrelated package in Julia's General registry, and
`NetworkDynamic` was one letter away from General's `NetworkDynamics`.

None of the packages has been released, so names that changed during
development were **removed, not deprecated**: an old name is undefined, and
an old keyword is an error. Each package documents its changes in a table:

| Package | Removed or renamed (examples) | Table |
|:---|:---|:---|
| NetworkCore.jl | the module name `Networks`; `at_boundary` in `newton_fit`'s result | [Renamed in 0.2.0](/NetworkCore.jl/dev/#Renamed-in-0.2.0) |
| SNA.jl | `bonacich_power` → `bonpow`, `geodesic_distance` → `geodist`, `reciprocity` → `grecip`, `structural_equivalence` → `sedist`; `reps=` → `n_sim=` | [Renamed in 0.2.0](/SNA.jl/dev/api/utilities/#Renamed-in-0.2.0) |
| ERGM.jl | `mcmle`'s `tol=` and `max_iter=` | [Renamed and removed names](/ERGM.jl/dev/api/estimation/#renames) |
| ERGMCount.jl | `fit_count_ergm` → `fit_ergm_count` / `ergm_count` | [Renamed and removed names](/ERGMCount.jl/dev/api/estimation/#Renamed-and-removed-names) |
| ERGMEgo.jl | `fit_ego_ergm` → `fit_ergm_ego` / `ergm_ego`; `max_iter=`, `tol=`, `ego_design(ppopsize=)` | [Renamed and removed names](/ERGMEgo.jl/dev/api/estimation/#Renamed-and-removed-names) |
| ERGMMulti.jl | `fit_multi_ergm` → `fit_ergm_multi` / `ergm_multi` | [Renamed and removed names](/ERGMMulti.jl/dev/api/estimation/#Renamed-and-removed-names) |
| TERGM.jl | `stergm_gof` → `gof`; `dissolution_coef`/`dissolution_se` → `persistence_coef`/`persistence_se` | [CHANGELOG](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl/blob/main/CHANGELOG.md) |
| Siena.jl | `parallel=` → `threaded=`; `seed=` → `rng=`; `n_sims=` → `n_sim=`; `:sharedIn`/`:sharedOut` → `:sharedInNbrs`/`:sharedOutNbrs` | [Names changed before the first release](/Siena.jl/dev/guide/estimation/#Names-changed-before-the-first-release) |
| REM.jl | `seed=` → `rng=`; `NodeMatch` → `AttributeMatch`, `NodeMix` → `ActorMix`, `NetworkState` → `EventNetworkState` | [CHANGELOG](https://github.com/statistical-network-analysis-with-Julia/REM.jl/blob/main/CHANGELOG.md) |
| TSNA.jl | the camelCase names (`earliestArrival`, `tBetweenness`, …) and `shortest_temporal_path` | [Renamed functions](/TSNA.jl/dev/guide/r_concordance/#Renamed-functions) |
| NDTV.jl | `KKLayout` → `MDSLayout`, `proximity_timeline` → `ego_timeline`, `transmissionTimeline` → `transmission_timeline` | [Renamed functions](/NDTV.jl/dev/r_concordance/#Renamed-functions) |

## NetworkCore: `network` → NetworkCore.jl

| R (`network`) | Julia (NetworkCore.jl) |
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
| `degree(net, gmode="graph")` | `degreecent(net)` (single-counted on undirected networks, like R) |
| `degree(net, cmode="indegree")` | `degreecent(net; cmode=:indegree)` |
| `betweenness(net)` | `betweenness(net)` (raw scores by default, like R) |
| `closeness(net)` | `closeness(net)` |
| `evcent(net)` | `evcent(net)` |
| `bonpow(net)` | `bonpow(net)` |
| `infocent(net)` | `infocent(net)` |
| `gden(net)` | `gden(net)` |
| `grecip(net)` | `grecip(net)` (`measure=:dyadic` by default, like R) |
| `gtrans(net)` | `gtrans(net)` |
| `mutuality(net)` | `mutuality(net)` |
| `dyad.census(net)` | `dyad_census(net)` |
| `triad.census(net)` | `triad_census(net)` (edge-driven Batagelj–Mrvar algorithm) |
| `centralization(net, degree)` | `centralization(net, degreecent)` or `centralization(net, :degree)` |
| `gcor(g1, g2)` | `gcor(g1, g2)` (diagonal excluded by default, like R's `diag=FALSE`) |
| `qaptest(list(g1, g2), gcor, g1=1, g2=2, reps=1000)` | `qaptest(gcor, g1, g2; n_sim=1000)` |
| `netlm(y, x)` | `netlm(y, x)` (Dekker DSP default, `nullhyp=:qapy/:qapx/:classical`) |
| `netlogit(y, x)` | `netlogit(y, x)` (a separated design warns and withholds inference; see below) |
| `geodist(net)` | `geodist(net)`: a named tuple `(counts, gdist)`, like R's list |
| `component.dist(net)` | `component_dist(net)` (`membership`, `csize`, `cdist`) — but see [differences](#what_still_differs_from_r) |
| `kcores(net)` (the core number of every vertex) | `kcores(net)`; the members of the k-core are `findall(>=(k), kcores(net))` |
| `cutpoints(net)` | `cutpoints(net)` |
| `clique.census(net)` (counts of maximal cliques by size) | `cliques(net; min_size=1)` lists the maximal cliques of every size; the default `min_size=3` leaves out isolates and dyads |
| `sedist / equiv.clust / blockmodel` | `sedist` / `equiv_clust` / `blockmodel` |
| `rgraph(20, tprob=0.1)` | `rgraph(20; tprob=0.1)` |

SNA.jl uses R `sna`'s function names, with `degreecent` for sna's `degree`,
whose name belongs to Graphs.jl. The Graphs.jl functions of the same family
(`degree_centrality`, `betweenness_centrality`, `closeness_centrality`,
`eigenvector_centrality`, `pagerank`, `density`, `diameter`) also accept a
`Network` and keep Graphs.jl's own definitions and normalizations, which differ
from sna's. Use the names in this table to reproduce R.

SNA.jl compares these measures with provenanced R fixtures on selected
undirected, directed, and two-mode networks. The [capability matrix](/capabilities/)
reports the fixture versions and datasets; those checks do not establish
equivalence for every input.

**Separation.** Every logistic, Poisson and conditional-logit fit in the
ecosystem decides separation with one exact verdict, and follows one policy,
as R's `glm`, `coxph` and `ergm` do: when no finite maximum exists, the fit
warns, returns `converged == false`, names the separated terms, and withholds
z values, p-values and confidence intervals (`NaN`). The coefficients and
standard errors stay in the result for diagnosis. For `netlogit` this
replaces an error. Its default QAP statistic, the signed root likelihood
ratio, exists on separated permutations; under sna's Wald statistic
(`statistic=:wald`) the p-values that would need them are withheld, with a
warning.

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
# Mutual() is dyad-dependent, so the default method=:auto fits the MCMLE, as R does
fit = ergm(net, [Edges(), Mutual(), NodeMatch(:group; diff=true)];
           rng=Xoshiro(7))
println(fit)
coefnames(fit)    # R's labels: "edges", "mutual", "nodematch.group.Loyal", …
```

Fitted coefficient tables use NetworkCore.jl's shared presentation layer.
Likelihood-based tables display estimates, standard errors, z values and
p-values; permutation tables label their reference distribution and resolution.

As in R, `NodeMatch(:group; diff=true)` expands into one statistic per
attribute level, in sorted order, labelled `nodematch.group.<level>`;
`levels=` selects levels, as R's `levels=` does, and `level=` builds the
statistic of a single level. `NodeFactor`, `NodeMix` and `Degree(0:3)`
expand the same way. ERGM.jl's own [Coming from R](/ERGM.jl/dev/guide/r_concordance/)
page maps `ergm`'s controls, terms and accessors in more detail.

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
| `nodematch("x", diff=TRUE)` | `NodeMatch(:x; diff=true)` — expands to one statistic per level, like R; `levels=` selects levels |
| *(count of mismatched edges)* | `NodeMismatch(:x)` |
| `absdiff("age")` | `AbsDiff(:age)` |
| `nodemix("g")` | `NodeMix(:g)` — expands to one statistic per mixing cell, first cell dropped, like R |
| `edgecov(m)` | `EdgeCov(m)` |
| `degree(0:2)` | `Degree(0:2)` — expands to one term per degree (undirected) |
| `idegree(d)` / `odegree(d)` | `IDegree(d)` / `ODegree(d)` (directed) |
| `gwesp(0.5, fixed=TRUE)` | `GWESP(0.5)` |
| `gwesp(0.5, fixed=FALSE)` (curved) | `GWESP(0.5; fixed=false)` — the decay is estimated by `mcmle` |
| `dgwesp(0.5, type="OSP", fixed=TRUE)` | `GWESP(0.5; type=:OSP)` (`:OTP`, `:ITP`, `:OSP`, `:ISP`) |
| `gwdsp(0.5, fixed=TRUE)` / `dgwdsp(...)` | `GWDSP(0.5)` / `GWDSP(0.5; type=:OSP)` |
| `gwdegree(0.5, fixed=TRUE)` | `GWDegree(0.5)` (`fixed=false` is curved, as for `GWESP`) |
| `gwidegree(0.5, fixed=TRUE)` / `gwodegree(...)` | `GWIDegree(0.5)` / `GWODegree(0.5)` |
| `offset(edges)` with `offset.coef=` | `Offset(Edges(), coef)`; `±Inf` forbids or forces ties |

Model construction *validates terms against the network*: a typo'd
attribute (`NodeCov(:welth)`) throws an `ArgumentError` listing the
attributes that do exist, instead of silently fitting a zero column.

### Estimation and post-estimation

| R (`ergm`) | Julia (ERGM.jl) |
|:---|:---|
| `summary(net ~ edges + triangle)` | `summary_stats(net, [Edges(), Triangle()])` |
| `fit <- ergm(net ~ ...)` | `fit = ergm(net, terms)` (`method=:auto`: R's rule, below) |
| `ergm(..., estimate="MPLE")` | `ergm(net, terms; method=:mple)` |
| `summary(fit)` | `println(fit)` |
| `coef(fit)` / `vcov(fit)` | `coef(fit)` / `vcov(fit)` (StatsAPI, plus `stderror`) |
| `names(coef(fit))` | `coefnames(fit)` (the same labels as the rows of `coeftable(fit)`) |
| `logLik(fit)`, `AIC(fit)`, `BIC(fit)` | `loglikelihood(fit)`, `aic(fit)`, `bic(fit)` |
| `gof(fit)` | `gof(fit; n_sim=100)` (degree, ESP, geodesic distance) |
| `simulate(fit, nsim=10)` | `simulate_ergm(fit; n_sim=10)` |
| `mcmc.diagnostics(fit)` | `mcmc_diagnostics(fit)` |
| `control.ergm(MCMC.burnin=..., MCMLE.maxit=...)` | the estimator's keywords: `ergm(net, terms; burnin=..., interval=..., maxiter=..., effective_size=..., rng=...)` for the MCMLE |
| `control.ergm(drop=FALSE)` | `ergm(net, terms; drop=false)`: refuses a boundary statistic (below) instead of fitting it |

**The default estimator is R's.** `ergm(net, terms)` takes `method=:auto`:
a formula with no dyad-dependent term is fitted by MPLE, which is then the
exact maximum-likelihood estimate (a logistic regression), and a formula
with any dyad-dependent term (`Mutual`, `Triangle`, `GWESP`, `Degree`, …)
by MCMLE, as R's `ergm()` does. `method=:mple` on a dyad-dependent formula
gives the fast pseudo-likelihood approximation: it reports estimates and
standard errors but no z values, p-values or intervals unless you ask for
`se=:bootstrap` (a parametric bootstrap). A keyword that only the other
estimator takes, such as `se=:bootstrap` under a default MCMLE fit, is an
`ArgumentError` that names the method that takes it.

**The MCMLE is R ergm 4's.** It samples with R's `SPDyad` proposal (tie/no-tie
mixed with a shared-partner proposal, exact Hastings ratio) and
ESS-adaptively to R's `MCMLE.effectiveSize = 64`. Every iteration takes a
Monte-Carlo Newton step with Hummel step-length control, and the stopping
rule is R's `confidence` equivalence test (`termination=:confidence`), with
R's enlarged sample when it fails and R's `maxiter = 60`;
`termination=:hotelling` restores the pre-0.2 rule. Standard errors include
the Monte-Carlo component (R's "MCMC %"), and a path-sampled (bridge)
log-likelihood gives AIC and BIC. A fit that exhausts `maxiter` is returned
with `converged == false` and a warning; continue it with
`init=coef(fit)`. `simulate_ergm`, `gof` and the other samplers default to
plain tie/no-tie (`proposal=:spdyad` selects R's).

**Boundary statistics and separation.** A statistic at the boundary of its
attainable range (a `NodeMatch` level with no within-level tie, a `NodeMix`
cell of a singleton level, `Triangle` on a network with no two-path) has no
finite estimate. Both estimators, and so every default fit, do what R's
default `drop=TRUE` does: they warn with R's sentence ("… are at their
smallest attainable values. Their coefficients will be fixed at -Inf"), fix
that coefficient at `-Inf` (or `+Inf`, standard error 0) and estimate the
rest; the MCMLE holds the statistic at its bound while it samples. No
`Offset(term, -Inf)` is needed, and the statnet tutorial's Goodreau model
(`edges + nodematch("Race", diff=TRUE) + …` on faux.mesa.high) is typed as in
R. `drop=false` is the strict mode: it refuses such a model with an
`ArgumentError`, where R's `drop=FALSE` would fit it. A statistic that does
not vary at all, or is a linear combination of the others, is reported as
`NaN` where R reports `NA`. Two differences remain: a curved model with a
boundary statistic is refused, and a `GWESP`/`GWDSP`/`GWNSP` statistic of 0
is fixed at `-Inf`, where R fits a finite, unidentified coefficient. When a
dropped statistic is dyad-dependent, the MCMLE reports no log-likelihood
(`NaN`). A design separated by a combination of statistics follows the
shared separation policy [described above](#describing_networks_sna_snajl).

**User terms under MCMC.** The samplers delete a tie's edge attributes when
they toggle it, so a user-defined term that reads an edge attribute from the
network at evaluation time is refused by every sampler entry point with an
explanation; snapshot the attribute when the model is built, or pass a
matrix to `EdgeCov`. The MPLE is unaffected.

### The ERGM variants

| R call | Julia call |
|:---|:---|
| `ergm(net ~ sum, response="w", reference=~Poisson)` | `ergm_count(net, [SumTerm()]; reference=PoissonReference())` |
| valued `nodematch("g", form="sum")`, `nodefactor`, `absdiff`, `nodecov`, `nodeocov`, `nodeicov`, `edgecov` | `CountNodeMatchTerm(:g)`, `CountNodeFactorTerm(:g, "b")`, `CountAbsDiffTerm(:x)`, `CountNodeCovTerm(:x)`, `CountNodeOCovTerm(:x)`, `CountNodeICovTerm(:x)`, `CountEdgeCovTerm(W; name="w")` — `form=:sum` (the default) or `:nonzero`, with R's labels (`nodematch.sum.g`); `nodefactor` and `nodematch(diff=TRUE)` are one term per level |
| `ergm.ego(egodata ~ edges + nodematch("x"))` | `ergm_ego(egodata, [EgoEdges(), EgoNodeMatch(:x)])` |
| `ergm.ego` `nodefactor`, `nodecov`, `absdiff`, `degree` | `EgoNodeFactor(:x)`, `EgoNodeCov(:x)`, `EgoAbsDiff(:x)`, `EgoDegree(d)` |
| `ergm.ego` `gwesp(0.5, fixed=TRUE)`, `esp(k)`, `mm("x")`, `concurrent` | `EgoGWESP(0.5)`, `EgoESP(k)`, `EgoMM(:x)` (default form), `EgoConcurrent()`; the curved `gwesp` is refused |
| `ergm.multi` multilayer models | `ergm_multi(mnet, [LayerEdges(1), MultiplexMutual(1, 2), ...])` |
| `ergm.rank` | `ergm_rank(rnet, [RankDeference(), ...])` |
| `ergm.userterms` (C skeleton + rebuild) | `@ergm_term` macro, then `validate_term` / `test_term` — plain Julia, no recompilation |

- **`ergm_count` and `ergm_multi` take `method=:auto`** with ERGM.jl's rule:
  the MPLE for a dyad-independent formula, MCMLE otherwise. Both apply R's
  `drop=TRUE` to a statistic at its bound under either estimator (`drop=false`
  refuses); after a drop, `ergm_count`'s MCMLE reports no log-likelihood
  (`NaN`), where R reports one. A count model
  whose fitted coefficients make the distribution improper (for example a
  positive `mutual.product` under a Poisson reference) is flagged
  (`fit.improper`), and simulation, `gof` and the bootstrap refuse it unless
  you fix `max_val`.
- **`ergm_multi` labels coefficients as `ergm.multi` does**: `L(A)~edges`,
  `L(A&B)~edges`, `L((A,B))~x`, `offset(...)`. Its boundary handling is R
  `ergm`'s, not `ergm.multi`'s: a layer statistic at its bound (a triangle
  term on a layer with no two-path, a conjunction layer with no tie) is fixed
  at `∓Inf` and the rest estimated, where `ergm.multi` 0.3.0 reports `NA` or
  a finite value at which its estimation stopped. The matching R model is the
  statistic written as `offset(L(…))` at `-Inf`.
- **`ergm_rank` fits the rank MCMC MLE by default**, as `ergm.rank` does;
  `method=:mple` is a swap pseudo-likelihood that `ergm.rank` does not have.
  A count observed at 0 (nonconformity, the unweighted inconsistency) has no
  finite MLE. The swap-MPLE applies R's drop; the MCMLE refuses such a model
  and points to `method=:mple`, because the rankings that share the extreme
  value are not connected by single swaps, so the sampler cannot be held
  there (`ergm.rank`'s own sampler stops moving).
- **`ergm_ego` labels coefficients as `ergm.ego` does** (`edges`, `degree0`,
  `nodefactor.Race.Hisp`, `gwdeg.fixed.0.5`, `gwesp.fixed.0`, …), and a target
  at its bound (`degree0` on a sample without isolates) is fixed at `∓Inf`, as
  in `ergm.ego`. Its default pseudo-population has as many members as there
  are egos when the population size is unknown, as `ergm.ego`'s
  `ppopsize = "auto"` does.
- Separated count, multilayer and rank fits follow the shared separation policy.

Variants share StatsAPI function names, `coefnames` included. The [generated table](/capabilities/) records which calls return a quantity, an explicit NaN, or are unavailable.

## Temporal ERGMs: `tergm` → TERGM.jl

| R (`tergm` ≥ 4) | Julia (TERGM.jl) |
|:---|:---|
| `tergm(nw_list ~ Form(~edges+mutual) + Persist(~edges))` | `stergm(networks, [Edges(), Mutual()], [Edges()])` — the panel, then the formation terms, then the persistence terms |
| `stergm(nw_list, formation=~edges+mutual, dissolution=~edges)` (deprecated in R) | the same call; the dissolution model is parameterized as *persistence*, like `Persist()` |
| `estimate="CMLE"` (R's `tergm()` has no default and requires `estimate=`) | TERGM.jl's default `method=:auto`: the CMLE (`method=:cmle`, Monte-Carlo conditional MLE) when a term is dyad-dependent, the CMPLE when none is — there the two are the same estimator and no MCMC is run |
| `estimate="CMPLE"` | `method=:cmple` |
| `summary(fit)` of a CMPLE fit (naive Wald table) | `stergm(...; method=:cmple, se=:hessian)`; the CMPLE's default withholds z and p for a dyad-dependent formula |
| `estimate="EGMME"` | not implemented: `method=:egmme` throws an `ArgumentError` |
| `Diss(~…)` | not offered: `persistence_coef` has `Persist()`'s sign, and `Diss()` is its negation |
| bootstrap SEs over time steps (`btergm`'s scheme) | `stergm(...; method=:cmple, se=:block_bootstrap)` — resamples transitions; refused below 10 transitions |
| — | `stergm(...; method=:cmple, se=:bootstrap, n_boot=200)` — the parametric bootstrap: simulate every transition from the fit and refit, valid at any panel length |
| `summary(fit)` | `coeftable(fit)` (rows `Form(1)~edges`, …) or `println(fit)` |
| `gof(fit)` | `gof(fit)` (tie changes, model statistics, degree distributions) |
| `simulate(fit, nsim=1, time.slices=k)` | `simulate_stergm(fit, k)` — one chain, `k` steps forward from the last panel |
| `simulate(fit, nsim=k)` (`k` independent one-step draws) | `[simulate_stergm(fit, 1; rng=rng)[end] for _ in 1:k]` |

The model is Krivitsky and Handcock's separable one: formation on the union
of consecutive panels and dissolution, as persistence, on their
intersection. The CMLE fits each side with a dyad-dependent term by MCMC on
that side's free dyads, with ERGM.jl's MCMLE update and R ergm's
`confidence` stopping rule, and reports Fisher-plus-Monte-Carlo standard
errors. It is pinned against the exact conditional MLE and against `tergm`,
including the tergm tutorial's `edges + mutual + cyclicalties +
transitiveties` model. The CMPLE matches `tergm`'s CMPLE to 1e-6; for a
dyad-dependent formula it is a pseudo-likelihood whose naive standard errors
are too small, so use the CMLE or the parametric bootstrap for inference.
The block bootstrap is too optimistic on short panels. A statistic at the
boundary of its attainable range is fixed at `-Inf` by the CMPLE, as R
`ergm`'s `drop=TRUE` would (R `tergm` does not drop, and returns a large
finite value with a huge standard error); the CMLE refuses such a side,
since no finite MLE exists. See the
[worked STERGM example](/examples/modelling-network-change/).

## SAOMs: `RSiena` → Siena.jl

The workflow is a deliberate mirror of RSiena's:

| RSiena | Siena.jl |
|:---|:---|
| `sienaDataCreate(...)` | `data = siena_data()` + `add_nodeset!` / `add_dependent!` / `add_covariate!` |
| `sienaDependent(array)` | `DependentNetwork(:name, waves)` — waves are matrices **or `Network` objects** |
| `sienaDependent(array, type="bipartite", nodeSet=c("A", "B"))` | `DependentNetwork(:name, waves; type=:twomode, nodeset1=:A, nodeset2=:B)`; waves may also be two-mode `Network`s (`network(n; bipartite=n₁)`, `BipartiteNetwork`), which convert to a two-mode variable with ties from the mode-1 actors to the mode-2 nodes |
| `sienaDependent(mat, type="behavior")` | `DependentBehavior(:name, waves)` |
| `sienaDependent(..., allowOnly=FALSE)` | `DependentNetwork(:name, waves; allow_only=false)` (also `DependentBehavior`) |
| `coCovar(v)` / `varCovar(m)` | `ConstantCovariate(:name, v)` / `VaryingCovariate(:name, m)` |
| `coDyadCovar(m)` | `ConstantDyadCovariate(:name, m)` (also accepts a `Network`) |
| `getEffects(data)` | `effects = get_effects(data)` — with RSiena's default effects included: the basic rates, `outdegree` (RSiena's `density`), `recip` for a directed network, `linear` and `quad` for a behaviour |
| `includeEffects(eff, transTrip, cycle3)` | `include_effects!(effects, :friendship, [:transTrip, :cycle3])` |
| `includeEffects(eff, recip, include=FALSE)` | `include_effects!(effects, :friendship, [:recip]; include=false)` |
| `includeEffects(eff, egoX, interaction1="smoke1")` | `include_effects!(effects, :friendship, [:egoX]; interaction1=:smoke1)` (or `:egosmoke1`) |
| `includeInteraction(eff, egoX, recip, interaction1=c("smoke1", ""))` | `include_interaction!(effects, :friendship, :egosmoke1, :recip)` |
| `sienaAlgorithmCreate(seed=42)` | `siena_algorithm(rng=MersenneTwister(42))` |
| `siena07(alg, data=dat, effects=eff)` | `fit_siena(data, effects; algorithm=alg)`; `siena07` is an alias, and RSiena's orders `siena07(alg, data, effects)` and `siena07(alg; data=dat, effects=eff)` also work |
| `coef(fit)`, `fit$se`, `names` of the effects | `coef(result)`, `stderror(result)`, `coefnames(result)`, `coeftable(result)` |
| `sienaAlgorithmCreate(cond=FALSE)` | `siena_algorithm(conditional=false)`; conditional estimation is the default for one dependent variable, as RSiena's `cond = NA` |
| `siena07(..., useCluster=TRUE)` | `siena_algorithm(threaded=true)` (the default; `threaded=false` runs serially) |
| `sienaTimeTest(fit)` | `siena_time_test(fit)` |
| `sienaCompositionChange(...)` | `CompositionChange()` + `add_change!` + `add_composition_change!(data, cc)` |
| `sienaGOF(res, IndegreeDistribution, ...)` | `gof(result, IndegreeDistribution(:friendship); n_sim=100, rng=Xoshiro(2))` |

Effect names such as `:outdegree`, `:recip`, and `:transTrip` follow RSiena.
An RSiena short name in Siena.jl denotes RSiena's statistic, and this is
verified for every RSiena-named effect that `get_effects` offers: their
target statistics are compared with `RSiena:::getTargets`, their change
statistics with 38 models simulated by RSiena, and five fitted models
(unconditional, conditional, undirected, network–behaviour co-evolution, and
a model with `gwespFF` and an interaction) with RSiena's estimates within
RSiena's own seed-to-seed spread. The one-network shared-neighbour effects
that Siena.jl adds are `sharedInNbrs` and `sharedOutNbrs`; RSiena's
`sharedIn` is a different, two-network effect.

As in RSiena, a period in which the observed network only gains (or only
loses) ties restricts the simulation to such changes, and a network whose
every period is up-only gets no `outdegree` effect; `allow_only=false`
lifts this. Estimation uses the simulated Method of Moments followed by
capped Newton refinement and an independent final validation batch. A fit
that misses RSiena's convergence standard (every |t-ratio| < 0.1,
`tconv.max` < 0.25) is returned with a warning and flagged by `show` and
`approximations`, as RSiena returns it; `allow_unconverged=false` raises
`SienaConvergenceError` instead. Under conditional estimation the rates and
their standard errors come from the phase-3 stopping times, as in RSiena, and
agree with RSiena's, including in up-only and down-only periods.

The NetworkCore bridge is an ordinary hard dependency. This example uses the
bundled s50 friendship panel and smoking covariate from the reference model:

```julia
using NetworkCore, Siena, Random
s50 = load_dataset(:s50)
data = siena_data()
add_nodeset!(data, NodeSet(50))
add_dependent!(data, DependentNetwork(:friendship, s50.friendship))
add_covariate!(data, ConstantCovariate(:smoke1, s50.smoke[:, 1]))
effects = get_effects(data)        # RSiena's defaults: rates, outdegree, recip
include_effects!(effects, :friendship,
    [:transTrip, :altsmoke1, :egosmoke1, :simsmoke1])
result = fit_siena(data, effects; rng=MersenneTwister(1),
                   algorithm=SienaAlgorithm(verbose=false))
@assert result.converged
println(result)
result.rate_estimates[:friendship]   # conditional estimation: rates from stopping times
result.derivative_matrix
```

Repeat independent seeds, inspect convergence and goodness of fit, and assess
whether the observation and effect assumptions suit the research question.
The derivative matrix is the score-function estimator, as in RSiena.
Structural codes 10/11 describe determined ties, not missing ties.

## Relational events: `relevent` and `remstats` → REM.jl / Revel.jl

Two packages cover this territory. REM.jl holds the event types, eventnet's
statistics, and a case-control-sampled estimator for long event streams.
Revel.jl adds the effects, covariates and interactions of `relevent`,
`remstats` and the wider literature, fits `rem.dyad`'s two exact full-risk-set
likelihoods (ordinal and interval timing), and supplies goodness-of-fit checks.
Start from Revel.jl.

| R | Julia |
|:---|:---|
| event list `(time, sender, receiver)` | `Event(sender, receiver, time)`; `EventSequence(events)` |
| `rem.dyad(el, n, effects=..., ordinal=TRUE)` | `fit_revel(events, stats, n)` — exact ordinal likelihood over the full risk set; `revel` is an alias |
| `rem.dyad(el, n, effects=..., ordinal=FALSE)` | `fit_revel(events, stats, n; model=:timing)` — exponential-baseline interval timing; `t0` and `t_end` set the observation window |
| large-stream approximate fit (eventnet-style) | `fit_revel(events, stats, n; n_controls=100)` or `fit_rem(seq, stats; n_controls=100, rng=Xoshiro(1))` — case-control conditional logit |
| remstats `inertia(scaling="prop")`, `reciprocity(scaling="prop")`; the documented definitions of `"FrPSndSnd"`, `"FrRecSnd"` | `Inertia(scaling=:prop, empty=1/(n-1))`, `Reciprocation(scaling=:prop, empty=1/(n-1))` (relevent 1.2.1's own output for these two differs from its documentation) |
| remstats `inertia()`, `reciprocity()` | `Inertia()`, `Reciprocation()` |
| `"RRecSnd"`, `"RSndSnd"` (inverse recency ranks) | `RecencyRank(:receive)`, `RecencyRank(:send)` |
| `"PSAB-BA"` p-shifts | `PShift(:AB_BA)` or `PShift("PSAB-BA")` — all 13 Gibson shifts (`pshift_types()`) |
| `covar=list(CovSnd=z, ...)` | `SendEffect(z)`, `ReceiveEffect(z)`, `SumEffect(z)` (`CovInt` is a sum, not an interaction) |
| `covar=list(CovEvent=x)` | `TieEffect(dyad_matrix)` |
| `"OTPSnd"`, `"ITPSnd"`, `"ISPSnd"` | `OTP()`, `ITP()`, `ISP()`; `OSP()` follows `"OSPSnd"`'s documentation, not relevent 1.2.1's output |
| normalized degree effects (`"NIDSnd"`, …) | `IndegreeSender(scaling=:prop, empty=1/(n-1))` and the five other sender/receiver degree effects; remstats' `scaling="prop"` degrees use `empty=1/n` |
| remstats `memory = "decay"`, `"window"`, `"interval"` | `memory=HalfLife(h)`, `Window(w)`, `IntervalMemory(lo, hi)` on the configuration effects |
| remstats `a:b` | `Interaction(a, b)` |
| `coef(fit)`, `summary(fit)` | `coef(fit)`, `stderror(fit)`, `println(fit)` |

```julia
using NetworkCore, Revel
calls = load_dataset(:wtc_police_calls)
events = [Event(row[2], row[3], Float64(row[1])) for row in eachrow(calls.events)]
n_actors = calls.n_actors
coordinator = SendEffect(Float64.(calls.is_icr); name="coordinator")
# relevent's zero-history value for a degree share is 1/(n-1); in Revel it is a keyword.
stats = [PShift(:AB_BA), RecencyRank(:receive), coordinator,
         IndegreeSender(scaling=:prop, empty=1 / (n_actors - 1))]
fit = fit_revel(events, stats, n_actors)
println(coeftable(fit))
# The name each effect has in relevent, remstats, rem, goldfish and eventnet.
catalogue = effect_catalogue()
println(catalogue[catalogue.relevent .== "NIDSnd", [:revel, :relevent]])
```

The data contain 481 ordered calls and 37 eligible actors, including actors who
do not appear at event endpoints. The first column is an event index, so use an
ordinal model; it cannot justify a waiting-time likelihood. The
[worked REM example](/examples/modelling-interaction-events/) explains the risk
set and compares distinct specifications without implying causal effects.

For genuine elapsed-time data, `fit_revel(...; model=:timing)` exposes the
log-baseline first in `coef`, `stderror`, `vcov`, and `coeftable`. Timing
likelihoods require statistics that are constant between events: p-shifts,
full-memory effects, recency ranks and static covariates qualify. Decaying
memory kernels, elapsed-time effects and time-varying covariates change inside
the waiting interval and are rejected for timing fits; they remain available
for ordinal fits. Tied events require an explicit supported policy; default
exact-order/time fits reject them.

The same effect name does not mean the same number across R packages.
`effect_catalogue()` lists the Revel call that reproduces each one. Its
`remstats` column is pinned by a golden fixture against remstats 4.1.0 and its
`relevent` column against statistics validated on `rem.dyad`, except three
names (`FrPSndSnd`, `FrRecSnd`, `OSPSnd`) whose relevent 1.2.1 output departs
from their documentation; the `rem`, `goldfish` and `eventnet` columns follow
those packages' documentation. Under
`memory = "decay"` remstats evaluates the decay at the previous event, Revel at
the event being explained.

relevent's effects are Revel calls — `CovSnd` is `SendEffect(x)`, `FESnd` is
`SendEffect((1:n) .== k)`, `RRecSnd` is `RecencyRank(:receive)`, `NODSnd` is
`OutdegreeSender(scaling=:prop, empty=1/(n-1))`; `effect_catalogue()` and
Revel's concordance guide list them all, and two golden fixtures pin them and
both `rem.dyad` likelihoods against relevent 1.2.1. REM.jl's statistics mix
with Revel's inside `fit_rem`. Every route — the ordinal and timing fitters and the
sampled `fit_rem` — decides separation with the shared verdict: a separated
fit warns, returns `converged == false`, names the separated statistics and
withholds z values, p-values and intervals, and Revel's diagnostics refuse
it.

REM's sampled likelihood uses a declared actor universe. Its Hessian reflects
the information lost through control sampling under correct specification;
`se=:sandwich` offers event-clustered score uncertainty. `se=:bootstrap` is
rejected. `control_draw_cov` reports redraw sensitivity and must not be added
as an allegedly omitted variance component. Controls are drawn from the `rng`
keyword.

## Dynamic networks: `networkDynamic` / `tsna` / `ndtv`

| R | Julia |
|:---|:---|
| `networkDynamic()` | `DynamicNetwork(10; observation_start=0.0, observation_end=100.0)` (give both ends or neither, as `net.obs.period` has both) |
| `networkDynamic(network.list=list(w1, w2, w3))` | `DynamicNetwork([w1, w2, w3])` — one step per panel, vertices matched by position |
| `nd %n% "net.obs.period"` | `get_observation_period(dnet)`; `nothing` when none was set, as R's `NULL` |
| `activate.vertices(nd, onset, terminus, v=1)` | `activate!(dnet, onset, terminus; vertex=1)` |
| `activate.edges(nd, onset, terminus, ...)` | `activate!(dnet, onset, terminus; edge=(1, 2))` |
| `is.active(nd, at=2, e=..., active.default=TRUE)` | `is_active(dnet, 2.0; edge=(1, 2))` — an element with no spell record is active, as in R; pass `active_default=false` to change that |
| `network.extract(nd, at=2)` | `network_extract(dnet, 2.0)` (returns a `Network`) |
| `network.collapse(nd, onset, terminus)` | `network_collapse(dnet; onset=onset, terminus=terminus)` |
| `as.networkDynamic(net)` | `as_dynamic_network(net)` |
| `get.edge.activity(nd, e=…)`, `get.vertex.activity(nd, v=…)` | `get_edge_activity(dnet, i, j)`, `get_vertex_activity(dnet, v)` — one element per call; an element with no spell record is reported as `(-Inf, Inf)`, as in R |
| `tSnaStats(nd, "gden")` | `t_sna_stats(dnet, times; measures=[:density])` |
| `tPath(nd, v=1, start=0)` (earliest arrival from one vertex) | `earliest_arrival(dnet, 1, 0.0)`; `temporal_path(dnet, 1, 5, 0.0)` for the path to one target |
| `forward.reachable(nd, v=1)` | `forward_reachable_set(dnet, 1, 0.0)` |
| `tReach(nd)` (size of every vertex's forward-reachable set) | `vec(sum(reachability_matrix(dnet, 0.0); dims=2))` (no sampling; the diagonal counts the vertex itself) |
| `tEdgeFormation(nd)` (a series: ties formed at each time step) | `t_edge_formation(dnet, onset, terminus)` counts one interval; `t_turnover(dnet, 1)` gives tsna's default series on integer spells without an observation window (also `t_edge_dissolution`, `t_edge_persistence`) |
| `render.animation(nd)` | `render_animation(dnet; n_frames=50)` then `export_movie` / `export_gif`; by default 100 frames, or one frame per time step on an integer or calendar time axis (ndtv's `interval = 1`) |
| `render.d3movie(nd)` | `export_html(layout, "movie.html")` (self-contained HTML) |
| `filmstrip(nd)` | `filmstrip(dnet, times)` |
| `timeline(nd)` | `timeline_plot(dnet)` |
| `proximity.timeline(nd)` (MDS positions over time) | not ported; `ego_timeline(dnet, v)` is a different display: one actor's tie spells |
| `transmissionTimeline(tree)` (draws a transmission tree) | not ported; `transmission_timeline` marks events on a text timeline |
| `network.layout.animate.kamadakawai` | not ported; `MDSLayout()` is classical MDS |

TSNA.jl and NDTV.jl use snake_case names (`t_sna_stats`, `earliest_arrival`,
...), like the rest of the ecosystem. The camelCase names of the development
versions (`earliestArrival`, `tBetweenness`, ...), `shortest_temporal_path`,
`KKLayout`, `proximity_timeline` and `transmissionTimeline` were never
released and have been removed; the packages' rename tables map each to its
current name. Most of them were never tsna or ndtv functions, and where a
name is shared with R the arguments or the result differ, as in the table
above. Translate from R with this table and the packages' own concordance
pages, not by spelling:
[networkDynamic](/DynamicNetworks.jl/dev/guide/r_concordance/),
[tsna](/TSNA.jl/dev/guide/r_concordance/) and
[ndtv](/NDTV.jl/dev/r_concordance/).

Vertices and edges with no activity spell are active throughout, as with R's
`active.default = TRUE`. **Without an observation window**, nothing is
derived from the data: each TSNA statistic applies tsna's own rule for that
case (durations over the whole time axis, densities over the range of the
change times, paths to `Inf`), and NDTV renders the closed range of the
change times; set a window with `set_observation_period!` to clip to it.
Temporal density and the per-vertex measures use the
vertices active at the query time by default (absent actors get `NaN`); pass
`active_only=false` for the full actor universe. Reciprocity defaults to `method=:dyadic`, including
null dyads; use `:edgewise` for the fraction of reciprocated edges. Queries
reject unobserved dyads unless `missing=:face` is explicit. Centrality vectors
retain original actor indexing. `length(path)` counts edges; unreachable paths
return `nothing`. Date/DateTime durations are converted to seconds where scalar
rates or durations are reported. `MDSLayout` is the deterministic classical-MDS
layout; Kamada–Kawai is not implemented.

## What still differs from R

Each package's README has a "Not implemented" section, which is the full
list. A feature listed there either has no function or term to call, or is
refused with an explanatory `ArgumentError`; it is never fitted differently.
The main items:

- **Model syntax:** typed terms instead of an R formula, and keywords instead
  of `control.*()` lists.
- **ERGM.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl#not-implemented)):
  two-mode (bipartite) networks and terms, `constraints=`, and several term
  families (`nodeicov`/`nodeocov`, `ttriple`/`ctriple`, `esp`/`dsp`, `balance`,
  `cycle`, …); curved estimation only for `gwesp` and `gwdegree`; R's
  `drop=FALSE` fit of a boundary statistic (`drop=false` refuses it), and a
  curved model with one; R's `SPDyad` sampler only in `mcmle`; R's
  stratified proposals and adaptive burn-in.
  Missing ties are fitted by `mcmle(...; missing=:mle)` and the available-case
  MPLE, but simulation and `gof` cannot impute them.
- **ERGMCount.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl#not-implemented)):
  `ergm.count`'s own MCMC proposals and missing-data MLE; the `StdNormal` and
  continuous `Unif` references; the `nodecovar` family, the valued
  `nodemix`, `absdiff(pow≠1)` and `nodematch(keep=, levels=)`; curved terms,
  `constraints=`, offsets and two-mode networks.
- **ERGMEgo.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl#not-implemented)):
  richer survey designs, the curved `gwesp` and `mm`'s non-default forms,
  `simulate(fit)`, directed and two-mode ego data,
  and a likelihood (the estimator is method-of-moments).
- **ERGMMulti.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl#not-implemented)):
  models over several networks (`ergm.multi`'s `Networks()`), layer logic
  beyond same-dyad conjunction, and a geodesic-distance GOF panel; its MCMLE
  is not R's implementation.
- **ERGMRank.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl#not-implemented)):
  some `rank.nonconformity` variants, attribute-name term arguments,
  ESS-adaptive sampling, partial or tied rankings, offsets and
  `constraints=`; the MCMLE refuses a statistic at its bound (the swap-MPLE
  drops it).
- **ERGMUserterms.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl#not-implemented-vs-r-ergmuserterms)):
  the harness checks a term on the networks it is given and samples dyads
  above 5000; terms that read edge attributes live are refused under MCMC.
- **TERGM.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl#not-implemented)):
  EGMME; `tergm`'s ESS-adaptive CMLE sampling, missing-data CMLE and offsets;
  `constraints=`; masked dyads, two-mode panels, self-loops and panels of
  changing composition; the non-separable (btergm-style) memory terms in a
  formula. Dissolution coefficients describe persistence.
- **Siena.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/Siena.jl#not-implemented)):
  only the Method of Moments (no maximum likelihood, Bayesian or GMoM
  estimation, no `sienaGroupCreate` or `siena08`); no period dummies
  (`sienaTimeFix`); endowment and creation effects simulate but do not
  estimate; RSiena's other model types and continuous behaviour; missing tie
  values; composition change within a period; some RSiena effects.
  [Differences from RSiena](https://github.com/statistical-network-analysis-with-Julia/Siena.jl#differences-from-rsiena)
  lists the known numerical differences, among them starting values and the
  spread of the time-test one-step estimates.
- **SNA.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/SNA.jl#not-implemented)):
  network autocorrelation models (`lnam`, `nacf`) and `netcancor`;
  structural distances, `bbnam` and `consensus`; several indices and
  generators; some `betweenness`, `gtrans` and `component.dist` modes;
  weighted shortest paths; plotting.
- **REM.jl and Revel.jl** ([REM](https://github.com/statistical-network-analysis-with-Julia/REM.jl#not-implemented),
  [Revel](https://github.com/statistical-network-analysis-with-Julia/Revel.jl#not-implemented)):
  random effects; a dyad × event-type risk set; events with duration; the
  sender-rate step of actor-oriented models (DyNAM); Weibull or Gompertz
  baselines and integrated time-varying hazards; Bayesian estimation; Efron's
  tie correction with sampled controls; a bootstrap for sampled fits.
- **DynamicNetworks.jl, TSNA.jl and NDTV.jl**
  ([DynamicNetworks](https://github.com/statistical-network-analysis-with-Julia/DynamicNetworks.jl#not-implemented),
  [TSNA](https://github.com/statistical-network-analysis-with-Julia/TSNA.jl#not-implemented),
  [NDTV](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl#not-implemented)):
  time-varying network attributes, attribute aggregation in
  `network.collapse`, spell data-frame import and export, persistent IDs
  (`vertex.pid`), several observation spells; `tReach` sampling,
  latest-departure paths and `tErgmStats`; censoring-aware duration
  estimators; Kamada–Kawai, Graphviz and styled frames.
- **NetworkCore.jl** ([full list](https://github.com/statistical-network-analysis-with-Julia/NetworkCore.jl#not-implemented)):
  multiplex edges and hyperedges, and the missing-dyad mask in file I/O.

No implementation should be treated as complete R feature parity merely
because selected golden fixtures pass.

Where R semantics and an earlier version of these packages disagreed
(the `nodematch` `diff` keyword, directed GWESP's shared-partner
definition, doubled undirected degree, `sna`-style graph-level indices),
the packages now follow R; statistics that intentionally deviate carry
different names (e.g. the legacy either-direction directed GWESP is
`GWESP(0.5; type=:union)`, printed as `gwesp.union.fixed.0.5`, so it can
never be confused with statnet's `gwesp.fixed.0.5`).

These realignments are version-0.2 behavior changes. If you have code
written against the 0.1 development versions (rather than against R), start
from the [table of renamed packages and removed names](#renamed_packages_and_removed_names)
above, then read each package's `CHANGELOG.md`: its `[0.2.0] - Unreleased`
section is the current list of breaking changes, each with a one-line
migration hint (for example
[ERGM.jl's](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl/blob/main/CHANGELOG.md)).
The July [consolidated release notes](/post/2026-07-12-changelogs-0.2.0/)
describe the state at that date, and several of the names they mention have
since changed again.

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

deg = degreecent(flo)
fam = vertex_attribute_vector(flo, :name, String)
for v in sortperm(deg, rev=true)[1:3]
    println(fam[v], "  degree = ", Int(deg[v]))
end
```

Fit the ERGM. `GWESP` makes the model dyad-dependent, so the default
`method=:auto` fits it by MCMC maximum likelihood, as R's `ergm()` does:

```julia
result = ergm(flo, [Edges(), NodeCov(:wealth), GWESP(0.5)]; rng=Xoshiro(42))
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
