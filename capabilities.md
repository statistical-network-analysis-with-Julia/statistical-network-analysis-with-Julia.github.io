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
> result-metadata protocol (`Networks.fit_metadata`); it reads the "validated against R"
> rows out of the `[provenance]` block of the golden fixtures committed in the package
> repositories; and it reads the `Networks.supports_missing` and
> `Networks.missing_policies` traits. The StatsAPI table executes the accessors on those
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
| ERGM | `mple`, **dyad-independent** formula (`edges`) | `ergm` | `pseudolikelihood` | **yes** | `hessian` | `none` | n/a |
| ERGM | `mple`, **dyad-dependent** formula (`edges + gwesp`) | `ergm` | `pseudolikelihood` | no | `hessian` | `none` | n/a |
| ERGM | `mcmle`, dyad-dependent formula | `ergm` | `mc_likelihood` | no | `fisher` | `none` | n/a |
| TERGM | `stergm`/CMPLE, **dyad-independent** formula | `stergm` | `conditional_pseudolikelihood` | **yes** | `hessian` | `rejected` | n/a |
| TERGM | `stergm`/CMPLE, **dyad-dependent** formula | `stergm` | `conditional_pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| ERGMCount | `fit_ergm_count`, **dyad-independent** (`sum + nonzero`) | `count_ergm` | `pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| ERGMCount | `fit_ergm_count`, **dyad-dependent** (`sum + mutual`) | `count_ergm` | `pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| ERGMMulti | `ergm_multi`, **dyad-independent** (per-layer edges) | `multilayer_ergm` | `pseudolikelihood` | **yes** | `hessian` | `rejected` | n/a |
| ERGMMulti | `ergm_multi`, **dyad-dependent** (interlayer dependence) | `multilayer_ergm` | `pseudolikelihood` | no | `hessian` | `rejected` | n/a |
| ERGMEgo | `fit_ergm_ego`, MCMC method of moments | `ergm_ego` | `moment` | no | `sandwich` | `none` | n/a |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, default SEs | `rank_ergm` | `pseudolikelihood` | no | `hessian` | `none` | n/a |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, `se=:bootstrap` | `rank_ergm` | `pseudolikelihood` | no | `bootstrap` | `none` | n/a |
| ERGMRank | `fit_ergm_rank`, MCMC-MLE | `rank_ergm` | `likelihood` | no | `fisher` | `none` | n/a |
| REM | `fit_rem`, case-control conditional logit | `relational_event` | `partial_likelihood` | no | `hessian` | `none` | `none` |
| Relevent | `fit_obpm`, ordinal B-P model | `relational_event` | `likelihood` | **yes** | `hessian` | `none` | `none` |
| Relevent | `fit_timing`, exact-time hazard model | `relational_event_timing` | `likelihood` | **yes** | `hessian` | `none` | `none` |
| Siena | `siena07`, SAOM by method of moments | `saom` | `moment` | no | `sandwich` | `rejected` | n/a |

Two rows are worth a second look, because they are exactly what a hand-written table
would have got wrong:

- **`ERGMCount`'s dyad-independent fit is still not exact.** Dyad independence is not
  enough here: the Poisson reference has unbounded support and the fit enumerates a
  truncated one, so it reports `exact? = no` and tells you the boundary mass it is
  leaning on ([ERGMCount#1](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl/issues/1)).
- **`ERGMRank` offers two estimators.** The default swap-MPLE multiplies overlapping
  comparisons and is not an exact likelihood. `method=:mcmle` fits the ranking ERGM
  by Monte Carlo likelihood; its simulation and convergence caveats remain relevant.

You can ask the same question of your own fit:

```julia
using Networks, ERGM
net = load_dataset(:florentine_marriage)
fit = ergm(net, [Edges(), GWESP(0.5)])
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

#### ERGM — `mple`, **dyad-dependent** formula (`edges + gwesp`)

- maximum pseudo-likelihood of a dyad-dependent formula: the dyad conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dyadic dependence

#### ERGM — `mcmle`, dyad-dependent formula

- MCMLE: the likelihood is approximated by an MCMC sample, so the estimates carry Monte-Carlo error (included in the standard errors; see mcmc_se)
- the reported log-likelihood (and AIC/BIC) is a path-sampling bridge estimate from a dyad-independent reference model

#### TERGM — `stergm`/CMPLE, **dyad-dependent** formula

- conditional maximum pseudo-likelihood of a dyad-dependent formula: the dyad conditionals of each transition are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive conditional pseudo-likelihood: expected anticonservative under dyadic dependence
- coefficient(s) Form~gwesp.OTP.fixed.0.5 fixed at -Inf (observed statistic at its smallest attainable value): no finite estimate exists; the other coefficients are estimated on the free dyads these statistics do not touch, as R ergm does (drop=TRUE), with standard error 0 and p-value 0 recorded for the fixed ones

#### ERGMCount — `fit_ergm_count`, **dyad-independent** (`sum + nonzero`)

- count support truncated at 0:20; max boundary mass 3.88e-13 (the reference measure is unbounded, so the enumerated support is an approximation to the model's)
- support chosen by error-controlled doubling: the last doubling to max_val = 20 moved the estimates by at most 0.000769 standard errors and left 0.000356 expected dyads past the previous bound (tolerance 0.001)

#### ERGMCount — `fit_ergm_count`, **dyad-dependent** (`sum + mutual`)

- count support truncated at 0:20; max boundary mass 3.13e-25 (the reference measure is unbounded, so the enumerated support is an approximation to the model's)
- support chosen by error-controlled doubling: the last doubling to max_val = 20 moved the estimates by at most 8.34e-10 standard errors and left 3.49e-10 expected dyads past the previous bound (tolerance 0.001)
- maximum pseudo-likelihood of a dyad-dependent model: the dyad conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dyadic dependence (refit with `se=:bootstrap` for a parametric-bootstrap covariance)

#### ERGMMulti — `ergm_multi`, **dyad-dependent** (interlayer dependence)

- maximum pseudo-likelihood of a dyad-dependent multilayer model: the (layer, i, j) conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dependence (refit with `se=:bootstrap` for a parametric-bootstrap covariance)

#### ERGMEgo — `fit_ergm_ego`, MCMC method of moments

- method-of-moments fit by MCMC: the targets are matched against simulated means, so the estimates carry Monte-Carlo error (final sample: 100 draws, effective sample size 5.0, max convergence t-ratio 0.0409, Hotelling p 0.932)
- the model is simulated on a pseudo-population network of size 20, not the population of size 20; the edges coefficient is put on the population scale by the size adjustment 0.0
- the survey-design variance component is the weighted-mean variance of the target statistics under INDEPENDENT egos with the given case weights: it encodes no strata, clusters, finite-population correction, replicate weights, without-replacement inclusion probabilities, or alter dependence, so the standard errors are narrower than "survey-design variance" implies for any richer sampling design
- the standard errors are the design sandwich I⁻¹ Σ_design I⁻¹ plus the Monte-Carlo estimation term I⁻¹/n_eff of the moment equations (ergm.ego's decomposition); the information I is itself the covariance of the statistics on a finite MCMC sample, so both components carry Monte-Carlo noise — increase n_samples or interval to reduce it

#### ERGMRank — `fit_ergm_rank`, swap-MPLE, default SEs

- swap pseudo-likelihood: the (ego, alter-pair) swap conditionals are multiplied as if independent, but they overlap (each ranking enters n − 2 comparisons), so this is not the likelihood and no consistency result is claimed for the estimator
- inverse-Hessian standard errors of the naive swap pseudo-likelihood: they ignore the dependence between the overlapping comparisons and are expected anticonservative (too small). Treat them as a rough guide, not calibrated inference — or refit with `se=:bootstrap`

#### ERGMRank — `fit_ergm_rank`, swap-MPLE, `se=:bootstrap`

- swap pseudo-likelihood: the (ego, alter-pair) swap conditionals are multiplied as if independent, but they overlap (each ranking enters n − 2 comparisons), so this is not the likelihood and no consistency result is claimed for the estimator
- standard errors are a parametric bootstrap of the swap MPLE (simulate rank networks at θ̂ with the AlterSwap sampler, refit, empirical covariance): they do NOT treat the overlapping swap comparisons as independent, but they are Monte-Carlo estimates and assume the fitted model generated the data

#### ERGMRank — `fit_ergm_rank`, MCMC-MLE

- MCMC MLE: the likelihood is approximated by an MCMC sample of the AlterSwap chain (n_samples draws per iteration), so the estimates carry Monte-Carlo error — included in the standard errors as the V·Σ_mc·V component (fit.vcov_fisher is the Fisher part alone; show prints R's MCMC %)
- the reported log-likelihood (and AIC/BIC) is a path-sampling bridge estimate along θ_u = u·θ̂ from the uniform ordering model (θ = 0, log Z = n·log((n−1)!)) with 16 rungs — a Monte-Carlo quantity with its own error

#### REM — `fit_rem`, case-control conditional logit

- case-control sampling of the risk set (each non-case dyad entered its stratum with probability 0.1724): the partial likelihood is an approximation to the full-risk-set ordinal likelihood, and if the model is misspecified the estimates depend on the control draw — refit with a larger `n_controls` or the full risk set, or measure the draw-to-draw spread with `control_draw_cov`
- the inverse-Hessian standard errors (`se=:hessian`) are the observed information of the sampled partial likelihood — a consistent variance estimator under nested case-control sampling (the information lost by sampling is already in it)

#### Siena — `siena07`, SAOM by method of moments

- Method of Moments by stochastic approximation: the moments are Monte-Carlo estimates from simulated trajectories, so the estimates carry Monte-Carlo error
- standard errors are D⁻¹ Σ D⁻ᵀ with BOTH factors estimated from the phase-3 simulations; unidentified derivative matrices produce undefined standard errors instead of an implicit ridge

#### Fits that declare no approximation at all

| package | fit | why there is nothing to declare |
|:---|:---|:---|
| ERGM | `mple`, **dyad-independent** formula (`edges`) | the objective **is** the exact likelihood of this model |
| TERGM | `stergm`/CMPLE, **dyad-independent** formula | the objective **is** the exact likelihood of this model |
| ERGMMulti | `ergm_multi`, **dyad-independent** (per-layer edges) | the objective **is** the exact likelihood of this model |
| Relevent | `fit_obpm`, ordinal B-P model | the objective **is** the exact likelihood of this model |
| Relevent | `fit_timing`, exact-time hazard model | the objective **is** the exact likelihood of this model |

## Validation against the reference implementations

A row exists here only if a golden fixture exists in the package repository: a frozen
set of numbers produced by the R implementation, together with the script that produced
them, the R and package versions, and the seed. **No fixture, no claim.** The dataset
column is the scale that has actually been validated — not a claim about the scale the
code will run at.

| package | fixture | reference implementation | R | validated on |
|:---|:---|:---|:---|:---|
| Networks | `florentine_sna` | `sna` 2.8 | 4.6.1 | network::flo (Padgett Florentine marriage) |
| Networks | `network_density` | `sna` 2.8 | 4.6.1 | hand-built 4- and 5-vertex networks (see script) |
| SNA | `sna_reference` | `ergm` 4.12.0, `sna` 2.8 | 4.6.1 | ergm florentine and sampson |
| ERGM | `ergm_terms` | `ergm` 4.12.0 | 4.6.1 |  |
| ERGM | `flomarriage_ergm` | `ergm` 4.12.0 | 4.6.1 | ergm::flomarriage (Padgett): 16 Florentine families, 20 undirected marriage ties, wealth covariate |
| ERGM | `flomarriage_missing_ergm` | `ergm` 4.12.0 | 4.6.1 | ergm::flomarriage (Padgett): 16 Florentine families, 20 undirected marriage ties, wealth covariate |
| TERGM | `panel_stergm` | `btergm` 1.11.1, `ergm` 4.12.0, `tergm` 4.2.2 | 4.6.1 | simulated: 25 actors, 8 directed waves, alternating two-group `grp` attribute |
| ERGMCount | `count_terms` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 |  |
| ERGMCount | `zach_poisson` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 | ergm.count::zach (Zachary 1977): 34 karate-club members, undirected, `contexts` edge counts 0-7 |
| ERGMEgo | `fauxmesa_ego_census` | `ergm_ego` 1.1.4, `ergm` 4.12.0 | 4.6.1 | ergm::faux.mesa.high: 205 students, 203 undirected friendship ties, Grade 7-12 |
| ERGMEgo | `fauxmesa_ego_weighted` | `ergm_ego` 1.1.4, `ergm` 4.12.0 | 4.6.1 | ergm::faux.mesa.high: 205 students, 203 undirected friendship ties, Grade 7-12 |
| ERGMMulti | `twolayer_ergm_multi` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 | simulated: 2 directed layers on the same 20 actors, alternating two-group `grp` |
| ERGMMulti | `twolayer_layer_terms` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 | the SAME two directed 20-actor layers as twolayer_ergm_multi.toml (identical generating code and seed), wrapped as ergm.multi Layer(list(A = net1, B = net2)) |
| ERGMRank | `newcomb_rank` | `ergm_rank` 4.1.2, `ergm` 4.12.0 | 4.6.1 | ergm.rank::newcomb[[1]] (Newcomb 1961): 17 fraternity men, week 1, each ranking the other 16 |
| ERGMRank | `rank_terms` | `ergm_rank` 4.1.2, `ergm` 4.12.0 | 4.6.1 | the 4-actor ERGMRank.jl test network (README/docstrings) and a seeded random 8-actor complete ranking |
| REM | `rem_clogit` | `survival` 3.8.6 | 4.6.1 | simulated relational event sequence (10 actors, 80 events) |
| REM | `rem_eventnet` | `survival` 3.8.6 | 4.6.1 | the rem_clogit.R sequence (10 actors, 80 events |
| REM | `rem_relevent_wtc` | `relevent` 1.2.1 | 4.6.1 | WTC police radio calls (Butts, Petrescu-Prahova & Cross 2007): Networks.jl/data/wtc_police_calls_{events,actors}.tsv, read by R and by Networks.load_dataset(:wtc_police_calls) |
| REM | `rem_ties` | `survival` 3.8.6 | 4.6.1 | simulated relational event sequence (8 actors, 90 events) observed on a coarse clock (resolution 0.03), which is what makes the ties |
| Relevent | `relevent_catalogue` | `relevent` 1.2.1 | 4.6.1 | 14 fixed directed events, 5 actors |
| Relevent | `relevent_rem_dyad` | `relevent` 1.2.1 | 4.6.1 | simulated dyadic event sequence (8 actors, 100 events) |
| Siena | `s50_siena07` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50 (van Duijn): 50 actors, 3 friendship waves, smoke1 covariate |
| Siena | `s50_targets.toml` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50: three friendship/alcohol waves, centered smoke1 |

Fixtures can compare different estimators or document residual differences. Read the
fixture's assertions and tolerances before treating a listed reference as equivalence.

## Shared result accessors

Each cell below comes from calling the accessor on the same fitted object used above.
`yes` means the call returned; `NaN` means a scalar criterion is explicitly unavailable;
`—` means the call is unsupported. For moment estimators and pseudo-likelihoods,
a returned AIC/BIC is not evidence that ordinary likelihood comparisons are justified.

| package | fit | `coef` | `stderror` | `vcov` | `confint` | `loglikelihood` | `nobs` | `dof` | `aic` | `bic` | `coeftable` |
|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| SNA | `netlm`, dyadic OLS, classical inference | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| SNA | `netlogit`, dyadic logit, classical inference | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGM | `mple`, **dyad-independent** formula (`edges`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGM | `mple`, **dyad-dependent** formula (`edges + gwesp`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGM | `mcmle`, dyad-dependent formula | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| TERGM | `stergm`/CMPLE, **dyad-independent** formula | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| TERGM | `stergm`/CMPLE, **dyad-dependent** formula | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMCount | `fit_ergm_count`, **dyad-independent** (`sum + nonzero`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMCount | `fit_ergm_count`, **dyad-dependent** (`sum + mutual`) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMMulti | `ergm_multi`, **dyad-independent** (per-layer edges) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMMulti | `ergm_multi`, **dyad-dependent** (interlayer dependence) | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMEgo | `fit_ergm_ego`, MCMC method of moments | yes | yes | yes | yes | — | yes | yes | — | — | yes |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, default SEs | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMRank | `fit_ergm_rank`, swap-MPLE, `se=:bootstrap` | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| ERGMRank | `fit_ergm_rank`, MCMC-MLE | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| REM | `fit_rem`, case-control conditional logit | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Relevent | `fit_obpm`, ordinal B-P model | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Relevent | `fit_timing`, exact-time hazard model | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| Siena | `siena07`, SAOM by method of moments | yes | yes | yes | yes | — | — | — | — | — | yes |

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
| Networks | `network_density` | `false` | `:error`, `:face` |
| SNA | `degree_centrality` | `false` | `:error`, `:face` |
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
| Relevent | `fit_obpm` | `false` | `:error` |
| Relevent | `fit_timing` | `false` | `:error` |
| Siena | `siena07` | `false` | `:error` |

## Scientific limitations

### Siena convergence and inference

`siena07` uses simulated method of moments. It rejects an unconverged fit by default;
`siena_algorithm(allow_unconverged=true)` explicitly returns a diagnostic fit with a
warning. Inspect `converged`, every t-ratio, `tconv_max`, `derivative_matrix`, and
`phase3_cov`; repeat independent seeds and assess goodness of fit before inference.
Convergence requires every absolute t-ratio below 0.1 and `tconv_max` below 0.25.
Newton refinement improves convergence, but a passing diagnostic does not establish
equivalence to RSiena across models, effects, or datasets. Maximum-likelihood and
Bayesian estimation remain unsupported; structural zeros/ones are not missing ties.

### Rank and other pseudo-likelihood estimators

ERGMRank's default swap-MPLE is a different objective from ranking MCMC-MLE. Use
`method=:mcmle` for the latter and inspect convergence and Monte Carlo diagnostics.
Dependent ERGM-family pseudo-likelihood Hessian errors can underestimate uncertainty.
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

### Relevent timing and effect coverage

Ordinal models condition on event order; timing models assume piecewise exponential
waiting times and require statistics constant between events. `fit_timing` rejects
finite-half-life decay statistics because their integrated hazard is not implemented;
these statistics remain available for ordinal/conditional fits. Cumulative-history
variants with `halflife=Inf` are interval-constant. For timing fits, `coef`,
`stderror`, `vcov` and `coeftable` include the
log-baseline first, followed by the effects. The legacy `.coefficients` and
`.std_errors` fields contain effects only. Choose tie handling explicitly where times
coincide. Time-varying covariate arrays and Bayesian fitting are unsupported.

Both fitters reject a verified separating direction: the likelihood keeps improving
toward an infinite coefficient, so no finite maximum-likelihood estimate exists.
This check does not detect every boundary case; inspect convergence and uncertainty.

### Count support and egocentric survey designs

Poisson/geometric count ERGMs enumerate a finite support. Adaptive doubling checks
coefficient movement in standard-error units, omitted tail mass and boundary mass;
this controls a numerical approximation and does not make infinite support exact.
Inspect the fitted support diagnostics. Egocentric inference assumes independent egos
with supplied case weights. Strata, clusters, replicate weights and richer inclusion
designs require additional survey-design variance treatment.

### Temporal models and observation

TERGM fits formation and persistence by CMPLE, exact for dyad-independent formulas.
`method=:cmle` and `TERGM.egmme` throw; dependent CMLE and EGMME are unavailable.
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

