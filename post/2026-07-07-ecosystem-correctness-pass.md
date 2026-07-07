@def title = "Ecosystem-wide correctness pass and R validation"
@def hascode = false
@def rss_description = "All packages received a coordinated correctness pass, with estimators rebuilt where needed and results validated against the R reference implementations (ergm, sna, ergm.rank, RSiena)."
@def rss_title = "Ecosystem-wide correctness pass and R validation"
@def rss_pubdate = Date(2026, 7, 7)

A coordinated correctness pass has landed across every package in the
ecosystem. Highlights:

- **Validation against the R reference implementations.** ERGM.jl now
  reproduces R `ergm` 4.12 MPLE coefficients to six decimals on the
  Florentine and Sampson benchmarks; SNA.jl matches `sna` 2.8 on the full
  battery of graph-level indices and centralities (including the 16-class
  triad census); ERGMRank.jl matches `ergm.rank` 4.1.2 statistics exactly;
  and Siena.jl reproduces RSiena target statistics and `siena07` estimates
  on the classic `s50` data.
- **Estimation engines rebuilt** where reviews found gaps: count-data
  MPLE with the reference measure in the likelihood (ERGMCount.jl), the
  Krivitsky–Handcock formation/dissolution construction (TERGM.jl), the
  Krivitsky–Morris pseudo-population pipeline (ERGMEgo.jl), block-diagonal
  multilayer models with offsets (ERGMMulti.jl), full-risk-set ordinal and
  interval-timing estimators (Relevent.jl), and interval-semantics
  time-respecting paths (TSNA.jl).
- **Test suites** now cover estimator recovery on simulated ground truth
  in every modeling package, and golden-master values from the R packages
  are pinned in the tests.

The [Examples](/examples/) have been rewritten to be fully runnable, with
real data, printed output, and interpretation.
