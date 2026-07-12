@def title = "Feature-surface completion, naming harmonization, and a polish sprint"
@def hascode = false
@def rss_description = "The P2 sprint lands: the remaining statnet/relevent/RSiena feature gaps closed, standardized fit_<model> entry points with a shared result presentation, numerical and performance fixes across the stack, and cleaner installs."
@def rss_title = "Feature-surface completion, naming harmonization, and a polish sprint"
@def rss_pubdate = Date(2026, 7, 12)

The polish sprint that followed the
[correctness pass](/post/2026-07-07-ecosystem-correctness-pass/) has
landed. Highlights:

- **The R feature surface is (nearly) complete.** ERGM.jl gains the
  degree-count terms (`Degree(0:2)`, `IDegree`, `ODegree`),
  `GWIDegree`/`GWODegree`, `GWDSP` with statnet's directed
  shared-partner types, and `NodeMix`; `NodeFactor` now expands into
  per-level statistics with the first level dropped, exactly like R's
  `nodefactor`. SNA.jl adds QAP inference (`qaptest`, `netlm`,
  `netlogit` with Dekker double-semi-partialing) and Freeman
  `centralization`. Relevent.jl adds the 13 Gibson participation shifts
  (`PShift(:AB_BA)`) and the `CovSnd`/`CovRec`/`CovInt` covariate
  blocks, plus a `t0` observation-onset keyword for left-truncated
  interval likelihoods. Siena.jl wires up conditional estimation
  (RSiena's `cond=TRUE`) and composition change
  (`sienaCompositionChange`).
- **One way to fit, one way to print.** Every model package now has a
  standardized `fit_<model>` entry point (`fit_ergm`, `fit_siena`,
  `fit_rem`, `fit_relevent`, `fit_stergm`, `fit_ergm_count`, ...) with
  the R-faithful names kept as aliases, and every fitted model prints
  through a shared presentation layer in Network.jl: the same R-style
  coefficient table (Estimate / Std.Error / z value / Pr(>|z|) with
  significance codes), p-values floored at `<1e-16` instead of a
  misleading `0.0`, one `gof` generic across the ecosystem, and
  `(1+k)/(N+1)` Monte-Carlo p-values that are never exactly zero.
  TSNA.jl and NDTV.jl switch to snake_case primary names
  (`t_sna_stats`, `earliest_arrival`, `transmission_timeline`) with the
  R camelCase spellings kept as aliases.
- **Two ERGM defaults changed** (both were silently wrong before, and
  both are flagged in the docs with "changed in 0.2" warnings):
  `NodeFactor(attr)` no longer produces a single all-levels statistic
  that was collinear with `Edges()` by construction, and directed
  `GWESP`/`GWDSP` default to statnet's OTP shared-partner definition —
  the old either-direction statistic survives as `type=:union` under a
  distinct coefficient name.
- **Performance.** The relational-event stack stores decayed counts as
  `(value, last_time)` pairs and decays lazily on read, so statistic
  evaluation no longer rescans event histories; SNA.jl's `triad_census`
  uses the edge-driven Batagelj–Mrvar algorithm (cost scales with edges,
  not `O(n³)`); TSNA.jl's earliest-arrival search is a heap-based
  Dijkstra over a memoized contact index; and ERGM.jl adds Geyer
  initial-sequence ESS and Geweke diagnostics to `mcmc_diagnostics`,
  with directed GOF split into in- and out-degree panels. A
  BenchmarkTools harness (`tools/run_benchmarks.jl` in the site repo, one
  `benchmark/` suite per package) locks the wins in with allocation
  regression tests.
- **Installs.** Every README now carries the ordered
  `Pkg.add(url=...)` block for its dependency chain, and the monorepo
  root gains a Julia 1.12 workspace `Project.toml` (`julia --project=.`
  after cloning the repositories side by side). A LocalRegistry is being
  prepared (`tools/setup_registry.jl`) so plain `Pkg.add("ERGM")` will
  eventually work.

The [migration guide](/migration/) and the [examples](/examples/) have
been updated to match, including the new coefficient-table output
everywhere a fit is printed.
