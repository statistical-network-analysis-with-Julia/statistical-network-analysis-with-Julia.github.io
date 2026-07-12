@def title = "0.2.0 across the ecosystem: consolidated release notes"
@def hascode = false
@def rss_description = "Every package now ships a Keep-a-Changelog CHANGELOG.md with its 0.2.0 (unreleased) section. One page collecting the links, the ecosystem-wide changes, and every breaking change with its migration hint."
@def rss_title = "0.2.0 across the ecosystem: consolidated release notes"
@def rss_pubdate = Date(2026, 7, 12)

The three review-driven sprints — the
[correctness pass](/post/2026-07-07-ecosystem-correctness-pass/) and the
[polish sprint](/post/2026-07-12-p2-polish-sprint/) — are now documented
release-note-style: **every package repository carries a
[Keep a Changelog](https://keepachangelog.com/)-format `CHANGELOG.md`**
whose `[0.2.0] - Unreleased` section covers everything since the 0.1.0
baseline, with every breaking change carrying a one-line migration hint.

## The per-package changelogs

| Package | 0.2.0 in one line |
|:---|:---|
| [Network.jl](https://github.com/statistical-network-analysis-with-Julia/Network.jl/blob/main/CHANGELOG.md) | Compile-time directedness (`Network{T,D}`), attribute-preserving `copy`, missing-dyad masks, bundled datasets, shared result presentation |
| [SNA.jl](https://github.com/statistical-network-analysis-with-Julia/SNA.jl/blob/main/CHANGELOG.md) | cliques/clustering/degree bugs fixed, Graphs.jl generics extended (not shadowed), QAP inference and `centralization`, R-`sna` semantics |
| [ERGM.jl](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl/blob/main/CHANGELOG.md) | Attribute-preserving copies (the critical fix), statnet-grade MCMLE, directed `GWESP` → `:OTP`, `NodeMatch(diff=true)` → per-level homophily, new terms, O(deg) change stats |
| [ERGMCount.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl/blob/main/CHANGELOG.md) | ergm.count-faithful references, real pseudo-likelihood, Gibbs sampler actually uses change statistics |
| [ERGMEgo.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl/blob/main/CHANGELOG.md) | Real Krivitsky–Morris moment matching (placeholders gone), egodata-style two/three-table ingestion, public sampler API |
| [ERGMMulti.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl/blob/main/CHANGELOG.md) | ergm.multi-style block-diagonal model, integer-indexed layers, real within-layer MPLE |
| [ERGMRank.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl/blob/main/CHANGELOG.md) | ergm.rank complete-ordering model, flipped rank orientation, swap-based pseudo-likelihood, new term set |
| [ERGMUserterms.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl/blob/main/CHANGELOG.md) | Add-direction `change_stat` contract for custom terms; validation harness enforces it |
| [TERGM.jl](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl/blob/main/CHANGELOG.md) | CMPLE on attribute-preserving Y⁺/Y⁻ auxiliaries, block-bootstrap SEs, `GOFResult`-based GOF |
| [Siena.jl](https://github.com/statistical-network-analysis-with-Julia/Siena.jl/blob/main/CHANGELOG.md) | RSiena-parity inference (score derivatives, Polyak–Ruppert, t < 0.1), conditional estimation, Network.jl bridge, threaded phase 3 |
| [REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl/blob/main/CHANGELOG.md) | `AttributeMatch`/`EventNetworkState` renames, lazy decay (O(1) updates), corrected control sampling |
| [Relevent.jl](https://github.com/statistical-network-analysis-with-Julia/Relevent.jl/blob/main/CHANGELOG.md) | 13 Gibson p-shifts, `CovSnd`/`CovRec`/`CovInt`, real MLE fitters, streaming statistics |
| [NetworkDynamic.jl](https://github.com/statistical-network-analysis-with-Julia/NetworkDynamic.jl/blob/main/CHANGELOG.md) | R-faithful point-spell semantics, `deactivate!`, stable-ID extraction, mutation tracking |
| [TSNA.jl](https://github.com/statistical-network-analysis-with-Julia/TSNA.jl/blob/main/CHANGELOG.md) | snake_case names (camelCase aliases kept), heap-based earliest arrival, R-`tsna`-aligned return types |
| [NDTV.jl](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl/blob/main/CHANGELOG.md) | Stable vertex identity across frames, real KK/MDS layout, working SVG/movie/HTML export |

## Changes shared by every package

- **Julia 1.12 is the minimum** (the docs previously claimed 1.9+).
- **Package UUIDs were regenerated** — the 0.1.0 placeholders are gone, so
  environments that recorded the old UUIDs need a fresh resolve.
- **StatsAPI everywhere**: `coef`, `stderror`, `vcov` (and friends) are
  methods of the shared generics on every fitted-model type, so loading any
  two model packages together — or `using ERGM, StatsBase` — no longer
  breaks the verb API.
- **One `gof` generic, one coefficient table**: every fit prints through
  Network.jl's shared presentation layer, and goodness-of-fit returns
  `Network.GOFResult` with `(1+k)/(N+1)` Monte-Carlo p-values.
- **Reproducibility**: `rng::AbstractRNG` keywords on sampling/fitting
  paths, with thread-count-independent seeding where work is parallelized.

## Breaking changes at a glance

The full list, each with a migration hint, lives in the per-package
changelogs; these are the ones most likely to touch existing scripts:

- **ERGM.jl** — directed `GWESP` (and `GWDSP`) default to statnet's `:OTP`
  shared-partner type; the old either-direction statistic is
  `type=:union`, relabeled `gwesp.union.fixed.<decay>`.
  `NodeMatch(attr; diff=true)` now means per-level differential homophily
  (as in R); the old mismatch count is the new `NodeMismatch` term.
  `NodeFactor` drops the first level by default (`base=0` keeps all).
  `gof` returns `Network.GOFResult`; `mcmc_diagnostics` throws on MPLE
  fits; custom terms must use the add-direction `change_stat` convention.
- **Network.jl** — `Network{T}` became `Network{T,D}` (one-parameter
  annotations still work; `net.directed` is read-only);
  `Graphs.is_directed` is truthful; `Graphs.is_bipartite` is now
  graph-theoretic, with the two-mode metadata flag renamed `is_two_mode`;
  DataFrames methods moved behind a package extension.
- **TERGM.jl** — `stergm_gof` returns `Network.GOFResult` instead of a
  NamedTuple; formula fields renamed to `formation`/`dissolution`;
  simulation takes coefficients positionally; the
  `FormationTerm`/`DissolutionTerm` wrappers and `EdgeAge`/`Memory`/
  `TimeLag` terms are gone.
- **REM.jl** — `NodeMatch` → `AttributeMatch` and `NetworkState` →
  `EventNetworkState` (no aliases); `has_edge` is no longer exported
  (qualify as `REM.has_edge`); control sampling is now without
  replacement.
- **SNA.jl** — undirected `degree_centrality` single-counts (values halve);
  `betweenness_centrality` defaults to raw scores; `reciprocity`,
  `mutuality`, `hierarchy`, and global `transitivity` follow R `sna`
  semantics.
- **Siena.jl** — convergence requires every |t| < 0.1 plus
  `tconv.max` < 0.25 (fits that 0.1.0 called converged may honestly report
  unconverged); `GOFResult` renamed `SienaGOFResult`; divergence is flagged
  instead of silently clamped.
- **ERGMMulti.jl / ERGMRank.jl / ERGMEgo.jl** — data models rebuilt to
  match their R counterparts (integer-indexed layers; complete-ordering
  rank matrices with flipped orientation; egodata-style tables), so 0.1
  model scripts need the rewrites described in their changelogs.
- **TSNA.jl / NDTV.jl** — camelCase names survive as aliases, but several
  return types changed (e.g. `temporal_distance` returns `nothing` when
  unreachable; layouts are keyed by stable vertex IDs).

If you are coming from R, the
[Coming from statnet / RSiena](/migration/) guide reflects all of the
above and translates workflows verb by verb.
