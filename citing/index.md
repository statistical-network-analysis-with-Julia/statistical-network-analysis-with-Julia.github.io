@def title = "How to cite"

# How to cite

These packages port methods that other people designed, published and first
implemented in R. When you publish results obtained with them, please cite
three things:

1. **the Julia package you used**, so readers can find and rerun the code;
2. **the R package it ports**, whose authors ask to be cited and whose design
   the Julia package follows;
3. **the papers that introduced the method**, which your analysis relies on.

The statnet packages and RSiena state this request in their own citation
files (`citation("ergm")`, `citation("RSiena")` in R).

## The Julia packages

Every package repository has a `CITATION.bib` with its BibTeX entry, also shown
in its README. The packages are unreleased (version 0.2.0, Revel.jl 0.1.0), so
cite the commit you used. Record it with `git rev-parse HEAD` in each checkout,
and add it to the entry's `note`, for example
`note = {Version 0.2.0, commit 1590e6d}`.

## What else to cite, package by package

| Julia package | R package to cite | Method papers |
|:---|:---|:---|
| [NetworkCore.jl](https://github.com/statistical-network-analysis-with-Julia/NetworkCore.jl) | `network` (Butts) | Butts (2008a) |
| [SNA.jl](https://github.com/statistical-network-analysis-with-Julia/SNA.jl) | `sna` (Butts) | Butts (2008b) |
| [ERGM.jl](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl) | `ergm` (Handcock et al.) | Hunter et al. (2008); Krivitsky et al. (2023) |
| [ERGMCount.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl) | `ergm.count` (Krivitsky) | Krivitsky (2012) |
| [ERGMEgo.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl) | `ergm.ego` (Krivitsky) | Krivitsky and Morris (2017) |
| [ERGMMulti.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl) | `ergm.multi` (Krivitsky) | Krivitsky, Koehly and Marcum (2020) |
| [ERGMRank.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl) | `ergm.rank` (Krivitsky) | Krivitsky and Butts (2017) |
| [ERGMUserterms.jl](https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl) | `ergm.userterms` | Hunter, Goodreau and Handcock (2013) |
| [TERGM.jl](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl) | `tergm` (Krivitsky and Handcock) | Krivitsky and Handcock (2014); for the block bootstrap over transitions (`se=:block_bootstrap`, btergm's scheme), Leifeld, Cranmer and Desmarais (2018) |
| [Siena.jl](https://github.com/statistical-network-analysis-with-Julia/Siena.jl) | `RSiena` (Snijders et al.) | Snijders (2001); Snijders, van de Bunt and Steglich (2010) |
| [REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl) | — (case-control sampling follows eventnet) | Butts (2008c); Lerner and Lomi (2020) |
| [Relevent.jl](https://github.com/statistical-network-analysis-with-Julia/Relevent.jl) (the engine underneath Revel.jl) | `relevent` (Butts) | Butts (2008c) |
| [Revel.jl](https://github.com/statistical-network-analysis-with-Julia/Revel.jl) | `relevent` (Butts); `remstats` (Arena et al.) | Butts (2008c); Meijerink-Bosman et al. (2023) |
| [DynamicNetworks.jl](https://github.com/statistical-network-analysis-with-Julia/DynamicNetworks.jl) | `networkDynamic` (Butts, Leslie-Cook, Krivitsky and Bender-deMoll) | — |
| [TSNA.jl](https://github.com/statistical-network-analysis-with-Julia/TSNA.jl) | `tsna` (Bender-deMoll and Morris) | — |
| [NDTV.jl](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl) | `ndtv` (Bender-deMoll) | Bender-deMoll and McFarland (2006) |

Most analyses use more than one package. A fitted ERGM, for example, uses
NetworkCore.jl and ERGM.jl: cite both, with `network` and `ergm` and their papers.
Revel.jl's effects come from a wider literature; its documentation lists the
source of each effect in `docs/references.bib`.

## References

- Bender-deMoll, S. and McFarland, D. A. (2006). The art and science of dynamic
  network visualization. *Journal of Social Structure*, 7(2).
- Butts, C. T. (2008a). network: A package for managing relational data in R.
  *Journal of Statistical Software*, 24(2).
  [doi:10.18637/jss.v024.i02](https://doi.org/10.18637/jss.v024.i02)
- Butts, C. T. (2008b). Social network analysis with sna. *Journal of
  Statistical Software*, 24(6).
  [doi:10.18637/jss.v024.i06](https://doi.org/10.18637/jss.v024.i06)
- Butts, C. T. (2008c). A relational event framework for social action.
  *Sociological Methodology*, 38(1), 155–200.
  [doi:10.1111/j.1467-9531.2008.00203.x](https://doi.org/10.1111/j.1467-9531.2008.00203.x)
- Hunter, D. R., Goodreau, S. M. and Handcock, M. S. (2013). ergm.userterms: A
  template package for extending statnet. *Journal of Statistical Software*,
  52(2). [doi:10.18637/jss.v052.i02](https://doi.org/10.18637/jss.v052.i02)
- Hunter, D. R., Handcock, M. S., Butts, C. T., Goodreau, S. M. and Morris, M.
  (2008). ergm: A package to fit, simulate and diagnose exponential-family
  models for networks. *Journal of Statistical Software*, 24(3), 1–29.
  [doi:10.18637/jss.v024.i03](https://doi.org/10.18637/jss.v024.i03)
- Krivitsky, P. N. (2012). Exponential-family random graph models for valued
  networks. *Electronic Journal of Statistics*, 6, 1100–1128.
  [doi:10.1214/12-EJS696](https://doi.org/10.1214/12-EJS696)
- Krivitsky, P. N. and Butts, C. T. (2017). Exponential-family random graph
  models for rank-order relational data. *Sociological Methodology*, 47(1),
  68–112. [doi:10.1177/0081175017692623](https://doi.org/10.1177/0081175017692623)
- Krivitsky, P. N. and Handcock, M. S. (2014). A separable model for dynamic
  networks. *Journal of the Royal Statistical Society, Series B*, 76(1), 29–46.
  [doi:10.1111/rssb.12014](https://doi.org/10.1111/rssb.12014)
- Krivitsky, P. N., Hunter, D. R., Morris, M. and Klumb, C. (2023). ergm 4: New
  features for analyzing exponential-family random graph models. *Journal of
  Statistical Software*, 105(6), 1–44.
  [doi:10.18637/jss.v105.i06](https://doi.org/10.18637/jss.v105.i06)
- Krivitsky, P. N., Koehly, L. M. and Marcum, C. S. (2020). Exponential-family
  random graph models for multi-layer networks. *Psychometrika*, 85(3),
  630–659. [doi:10.1007/s11336-020-09720-7](https://doi.org/10.1007/s11336-020-09720-7)
- Krivitsky, P. N. and Morris, M. (2017). Inference for social network models
  from egocentrically sampled data, with application to understanding
  persistent racial disparities in HIV prevalence in the US. *Annals of Applied
  Statistics*, 11(1), 427–455.
  [doi:10.1214/16-AOAS1010](https://doi.org/10.1214/16-AOAS1010)
- Leifeld, P., Cranmer, S. J. and Desmarais, B. A. (2018). Temporal exponential
  random graph models with btergm: Estimation and bootstrap confidence
  intervals. *Journal of Statistical Software*, 83(6).
  [doi:10.18637/jss.v083.i06](https://doi.org/10.18637/jss.v083.i06)
- Lerner, J. and Lomi, A. (2020). Reliability of relational event model
  estimates under sampling: How to fit a relational event model to 360 million
  dyadic events. *Network Science*, 8(1), 97–135.
  [doi:10.1017/nws.2019.57](https://doi.org/10.1017/nws.2019.57)
- Meijerink-Bosman, M., Back, M., Geukes, K., Leenders, R. and Mulder, J.
  (2023). Discovering trends of social interaction behavior over time: An
  introduction to relational event modeling. *Behavior Research Methods*,
  55(3), 997–1023.
  [doi:10.3758/s13428-022-01821-8](https://doi.org/10.3758/s13428-022-01821-8)
- Snijders, T. A. B. (2001). The statistical evaluation of social network
  dynamics. *Sociological Methodology*, 31(1), 361–395.
  [doi:10.1111/0081-1750.00099](https://doi.org/10.1111/0081-1750.00099)
- Snijders, T. A. B., van de Bunt, G. G. and Steglich, C. E. G. (2010).
  Introduction to stochastic actor-based models for network dynamics. *Social
  Networks*, 32(1), 44–60.
  [doi:10.1016/j.socnet.2009.02.004](https://doi.org/10.1016/j.socnet.2009.02.004)

## The R packages

For the R packages, use the entry that R itself prints, because it carries the
version you compared against:

```r
citation("ergm")             # also "network", "sna", "tergm", "ergm.count", ...
toBibtex(citation("RSiena"))
```

Each package is on CRAN (`https://CRAN.R-project.org/package=<name>`). The
golden fixtures in each Julia package's `test/fixtures/` record the R package
versions the Julia results were compared with.
