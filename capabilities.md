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
> repositories; and it reads missing-data support out of the `Networks.supports_missing`
> trait. A hand-maintained capability table drifts from the code within one release.
> This one cannot, because it *is* the code — and a CI check regenerates it and fails if
> the committed page has gone stale.

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
| SNA | `netlm`, dyadic OLS + QAP | `network_regression` | `least_squares` | **yes** | `none` | `none` | n/a |
| SNA | `netlogit`, dyadic logit + QAP | `network_logit_regression` | `likelihood` | **yes** | `fisher` | `none` | n/a |
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
- **`ERGMRank` is never exact, at any formula.** Its swap comparisons overlap by
  construction, so there is no dyad-independent special case to fall back on
  ([ERGMRank#1](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl/issues/1)).

Every one of the twelve fitted-result types in the ecosystem declares this protocol, so
you can ask the same question of your own fit:

```julia
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

#### SNA — `netlm`, dyadic OLS + QAP

- the dyads are treated as independent observations by the estimator; the dyadic dependence is addressed only by the null distribution the p-values are read off
- no standard errors are reported; the t-statistics use homoskedastic iid-dyad OLS standard errors and serve only as the test statistic compared against the null distribution
- nullhyp = :classical: the p-values are parametric t/z tests that assume independent dyads — for reference only, since dyadic dependence typically invalidates them. No permutation was performed
- the missing-dyad policy applied to the inputs is not recorded on the result: masked dyads are rejected by default (missing = :error), and with missing = :face they enter the design matrix at their stored face value

#### SNA — `netlogit`, dyadic logit + QAP

- the dyads are treated as independent observations by the estimator; the dyadic dependence is addressed only by the null distribution the p-values are read off
- the standard errors are the inverse Fisher information of a binomial GLM that treats the dyads as independent: they are expected anticonservative under dyadic dependence, and the reported p-values are not derived from them
- nullhyp = :classical: the p-values are parametric t/z tests that assume independent dyads — for reference only, since dyadic dependence typically invalidates them. No permutation was performed
- the missing-dyad policy applied to the inputs is not recorded on the result: masked dyads are rejected by default (missing = :error), and with missing = :face they enter the design matrix at their stored face value

#### ERGM — `mple`, **dyad-dependent** formula (`edges + gwesp`)

- maximum pseudo-likelihood of a dyad-dependent formula: the dyad conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dyadic dependence

#### ERGM — `mcmle`, dyad-dependent formula

- MCMLE: the likelihood is approximated by an MCMC sample, so the estimates carry Monte-Carlo error
- the reported log-likelihood (and AIC/BIC) is a path-sampling bridge estimate from a dyad-independent reference model

#### TERGM — `stergm`/CMPLE, **dyad-dependent** formula

- conditional maximum pseudo-likelihood of a dyad-dependent formula: the dyad conditionals of each transition are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive conditional pseudo-likelihood: expected anticonservative under dyadic dependence

#### ERGMCount — `fit_ergm_count`, **dyad-independent** (`sum + nonzero`)

- count support truncated at 0:10; max boundary mass 4.41e-5 (the reference measure is unbounded, so the enumerated support is an approximation to the model's)

#### ERGMCount — `fit_ergm_count`, **dyad-dependent** (`sum + mutual`)

- count support truncated at 0:10; max boundary mass 2.83e-9 (the reference measure is unbounded, so the enumerated support is an approximation to the model's)
- maximum pseudo-likelihood of a dyad-dependent model: the dyad conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dyadic dependence (refit with `se=:bootstrap` for a parametric-bootstrap covariance)

#### ERGMMulti — `ergm_multi`, **dyad-dependent** (interlayer dependence)

- maximum pseudo-likelihood of a dyad-dependent multilayer model: the (layer, i, j) conditionals are multiplied as if independent, so the point estimates are biased in finite samples
- inverse-Hessian standard errors of the naive pseudo-likelihood: expected anticonservative under dependence (refit with `se=:bootstrap` for a parametric-bootstrap covariance)

#### ERGMEgo — `fit_ergm_ego`, MCMC method of moments

- method-of-moments fit by MCMC: the targets are matched against simulated means, so the estimates carry Monte-Carlo error
- the model is simulated on a pseudo-population network of size 20, not the population of size 20; the edges coefficient is put on the population scale by the size adjustment -0.0
- the survey-design variance component is the weighted-mean variance of the target statistics under INDEPENDENT egos with the given case weights: it encodes no strata, clusters, finite-population correction, replicate weights, without-replacement inclusion probabilities, or alter dependence, so the standard errors are narrower than "survey-design variance" implies for any richer sampling design
- the Monte-Carlo variance of the pseudo-population construction itself is not included in the reported standard errors

#### ERGMRank — `fit_ergm_rank`, swap-MPLE, default SEs

- swap pseudo-likelihood: the (ego, alter-pair) swap conditionals are multiplied as if independent, but they overlap (each ranking enters n − 2 comparisons), so this is not the likelihood and no consistency result is claimed for the estimator
- inverse-Hessian standard errors of the naive swap pseudo-likelihood: they ignore the dependence between the overlapping comparisons and are expected anticonservative (too small). Treat them as a rough guide, not calibrated inference — or refit with `se=:bootstrap`

#### ERGMRank — `fit_ergm_rank`, swap-MPLE, `se=:bootstrap`

- swap pseudo-likelihood: the (ego, alter-pair) swap conditionals are multiplied as if independent, but they overlap (each ranking enters n − 2 comparisons), so this is not the likelihood and no consistency result is claimed for the estimator
- standard errors are a parametric bootstrap of the swap MPLE (simulate rank networks at θ̂ with the AlterSwap sampler, refit, empirical covariance): they do NOT treat the overlapping swap comparisons as independent, but they are Monte-Carlo estimates and assume the fitted model generated the data

#### REM — `fit_rem`, case-control conditional logit

- case-control sampling of the risk set (each non-case dyad entered its stratum with probability 0.1724): the partial likelihood is an approximation to the full-risk-set ordinal likelihood
- the inverse-Hessian standard errors are conditional on the ONE sampled control set that was drawn: they do not include the variance induced by the risk-set sampling itself, so they are understated (refit with `se=:bootstrap` to include it, or `se=:sandwich` for a misspecification-robust covariance)

#### Siena — `siena07`, SAOM by method of moments

- the fit did NOT meet the RSiena convergence standard (|t-ratio| < threshold for every parameter and tconv.max = 0.194 below its own): the estimates do not solve the moment equations
- Method of Moments by stochastic approximation: the moments are Monte-Carlo estimates from simulated trajectories, so the estimates carry Monte-Carlo error
- standard errors are D⁻¹ Σ D⁻ᵀ with BOTH factors estimated from the phase-3 simulations; the derivative matrix D is ridge-regularized (+0.01·I) before inversion, which biases the reported standard errors

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
| SNA | — | *no golden fixture* | | |
| ERGM | `flomarriage_ergm` | `ergm` 4.12.0 | 4.6.1 | ergm::flomarriage (Padgett): 16 Florentine families, 20 undirected marriage ties, wealth covariate |
| TERGM | `panel_stergm` | `btergm` 1.11.1, `ergm` 4.12.0, `tergm` 4.2.2 | 4.6.1 | simulated: 25 actors, 8 directed waves, alternating two-group `grp` attribute |
| ERGMCount | `zach_poisson` | `ergm_count` 4.1.3, `ergm` 4.12.0 | 4.6.1 | ergm.count::zach (Zachary 1977): 34 karate-club members, undirected, `contexts` edge counts 0-7 |
| ERGMEgo | `fauxmesa_ego_census` | `ergm_ego` 1.1.4, `ergm` 4.12.0 | 4.6.1 | ergm::faux.mesa.high: 205 students, 203 undirected friendship ties, Grade 7-12 |
| ERGMMulti | `twolayer_ergm_multi` | `ergm_multi` 0.3.0, `ergm` 4.12.0 | 4.6.1 | simulated: 2 directed layers on the same 20 actors, alternating two-group `grp` |
| ERGMRank | `newcomb_rank` | `ergm_rank` 4.1.2, `ergm` 4.12.0 | 4.6.1 | ergm.rank::newcomb[[1]] (Newcomb 1961): 17 fraternity men, week 1, each ranking the other 16 |
| REM | `rem_clogit` | `survival` 3.8.6 | 4.6.1 | simulated relational event sequence (10 actors, 80 events) |
| REM | `rem_ties` | `survival` 3.8.6 | 4.6.1 | simulated relational event sequence (8 actors, 90 events) observed on a coarse clock (resolution 0.03), which is what makes the ties |
| Relevent | `relevent_rem_dyad` | `relevent` 1.2.1 | 4.6.1 | simulated dyadic event sequence (8 actors, 100 events) |
| Siena | `s50_siena07` | `rsiena` 1.6.6 | 4.6.1 | RSiena::s50 (van Duijn): 50 actors, 3 friendship waves, smoke1 covariate |

Two entries in that table are **not** claims of agreement, and are called out in the
limitations below: `newcomb_rank` pins ERGMRank against a *different estimator*, and
`s50_siena07` pins Siena against RSiena on the estimand while documenting that the
procedure is materially weaker.

## Missing-data support

The ecosystem contract (`Networks.supports_missing` / `Networks.require_observed`): a
routine that has not declared a missing-data method **refuses** a network with masked
dyads rather than silently reading unobserved ties at face value. Both columns below are
read out of the code — the first from the `Networks.supports_missing` trait, which
defaults to `false` (so this is a census, not an advertisement), and the second from the
routine's own method table.

The second column is worth reading carefully, because it is narrower than the contract's
slogan. `missing = :face` is described as the auditable opt-in *everywhere*, but only
three of the thirteen fitting functions actually accept the keyword. For the rest,
refusing is all they can do: there is no way to ask them to proceed on face values, and
a masked network must be resolved before it reaches them ([Networks#1](https://github.com/statistical-network-analysis-with-Julia/Networks.jl/issues/1)).

| package | routine | handles masked dyads | face-value opt-in |
|:---|:---|:---|:---|
| ERGM | `mple` | **yes** — available-case objective; masked dyads excluded | *not needed — it handles the mask* |
| ERGM | `mcmle` | no — a masked network is **rejected** | `missing = :face` |
| SNA | `netlm` | no — a masked network is **rejected** | `missing = :face` |
| SNA | `netlogit` | no — a masked network is **rejected** | `missing = :face` |
| TERGM | `stergm` | no — a masked network is **rejected** | *none — it can only refuse* |
| ERGMCount | `fit_ergm_count` | no — a masked network is **rejected** | *none — it can only refuse* |
| ERGMEgo | `fit_ergm_ego` | no — a masked network is **rejected** | *none — it can only refuse* |
| ERGMMulti | `ergm_multi` | no — a masked network is **rejected** | *none — it can only refuse* |
| ERGMRank | `fit_ergm_rank` | no — a masked network is **rejected** | *none — it can only refuse* |
| REM | `fit_rem` | no — a masked network is **rejected** | *none — it can only refuse* |
| Relevent | `fit_obpm` | no — a masked network is **rejected** | *none — it can only refuse* |
| Relevent | `fit_timing` | no — a masked network is **rejected** | *none — it can only refuse* |
| Siena | `siena07` | no — a masked network is **rejected** | *none — it can only refuse* |

## Known limitations, and who owns them

Everything below is a real, reproduced finding. Each links to the issue that owns it.

### Siena.jl's SAOM procedure is materially weaker than RSiena's — [Siena#2](https://github.com/statistical-network-analysis-with-Julia/Siena.jl/issues/2)

**This is the most serious open finding in the ecosystem, and it can bite you
silently.** The *estimand* is right: on the `s50` fixture every parameter lands within
0.28 RSiena standard errors of RSiena's own estimate. The *procedure* is not:

- **~1 seed in 10 diverges outright while reporting `diverged == false`.** Two of 24
  surveyed seeds reached `tconv.max ≈ 50` (reciprocity 5.77 against a true ≈ 2.40).
  The parameter clamp never fires, so **`result.tconv_max` is the only signal you
  have** that a fit is garbage. Check it. Do not trust `diverged`.
- **3–19× noisier than RSiena at the same simulation budget** (smoke1-similarity:
  seed-to-seed sd 0.045, against RSiena's 0.0057).
- **It fails the convergence standard it enforces on itself**: `tconv.max` came out
  0.26–0.77 across five seeds, against the 0.25 threshold Siena.jl checks. RSiena gets
  0.13 on the same data.
- **More budget makes it worse, not better.** Raising `phase1_iterations` to 200 or 400
  each diverged one seed in six; `n_simulations = 5` inflates the sd about tenfold. The
  shipped defaults are the only stable operating point.

Until this is fixed: run several seeds, compare the estimates, and read `tconv_max` on
every one.

### Two RSiena comparisons cannot be made at all — [Siena#2](https://github.com/statistical-network-analysis-with-Julia/Siena.jl/issues/2)

`SienaResult` exposes neither the **derivative matrix** nor the **phase-3 statistic
covariance**, so two of the comparisons the parity issue asks for cannot be performed.
RSiena's values are frozen in the fixture as reference-only, unasserted; the check is
one accessor away.

### ERGMRank's swap-MPLE is a different estimator, not an approximation — [ERGMRank#1](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl/issues/1)

`ergm.rank` fits by MCMC-MLE; ERGMRank.jl fits a **swap pseudo-likelihood**. The swap
comparisons overlap (each ranking enters *n* − 2 of them), so their product is not the
likelihood, and **no consistency result is claimed**. Against R on the Newcomb fixture
it is systematically **16× R's seed noise** — though the gap is only about **0.3 of a
standard error**, so it is a difference of estimator, not a bug. The fixture pins the
*character* of the gap rather than asserting agreement.

### Pseudo-likelihood Hessian standard errors are anticonservative — [ERGMRank#1](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl/issues/1), [ERGMMulti#1](https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl/issues/1), [ERGMCount#2](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl/issues/2), [REM#2](https://github.com/statistical-network-analysis-with-Julia/REM.jl/issues/2)

Where the objective is a pseudo-likelihood and the model is dyad-dependent, the
inverse-Hessian standard errors treat overlapping conditionals as independent and come
out **too small**. Measured against `Networks.bootstrap_cov` on dependent models:

| package | bootstrap SE ÷ Hessian SE |
|:---|:---|
| ERGMRank | **5.4×** and 3.4× |
| ERGMMulti | up to 9.0× |
| ERGMCount | 1.20× |
| REM | 1.03–1.17× |

Pass **`se = :bootstrap`** (or `se = :sandwich` for REM) whenever the model is
dyad-dependent. Point estimates are byte-identical across the `se` options; only the
covariance changes.

### REM's uncertainty ignores the risk-set sampling — [REM#2](https://github.com/statistical-network-analysis-with-Julia/REM.jl/issues/2)

The default inverse-Hessian standard errors are conditional on the **one** sampled
control set that was drawn, so they omit the variance induced by the case-control
sampling itself. `se = :bootstrap` (law of total variance) or `se = :sandwich` includes
it. Relatedly, the actor universe must be **declared** ([REM#1](https://github.com/statistical-network-analysis-with-Julia/REM.jl/issues/1)): inferring
it from observed event endpoints drops eligible non-participants from the risk set and
changes the estimand.

### ERGMCount truncates an unbounded support — [ERGMCount#1](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl/issues/1)

Poisson/geometric references have unbounded support; the fit enumerates `0:max_val` and
reports the **boundary mass** it is leaning on (see the caveats above — it is
reported per fit, not assumed away). It is currently data-adaptive rather than
error-controlled.

### ERGMEgo's design variance encodes only a simple design — [ERGMEgo#1](https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl/issues/1)

The survey-design variance component is the weighted-mean variance of the target
statistics under **independent egos** with the given case weights. It encodes no
strata, clusters, finite-population correction, replicate weights, without-replacement
inclusion probabilities, or alter dependence. Since the design component is roughly
**17× the estimation component**, an ego standard error essentially *is* its design
variance — so a richer sampling design than the one assumed will give you standard
errors that are too narrow.

### TERGM has no EGMME, and `cmle` is not CMLE — [TERGM#1](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl/issues/1)

`TERGM.egmme` is unimplemented and deliberately **unexported**: it throws rather than
silently doing something else. `cmle` throws rather than quietly falling back to CMPLE.
For a dyad-dependent formula, the CMPLE rows above show `exact? = no`.

### Missing-dyad semantics across conversions — [Networks#1](https://github.com/statistical-network-analysis-with-Julia/Networks.jl/issues/1)

Conversions between `Network`, `DynamicNetwork` and the Siena/REM data structures are
now mask-preserving where they can be and **reject** where they cannot. In particular,
**Siena's structural mask is not a missing mask**: Siena records ties that are
*determined*, `Networks` records ties that are *unobserved*, and encoding one as the
other would tell the estimator that a tie is known to be impossible. There is no
faithful encoding, so the conversion refuses.

### The module is `Networks`, the type is `Network` — [Networks#2](https://github.com/statistical-network-analysis-with-Julia/Networks.jl/issues/2)

`using Networks`, then `Network(5)`. The module was renamed (the type name appears in
~200 downstream signatures); `using Network` is not a thing.

### What is not covered here

This page covers **fitted estimators**. Descriptive measures (`SNA.jl` centralities,
cohesion, equivalence), simulation-only entry points (`simulate_*`), and the
visualization packages (`NDTV.jl`, `TSNA.jl`) are not fits and have no result metadata
to report; their own issues are [NDTV#1](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl/issues/1), [TSNA#1](https://github.com/statistical-network-analysis-with-Julia/TSNA.jl/issues/1) and
[ERGMUserterms#1](https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl/issues/1). Regenerating this page is tracked by [site#2](https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io/issues/2);
release/registry sequencing by [site#3](https://github.com/statistical-network-analysis-with-Julia/statistical-network-analysis-with-Julia.github.io/issues/3).

