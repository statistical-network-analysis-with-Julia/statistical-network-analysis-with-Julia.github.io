+++
title = "Capability and parity matrix"
+++

# Capability and parity matrix

~~~
<p class="lead">What every estimator in the ecosystem actually does — the objective it
maximises, whether that objective is exact for the model at hand, where its standard
errors come from, what it does with unobserved dyads and tied events, and whether any
of it has been checked against R.</p>
~~~

> **This page is generated, not written.** `tools/generate_capability_matrix.jl` fits a
> small model of every family and asks the fitted result what it did, through the shared
> result-metadata protocol (`NetworkCore.fit_metadata`); it reads the "validated against R"
> rows out of the `[provenance]` block of the golden fixtures committed in the package
> repositories; and it reads the `NetworkCore.supports_missing` and
> `NetworkCore.missing_policies` traits. The StatsAPI table executes the accessors on those
> same fits. CI rejects failed probes and checks the page for drift. These small probes
> establish the reported API behavior, not general scientific validity or scalability.

## How to read the columns

- **objective** — what was actually maximised, *not* what the model is named after:
  `likelihood`, `pseudolikelihood`, `conditional_pseudolikelihood`, `mc_likelihood`,
  `moment` (method of moments / Robbins–Monro), `partial_likelihood`, `least_squares`.
- **exact?** — whether that objective coincides with the exact likelihood **for this
  particular model**. This is deliberately a property of the *fit*, not of the
  estimator: maximum pseudo-likelihood of a dyad-independent formula **is** maximum
  likelihood; of a dyad-dependent one it is a different estimator with
  anticonservative standard errors. That contrast is the most important thing on this
  page, so the ERGM-family rows below come in pairs.
- **standard errors** — `hessian` (inverse observed information; for a
  pseudo-likelihood under dependence this is generally **anticonservative**, i.e. too
  small), `fisher`, `sandwich`, `bootstrap`, or `none`.
- **missing / ties** — how unobserved dyads and tied event times were treated by *this*
  fit. `rejected` means the routine refuses masked data rather than reading it at face
  value.

## Fitted-estimator status

| package | fit | estimand | objective | exact? | standard errors | missing dyads | tied events |
|:---|:---|:---|:---|:---:|:---|:---|:---|
| SNA | `netlm`, dyadic OLS, classical inference | `network_regression` | `least_squares` | **yes** | `ols` | `none` | n/a |
| SNA | `netlogit`, dyadic logit, classical inference | `network_logit_regression` | `likelihood` | **yes** | `fisher` | `none` | n/a |
| ERGM | `ergm`, default `method=:auto` (MPLE), **dyad-independent** formula (`edges`) | `ergm` | `pseudolikelihood` | **yes** | `hessian` | `none` | n/a |
| ERGM | `ergm(...; method=:mple)`, **dyad-dependent** formula (`edges + gwesp`) | `ergm` | `pseudolikelihood` | no | `hessian` | `none` | n/a |
| ERGM | `ergm`, default `method=:auto` (MCMLE), dyad-dependent formula | `ergm` | `mc_likelihood` | no | `fisher` | `none` | n/a |
| ERGM | `ergm`, default `method=:auto` (MCMLE), a statistic at its bound (`edges + triangle` on a matching): R's `drop=TRUE` | `ergm` | `mc_likelihood` | no | `fisher` | `none` | n/a |
| TERGM | `stergm`, default `method=:auto` (CMPLE), **dyad-independent** formula | `stergm` | `conditional_pseudolikelihood` | **yes** | `hessian` | `rejected` | n/a |
| TERGM | `stergm(...; method=:cmple)`, **dyad-dependent** formula (`edges + mutual`) | `stergm` | `conditional_pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| TERGM | `stergm(...; method=:cmle)` (the default here), dyad-dependent formula (`edges + mutual`) | `stergm` | `mc_likelihood` | no | `fisher` | `rejected` | n/a |
| ERGMCount | `fit_ergm_count`, default `method=:auto` (MPLE), **dyad-independent** (`sum + nonzero`) | `count_ergm` | `pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| ERGMCount | `fit_ergm_count(...; method=:mple)`, **dyad-dependent** (`sum + mutual`) | `count_ergm` | `pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| ERGMMulti | `ergm_multi`, default `method=:auto` (MPLE), **dyad-independent** (per-layer edges) | `multilayer_ergm` | `pseudolikelihood` | **yes** | `hessian` | `rejected` | n/a |
| ERGMMulti | `ergm_multi(...; method=:mple)`, **dyad-dependent** (interlayer dependence) | `multilayer_ergm` | `pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| ERGMEgo | `fit_ergm_ego`, MCMC method of moments | `ergm_ego` | `moment` | no | `sandwich` | `none` | n/a |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, default SEs | `rank_ergm` | `pseudolikelihood` | no | `hessian` | `none` | n/a |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, `se=:bootstrap` | `rank_ergm` | `pseudolikelihood` | no | `bootstrap` | `none` | n/a |
| ERGMRank | `fit_ergm_rank`, MCMC-MLE | `rank_ergm` | `likelihood` | no | `fisher` | `none` | n/a |
| REM | `fit_rem`, case-control conditional logit | `relational_event` | `partial_likelihood` | no | `hessian` | `none` | `none` |
| Revel | `fit_revel`, ordinal model, full risk set | `relational_event` | `likelihood` | **yes** | `hessian` | `none` | `none` |
| Revel | `fit_revel`, receiver choice (`riskset=:sender`) | `relational_event` | `partial_likelihood` | **yes** | `hessian` | `none` | `none` |
| Revel | `fit_revel`, `model=:timing`, exact-time hazard model | `relational_event_timing` | `likelihood` | **yes** | `hessian` | `none` | `none` |
| Revel | `fit_rhem`, hyperevents, sampled non-events | `relational_event` | `partial_likelihood` | no | `hessian` | `none` | `none` |
| Siena | `siena07`, SAOM by method of moments | `saom` | `moment` | no | `sandwich` | `rejected` | n/a |

Three rows are worth a second look, because they are exactly what a hand-written table
would have got wrong:

- **`ERGMCount`'s dyad-independent fit is still not exact.** Dyad independence is not
  enough here: the Poisson reference has unbounded support and the fit enumerates a
  truncated one, so it reports `exact? = no` and tells you the boundary mass it is
  leaning on.
- **`ERGMRank` offers two estimators.** The default, `method=:mcmle`, fits the ranking
  ERGM by Monte Carlo likelihood; its simulation and convergence caveats remain
  relevant. The swap-MPLE (`method=:mple`) multiplies overlapping comparisons and is
  not an exact likelihood.
- **`ERGM`'s boundary row.** On a network with no two-path, `triangle` sits at its
  smallest attainable value and has no finite estimate. As R's `ergm()` does under its
  default `drop=TRUE`, the fit fixes that coefficient at `-Inf`, holds the statistic at
  its bound while it samples and estimates the rest; `drop=false` refuses the model
  instead. ERGMCount, ERGMEgo and ERGMMulti do the same, and TERGM's CMPLE and
  ERGMRank's swap-MPLE drop too. ERGMRank's MCMLE and TERGM's CMLE refuse such a
  model. Because the dropped statistic is dyad-dependent, the fit reports no
  log-likelihood (`NaN` in the accessor table below).

You can ask the same question of your own fit:

```julia
using NetworkCore, ERGM
net = load_dataset(:florentine_marriage)
fit = ergm(net, [Edges(), GWESP(0.5)]; method=:mple)
md = fit_metadata(fit)
md.objective      # :pseudolikelihood
md.is_exact       # false — the formula is dyad-dependent
md.se_method      # :hessian, therefore anticonservative here
md.approximations # the caveats below, attached to the object
```

## The caveats the fits declare about themselves

These are not editorial. Each line is an entry of `approximations(fit)` on the
corresponding row above — attached to the fitted object, printed by its `show` method,
and reproduced here verbatim.

#### SNA — `netlm`, dyadic OLS, classical inference

- the dyads are treated as independent observations by the estimator; the dyadic dependence is addressed only by the null distribution the p-values are read off
- the standard errors are homoskedastic iid-dyad OLS standard errors and serve only as the test statistic compared against the null distribution
- nullhyp = :classical: the p-values are parametric t/z tests that assume independent dyads — for reference only, since dyadic dependence typically invalidates them. No permutation was performed

#### SNA — `netlogit`, dyadic logit, classical inference

- the dyads are treated as independent observations by the estimator; the dyadic dependence is addressed only by the null distribution the p-values are read off
- the standard errors are the inverse Fisher information of a binomial GLM that treats the dyads as independent: they are expected anticonservative under dyadic dependence, and the reported p-values are not derived from them
- nullhyp = :classical: the p-values are parametric t/z tests that assume independent dyads — for reference only, since dyadic dependence typically invalidates them. No permutation was performed

#### ERGM — `ergm(...; method=:mple)`, **dyad-dependent** formula (`edges + gwesp`)

- maximum pseudo-likelihood of a dyad-dependent formula: the dyad conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dyadic dependence
- z values, p-values and confidence intervals withheld: the naive pseudo-likelihood standard errors are not calibrated under dyadic dependence (refit with se=:bootstrap or method=:mcmle; se=:hessian opts in)

#### ERGM — `ergm`, default `method=:auto` (MCMLE), dyad-dependent formula

- MCMLE: the likelihood is approximated by an MCMC sample, so the estimates carry Monte-Carlo error (included in the standard errors; see mcmc_se)
- the reported log-likelihood (and AIC/BIC) is a path-sampling bridge estimate from a dyad-independent reference model

#### ERGM — `ergm`, default `method=:auto` (MCMLE), a statistic at its bound (`edges + triangle` on a matching): R's `drop=TRUE`

- MCMLE: the likelihood is approximated by an MCMC sample, so the estimates carry Monte-Carlo error (included in the standard errors; see mcmc_se)
- log-likelihood not estimated (a dyad-dependent statistic fixed at ±Inf at the boundary of its attainable range constrains the sample space, and such a constraint has no dyad-independent reference to bridge from): AIC/BIC are NaN
- coefficient(s) triangle fixed at -Inf (observed statistic at its smallest attainable value): no finite estimate exists; the other coefficients are estimated with these statistics held at their bound (the sampler never moves them off it), as R ergm does (drop=TRUE)

#### TERGM — `stergm(...; method=:cmple)`, **dyad-dependent** formula (`edges + mutual`)

- conditional maximum pseudo-likelihood of a dyad-dependent formula: the dyad conditionals of each transition are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive conditional pseudo-likelihood: expected anticonservative under dyadic dependence
- z values, p-values and confidence intervals withheld: the naive pseudo-likelihood standard errors are not calibrated under dyadic dependence (refit with se=:bootstrap or method=:cmle; se=:hessian opts in)

#### TERGM — `stergm(...; method=:cmle)` (the default here), dyad-dependent formula (`edges + mutual`)

- CMLE: the conditional likelihood is approximated by an MCMC sample, so the estimates carry Monte-Carlo error (included in the standard errors; see `fit.mcmc`)
- the reported log-likelihood (and AIC/BIC) is a path-sampling bridge estimate from a dyad-independent reference model

#### ERGMCount — `fit_ergm_count`, default `method=:auto` (MPLE), **dyad-independent** (`sum + nonzero`)

- count support truncated at 0:20; max boundary mass 3.88e-13 (the reference measure is unbounded, so the enumerated support is an approximation to the model's)
- support chosen by error-controlled doubling: the last doubling to max_val = 20 moved the estimates by at most 0.000769 standard errors and left 0.000356 expected dyads past the previous bound (tolerance 0.001)

#### ERGMCount — `fit_ergm_count(...; method=:mple)`, **dyad-dependent** (`sum + mutual`)

- count support truncated at 0:20; max boundary mass 3.13e-25 (the reference measure is unbounded, so the enumerated support is an approximation to the model's)
- support chosen by error-controlled doubling: the last doubling to max_val = 20 moved the estimates by at most 8.34e-10 standard errors and left 3.49e-10 expected dyads past the previous bound (tolerance 0.001)
- maximum pseudo-likelihood of a dyad-dependent model: the dyad conditionals are multiplied as if independent, so the point estimates are not the MLE that R's ergm.count (MCMLE) reports (on ergm.count's `zach` (sum + nonzero + transitiveweights) it sits 1.7-1.8 standard errors from the MLE); `method=:mcmle` gives the MLE
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dyadic dependence (refit with `se=:bootstrap` for a parametric-bootstrap covariance)
- z values, p-values and confidence intervals withheld: the naive pseudo-likelihood standard errors are not calibrated under dyadic dependence (refit with method=:mcmle or se=:bootstrap; se=:hessian opts in)

#### ERGMMulti — `ergm_multi(...; method=:mple)`, **dyad-dependent** (interlayer dependence)

- maximum pseudo-likelihood of a dyad-dependent multilayer model: the (layer, i, j) conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dependence (refit with `se=:bootstrap` for a parametric-bootstrap covariance)
- z values, p-values and confidence intervals withheld: the naive pseudo-likelihood standard errors are not calibrated under dyadic dependence (refit with method=:mcmle or se=:bootstrap; se=:hessian opts in)

#### ERGMEgo — `fit_ergm_ego`, MCMC method of moments

- method-of-moments fit by MCMC: the targets are matched against simulated means, so the estimates carry Monte-Carlo error (final sample: 400 draws, effective sample size 298.9, max convergence t-ratio 0.0598, Hotelling p 0.302)
- the model is simulated on a pseudo-population network of size 20, with ergm.ego's network-size offset netsize.adj = 0.0 on edges; the coefficients are those of a population of 20
- the design variance component treats the egos as independent draws with the given case weights (no strata, clusters, finite-population correction, replicate weights or without-replacement inclusion probabilities), multiplied by 1 + n_egos/popsize = 2.0 (se=:superpopulation) because a tie between two sampled egos is reported by both: exact for tie-sum statistics (edges, nodematch) under equal-probability sampling, approximate otherwise. In simulation nominal 95 % intervals for edges cover 92–95 % with 50 or more egos; an attribute term (nodematch) covers 85–95 %, and with about 20 egos they cover 87 % and 78 %, because the pseudo-population's attribute composition is itself estimated from the sample With 20 egos, prefer `se=:bootstrap` (it resamples the egos and refits, so it also carries the sampling error of the pseudo-population's attribute composition). `se=:design` gives ergm.ego's standard errors
- the standard errors are the design sandwich I⁻¹ Σ_design I⁻¹ plus the Monte-Carlo estimation term I⁻¹/n_eff of the moment equations (ergm.ego's decomposition); the information I is itself the covariance of the statistics on a finite MCMC sample, so both components carry Monte-Carlo noise — increase n_samples or interval to reduce it

#### ERGMRank — `fit_ergm_rank`, swap-MPLE, default SEs

- swap pseudo-likelihood: the (ego, alter-pair) swap conditionals are multiplied as if independent, but they overlap (each ranking enters n − 2 comparisons), so this is not the likelihood and no consistency result is claimed for the estimator
- inverse-Hessian standard errors of the naive swap pseudo-likelihood: they ignore the dependence between the overlapping comparisons and are expected anticonservative (too small). Treat them as a rough guide, not calibrated inference — or refit with `se=:bootstrap`
- z values, p-values and confidence intervals withheld: the inverse pseudo-Hessian standard errors of the swap pseudo-likelihood treat the overlapping swap comparisons as independent and are too small (2–3.9× narrower than the MLE's on Newcomb's fraternity ranks), so no test or interval is built on them — refit with method=:mcmle (the default) or se=:bootstrap; se=:hessian opts in to the naive Wald table

#### ERGMRank — `fit_ergm_rank`, swap-MPLE, `se=:bootstrap`

- swap pseudo-likelihood: the (ego, alter-pair) swap conditionals are multiplied as if independent, but they overlap (each ranking enters n − 2 comparisons), so this is not the likelihood and no consistency result is claimed for the estimator
- standard errors are a parametric bootstrap of the swap MPLE (simulate rank networks at θ̂ with the AlterSwap sampler, refit, empirical covariance): they do NOT treat the overlapping swap comparisons as independent, but they are Monte-Carlo estimates and assume the fitted model generated the data

#### ERGMRank — `fit_ergm_rank`, MCMC-MLE

- MCMC MLE: the likelihood is approximated by an MCMC sample of the AlterSwap chain (1000 draws in the final sample; stopped by the confidence rule, p = 1.74e-22 against 0.01 (precision 0.1, 1000 draws)), so the estimates carry Monte-Carlo error — included in the standard errors as the V·Σ_mc·V component (fit.vcov_fisher is the Fisher part alone; show prints R's MCMC %)
- the reported log-likelihood (and AIC/BIC) is a path-sampling bridge estimate along θ_u = u·θ̂ from the uniform ordering model (θ = 0, log Z = n·log((n−1)!)) with 16 rungs — a Monte-Carlo quantity with its own error

#### REM — `fit_rem`, case-control conditional logit

- case-control sampling of the risk set (each non-case dyad entered its stratum with probability 0.1724): the partial likelihood is an approximation to the full-risk-set ordinal likelihood, and if the model is misspecified the estimates depend on the control draw — refit with a larger `n_controls` or the full risk set, or measure the draw-to-draw spread with `control_draw_cov`
- the inverse-Hessian standard errors (`se=:hessian`) are the observed information of the sampled partial likelihood — a consistent variance estimator under nested case-control sampling (the information lost by sampling is already in it)

#### Revel — `fit_rhem`, hyperevents, sampled non-events

- case-control sampling of hyperedges: each stratum holds the observed hyperedge and up to 5 others of the same size drawn uniformly, so the partial likelihood approximates the one over every hyperedge of that size; if the model is misspecified the estimates depend on the draw — refit with a larger `n_controls`, or with another `rng`, and compare
- the inverse-Hessian standard errors (`se=:hessian`) are the observed information of the sampled partial likelihood — a consistent variance estimator under nested case-control sampling (the information lost by sampling is already in it)

#### Siena — `siena07`, SAOM by method of moments

- Method of Moments by stochastic approximation: the moments are Monte-Carlo estimates from simulated trajectories, so the estimates carry Monte-Carlo error
- standard errors are D⁻¹ Σ D⁻ᵀ with BOTH factors estimated from the phase-3 simulations; unidentified derivative matrices produce undefined standard errors instead of an implicit ridge

#### Fits that declare no approximation at all

| package | fit | why there is nothing to declare |
|:---|:---|:---|
| ERGM | `ergm`, default `method=:auto` (MPLE), **dyad-independent** formula (`edges`) | the objective **is** the exact likelihood of this model |
| TERGM | `stergm`, default `method=:auto` (CMPLE), **dyad-independent** formula | the objective **is** the exact likelihood of this model |
| ERGMMulti | `ergm_multi`, default `method=:auto` (MPLE), **dyad-independent** (per-layer edges) | the objective **is** the exact likelihood of this model |
| Revel | `fit_revel`, ordinal model, full risk set | the objective **is** the exact likelihood of this model |
| Revel | `fit_revel`, receiver choice (`riskset=:sender`) | the objective **is** the exact likelihood of this model |
| Revel | `fit_revel`, `model=:timing`, exact-time hazard model | the objective **is** the exact likelihood of this model |

## Validation against the reference implementations

A row exists here only if a golden fixture exists in the package repository: a frozen
set of numbers produced by the R implementation, together with the script that produced
them, the R and package versions, and the seed. **No fixture, no claim.** The dataset
column is the scale that has actually been validated — not a claim about the scale the
code will run at.

| package | fixture | reference implementation | R | validated on |
|:---|:---|:---|:---|:---|
| NetworkCore | `florentine_sna` | `sna` 2.8 | 4.6.1 | network::flo (Padgett Florentine marriage) |
| NetworkCore | `network_density` | `sna` 2.8 | 4.6.1 | hand-built 4- and 5-vertex networks (see script) |
| SNA | `sna_fuzz` | `igraph` 2.3.3, `sna` 2.8 | 4.6.1 | 60 seeded random networks (n = 3-10, directed and undirected, self-loops), structural-equivalence and Bonacich edge cases, a two-mode regression |
| SNA | `sna_inference` | `sna` 2.8 | 4.6.1 | 24 seeded random networks with random classes (brokerage, equiv.clust, blockmodel) |
| SNA | `sna_reference` | `ergm` 4.12.0, `sna` 2.8 | 4.6.1 | ergm florentine and sampson |
| ERGM | `boundary_ergm` | `ergm` 4.12.0 | 4.6.1 |  |
| ERGM | `curved_ergm` | `ergm` 4.12.0 | 4.6.1 |  |
| ERGM | `ergm_terms` | `ergm` 4.12.0 | 4.6.1 |  |
| ERGM | `flomarriage_ergm` | `ergm` 4.12.0 | 4.6.1 | ergm::flomarriage (Padgett): 16 Florentine families, 20 undirected marriage ties, wealth covariate |
| ERGM | `flomarriage_missing_ergm` | `ergm` 4.12.0 | 4.6.1 | ergm::flomarriage (Padgett): 16 Florentine families, 20 undirected marriage ties, wealth covariate |
| ERGM | `mcmle_ergm` | `ergm` 4.12.0 | 4.6.1 | ergm::faux.mesa.high (205 students, 203 undirected ties, Grade/Race/Sex) and ergm::flomarriage |
| ERGM | `offset_ergm` | `ergm` 4.12.0 | 4.6.1 |  |
| TERGM | `cmle_stergm` | `ergm` 4.12.0, `tergm` 4.2.2 | 4.6.1 | (a) main: the 25-actor, 8-wave directed panel of panel_stergm.toml, regenerated from the same seed (edge counts asserted) |
| TERGM | `panel_stergm` | `btergm` 1.11.1, `ergm` 4.12.0, `tergm` 4.2.2 | 4.6.1 | simulated: 25 actors, 8 directed waves, alternating two-group `grp` attribute |
| TERGM | `simulate_stergm` | `ergm` 4.12.0, `tergm` 4.2.2 | 4.6.1 | simulated: one 20-actor directed starting network, Bernoulli(0.12), frozen below as an edge list |
| ERGMCount | `count_covariates` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 |  |
| ERGMCount | `count_geometric_drop` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 |  |
| ERGMCount | `count_mcmle` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 |  |
| ERGMCount | `count_terms` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 |  |
| ERGMCount | `zach_poisson` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 | ergm.count::zach (Zachary 1977): 34 karate-club members, undirected, `contexts` edge counts 0-7 |
| ERGMEgo | `ego_netsize` | `ergm_ego` 1.1.4, `ergm` 4.12.0 | 4.6.1 | a frozen 100-vertex Bernoulli(0.04) network (edge list below) and ergm::faux.mesa.high |
| ERGMEgo | `ego_terms` | `ergm_ego` 1.1.4, `ergm` 4.12.0 | 4.6.1 | ergm::faux.mesa.high: 205 students, 203 undirected friendship ties |
| ERGMEgo | `fauxmesa_ego_census` | `ergm_ego` 1.1.4, `ergm` 4.12.0 | 4.6.1 | ergm::faux.mesa.high: 205 students, 203 undirected friendship ties, Grade 7-12 |
| ERGMEgo | `fauxmesa_ego_weighted` | `ergm_ego` 1.1.4, `ergm` 4.12.0 | 4.6.1 | ergm::faux.mesa.high: 205 students, 203 undirected friendship ties, Grade 7-12 |
| ERGMMulti | `boundary_multi` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 |  |
| ERGMMulti | `multilayer_labels` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 | deterministic: three directed 8-actor layers friend/advice/cowork and two undirected 8-actor layers a/b, ties arithmetic in the vertex indices |
| ERGMMulti | `multilayer_mcmle` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 |  |
| ERGMMulti | `pooled_layer_terms` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 | the SAME directed 20-actor and undirected 12-actor layer pairs as twolayer_layer_terms.toml (identical generating code and seed), plus the deterministic vertex attributes g3 = rep(a,b,c) and x = round(sin(1:n), 3) on both layers |
| ERGMMulti | `twolayer_ergm_multi` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 | simulated: 2 directed layers on the same 20 actors, alternating two-group `grp` |
| ERGMMulti | `twolayer_layer_terms` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 | the SAME two directed 20-actor layers as twolayer_ergm_multi.toml (identical generating code and seed), wrapped as ergm.multi Layer(list(A = net1, B = net2)) |
| ERGMRank | `newcomb2_rank` | `ergm_rank` 4.1.2, `ergm` 4.12.0 | 4.6.1 | ergm.rank::newcomb[[2]] (Newcomb 1961): 17 fraternity men, week 2, each ranking the other 16, with week 1 (newcomb[[1]]) as the reference ranking |
| ERGMRank | `newcomb_rank` | `ergm_rank` 4.1.2, `ergm` 4.12.0 | 4.6.1 | ergm.rank::newcomb[[1]] (Newcomb 1961): 17 fraternity men, week 1, each ranking the other 16 |
| ERGMRank | `rank_inconsistency_weights` | `ergm_rank` 4.1.2, `ergm` 4.12.0 | 4.6.1 | the 4-actor ERGMRank.jl test network and the seeded 8-actor ranking of rank_terms.R, with their reference rankings |
| ERGMRank | `rank_terms` | `ergm_rank` 4.1.2, `ergm` 4.12.0 | 4.6.1 | the 4-actor ERGMRank.jl test network (README/docstrings) and a seeded random 8-actor complete ranking |
| REM | `rem_clogit` | `survival` 3.8.6 | 4.6.1 | simulated relational event sequence (10 actors, 80 events) |
| REM | `rem_eventnet` | `survival` 3.8.6 | 4.6.1 | the rem_clogit.R sequence (10 actors, 80 events |
| REM | `rem_relevent_wtc` | `relevent` 1.2.1 | 4.6.1 | WTC police radio calls (Butts, Petrescu-Prahova & Cross 2007): NetworkCore.jl/data/wtc_police_calls_{events,actors}.tsv, read by R and by NetworkCore.load_dataset(:wtc_police_calls) |
| REM | `rem_ties` | `survival` 3.8.6 | 4.6.1 | simulated relational event sequence (8 actors, 90 events) observed on a coarse clock (resolution 0.03), which is what makes the ties |
| Revel | `relevent_catalogue` | `relevent` 1.2.1 | 4.6.1 | 14 fixed directed events, 5 actors |
| Revel | `relevent_rem_dyad` | `relevent` 1.2.1 | 4.6.1 | simulated dyadic event sequence (8 actors, 100 events) |
| Revel | `revel_remstats` | `remify` 4.1.0, `remstats` 4.1.0 | 4.6.1 | 36 fixed directed events on a 0.25 time grid, 6 actors |
| Siena | `s50_allowonly_cond` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50 friendship |
| Siena | `s50_coevolution` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50: friendship (3 waves) and alcohol use (dependent behaviour) |
| Siena | `s50_defaults.toml` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50 friendship (ties > 1 set to 0), alcohol, smoke1 |
| Siena | `s50_dynamics` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50 (friendship, alcohol, smoke1), symmetrised s50, deterministic two-mode panel and dyadic covariates |
| Siena | `s50_siena07` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50 (van Duijn): 50 actors, 3 friendship waves, smoke1 covariate |
| Siena | `s50_siena07_cond` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50: 50 actors, 3 friendship waves, smoke1 |
| Siena | `s50_siena07_interaction` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50: 50 actors, 3 friendship waves, smoke1 |
| Siena | `s50_siena07_undirected` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50 friendship, symmetrised |
| Siena | `s50_targets.toml` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50: friendship waves (directed, and symmetrised), alcohol, centred smoke1 |
| Siena | `s50_time_test` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50: 50 actors, 3 friendship waves, smoke1 |

Fixtures can compare different estimators or document residual differences. Read the
fixture's assertions and tolerances before treating a listed reference as equivalence.

## Shared result accessors

Each cell below comes from calling the accessor on the same fitted object used above.
`yes` means the call returned; `NaN` means a scalar criterion is explicitly unavailable;
`—` means the call is unsupported. `coefnames` returns R's coefficient labels, the same
as the rows of `coeftable`. For moment estimators and pseudo-likelihoods,
a returned AIC/BIC is not evidence that ordinary likelihood comparisons are justified.

| package | fit | `coef` | `coefnames` | `stderror` | `vcov` | `confint` | `loglikelihood` | `nobs` | `dof` | `aic` | `bic` | `coeftable` |
|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| SNA | `netlm`, dyadic OLS, classical inference | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| SNA | `netlogit`, dyadic logit, classical inference | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGM | `ergm`, default `method=:auto` (MPLE), **dyad-independent** formula (`edges`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGM | `ergm(...; method=:mple)`, **dyad-dependent** formula (`edges + gwesp`) | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes |
| ERGM | `ergm`, default `method=:auto` (MCMLE), dyad-dependent formula | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGM | `ergm`, default `method=:auto` (MCMLE), a statistic at its bound (`edges + triangle` on a matching): R's `drop=TRUE` | yes | yes | yes | yes | yes | NaN | yes | yes | NaN | NaN | yes |
| TERGM | `stergm`, default `method=:auto` (CMPLE), **dyad-independent** formula | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| TERGM | `stergm(...; method=:cmple)`, **dyad-dependent** formula (`edges + mutual`) | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes |
| TERGM | `stergm(...; method=:cmle)` (the default here), dyad-dependent formula (`edges + mutual`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMCount | `fit_ergm_count`, default `method=:auto` (MPLE), **dyad-independent** (`sum + nonzero`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMCount | `fit_ergm_count(...; method=:mple)`, **dyad-dependent** (`sum + mutual`) | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes |
| ERGMMulti | `ergm_multi`, default `method=:auto` (MPLE), **dyad-independent** (per-layer edges) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMMulti | `ergm_multi(...; method=:mple)`, **dyad-dependent** (interlayer dependence) | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes |
| ERGMEgo | `fit_ergm_ego`, MCMC method of moments | yes | yes | yes | yes | yes | — | yes | yes | — | — | yes |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, default SEs | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, `se=:bootstrap` | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMRank | `fit_ergm_rank`, MCMC-MLE | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| REM | `fit_rem`, case-control conditional logit | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Revel | `fit_revel`, ordinal model, full risk set | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Revel | `fit_revel`, receiver choice (`riskset=:sender`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Revel | `fit_revel`, `model=:timing`, exact-time hazard model | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Revel | `fit_rhem`, hyperevents, sampled non-events | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Siena | `siena07`, SAOM by method of moments | yes | yes | yes | yes | yes | — | — | — | — | — | yes |

## Missing-data support

A masked dyad is unobserved, not absent. The first column reports the
`supports_missing` declaration verbatim; the second reports `missing_policies(f)`.
A true trait alone does not say whether a routine excludes, conditions on, or refuses
a mask: read the accepted policies and the routine documentation. `:error` alone
promises rejection and may mean there is no `missing=` keyword. `:face` uses stored
values; `:condition_on_face` fixes them during MCMC. Neither is missing-data MLE.
ERGM's `:mle` instead integrates missing ties with free and constrained chains;
inspect convergence and Monte Carlo diagnostics for that fit.

| package | routine | `supports_missing` | accepted `missing` policies |
|:---|:---|:---:|:---|
| NetworkCore | `network_density` | `false` | `:error`, `:face` |
| SNA | `degreecent` | `false` | `:error`, `:face` |
| TSNA | `t_density` | `false` | `:error`, `:face` |
| TSNA | `t_reciprocity` | `false` | `:error`, `:face` |
| ERGM | `mple` | `true` | `:error` |
| ERGM | `mcmle` | `true` | `:error`, `:condition_on_face`, `:mle` |
| SNA | `netlm` | `false` | `:error`, `:face` |
| SNA | `netlogit` | `false` | `:error`, `:face` |
| TERGM | `stergm` | `false` | `:error` |
| ERGMCount | `fit_ergm_count` | `false` | `:error` |
| ERGMEgo | `fit_ergm_ego` | `false` | `:error` |
| ERGMMulti | `ergm_multi` | `false` | `:error` |
| ERGMRank | `fit_ergm_rank` | `false` | `:error` |
| REM | `fit_rem` | `false` | `:error` |
| Revel | `fit_revel` | `false` | `:error` |
| Revel | `fit_rhem` | `false` | `:error` |
| Siena | `siena07` | `false` | `:error` |

## Scientific limitations

### Siena convergence and inference

`siena07` uses simulated method of moments, conditional on the observed amount of
change when one dependent variable is simulated, as RSiena's default. An unconverged
fit is returned with a warning and `converged == false`, as RSiena returns it;
`siena_algorithm(allow_unconverged=false)` raises `SienaConvergenceError` instead.
`get_effects` includes RSiena's default effects. Inspect `converged`, every t-ratio,
`tconv_max`, `derivative_matrix`, and
`phase3_cov`; repeat independent seeds and assess goodness of fit before inference.
Convergence requires every absolute t-ratio below 0.1 and `tconv_max` below 0.25.
Newton refinement improves convergence, but a passing diagnostic does not establish
equivalence to RSiena across models, effects, or datasets. Maximum-likelihood and
Bayesian estimation remain unsupported; structural zeros/ones are not missing ties.

### Rank and other pseudo-likelihood estimators

ERGMRank's swap-MPLE (`method=:mple`) is a different objective from the ranking
MCMC-MLE, its default; inspect convergence and Monte Carlo diagnostics for the latter.
Dependent ERGM-family pseudo-likelihood Hessian errors can underestimate uncertainty,
so a dyad-dependent MPLE or CMPLE reports no z values or p-values by default.
Where offered, `se=:bootstrap` changes the covariance, not the objective or consistency
properties. Check each routine's documentation; this option is not universal.

### REM risk sets and uncertainty

Declare the complete eligible actor universe, including nonparticipants. Omitting
eligible actors changes the risk set and the estimand. Under a correctly specified
nested case-control model, the sampled likelihood's Hessian already accounts for the
information lost by sampling controls. `se=:sandwich` uses event-clustered scores for
robustness to within-stratum misspecification; it does not establish robustness to
arbitrary dependence between events. REM rejects `se=:bootstrap`. `control_draw_cov`
measures sensitivity to control redraws and must not be added to the fitted covariance
as a supposed missing variance component.

### Revel timing, effects and diagnostics

Ordinal models condition on event order; the timing model assumes piecewise
exponential waiting times and requires statistics constant between events. It
therefore refuses decaying memory kernels on the time clock, elapsed-time effects,
global and time-varying covariates, which remain available for ordinal fits, and it
needs the full directed risk set. For timing fits, `coef`, `stderror`, `vcov` and
`coeftable` include the log-baseline first, followed by the effects. Choose tie
handling explicitly where times coincide.

The same configuration has a different default measurement in each R package, so an
effect name alone does not fix a number: `effect_catalogue()` gives the call that
reproduces relevent, remstats, rem, goldfish and eventnet. Only the remstats and
relevent columns are checked numerically, and three relevent names (`FrPSndSnd`,
`FrRecSnd`, `OSPSnd`) follow relevent's documentation, from which relevent 1.2.1's
output departs. Under decaying memory Revel evaluates the decay at the event being
explained, where remstats 4.1.0 uses the previous event.

Product terms, filtered statistics, type splits and separate fits are different
models of moderation, not interchangeable ones. Random effects, smooth non-linear
effects, a dyad-by-type risk set, events with duration and the sender-rate step of
actor-oriented models are unavailable; unobserved actor heterogeneity can therefore
inflate closure and popularity effects. Score-process and score tests apply to
converged ordinal fits whose risk sets were enumerated, not to timing fits or fits
with sampled controls; a score-process rejection says the specification drifts, not
which effect does. Simulation-based `gof` is a plug-in check with conservative,
pointwise p-values and one joint Mahalanobis test. Hyperevent fits sample non-events
of the observed size, so their estimates vary with the control draw, and have no
goodness-of-fit routine.

### Count support and egocentric survey designs

Poisson/geometric count ERGMs enumerate a finite support. Adaptive doubling checks
coefficient movement in standard-error units, omitted tail mass and boundary mass;
this controls a numerical approximation and does not make infinite support exact.
Inspect the fitted support diagnostics. Egocentric inference assumes independent egos
with supplied case weights. Strata, clusters, replicate weights and richer inclusion
designs require additional survey-design variance treatment.

### Temporal models and observation

TERGM fits formation and persistence by the conditional MLE: by MCMC (`method=:cmle`)
when a formula is dyad-dependent, and exactly by its CMPLE otherwise. The CMPLE of a
dyad-dependent formula (`method=:cmple`) is a pseudo-likelihood; `se=:bootstrap` is
its parametric bootstrap and `se=:block_bootstrap` resamples transitions (btergm's
scheme, refused below 10 transitions). EGMME is unavailable (`method=:egmme` throws).
TSNA uses active-vertex density and dyadic reciprocity by default. Its temporal
analyses reject masks unless `missing=:face` is explicit; face values cannot recover
unobserved histories. Conversions preserve representable masks and reject incompatible
encodings: Siena structural masks describe determined ties, not unobserved ties.

### Scope and installation

These tables cover small fitted models and selected missing-data policies. They do
not validate every descriptive measure, simulation, visualization, or scale. The
[migration guide](/migration/) describes current API differences. The published
[workspace recipe](https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io/tree/main/tools/workspace)
reconstructs sibling checkouts. A passing local snapshot installation check does not
establish registry publication or the availability of unpushed changes.

