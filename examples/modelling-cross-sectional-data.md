@def title = "Modelling Cross-Sectional Data"
@def hascode = true

# Modelling Cross-Sectional Data

Fit an Exponential Random Graph Model (ERGM) to the Florentine marriage
network with [ERGM.jl](https://github.com/statistical-network-analysis-with-Julia/ERGM.jl):
does family wealth attract marriage ties, and do alliances cluster beyond
what wealth explains?

```julia
using Networks, ERGM

net = network(16; directed=false)
ties = [(1, 9), (2, 6), (2, 7), (2, 9), (3, 5), (3, 9), (4, 7), (4, 11),
        (4, 15), (5, 11), (5, 15), (7, 8), (7, 16), (9, 13), (9, 14),
        (9, 16), (10, 14), (11, 15), (13, 15), (13, 16)]
for (i, j) in ties
    add_edge!(net, i, j)
end
wealth = Dict(1 => 10, 2 => 36, 3 => 55, 4 => 44, 5 => 20, 6 => 32,
              7 => 8, 8 => 42, 9 => 103, 10 => 48, 11 => 49, 12 => 3,
              13 => 27, 14 => 10, 15 => 146, 16 => 48)
set_vertex_attribute!(net, :wealth, wealth)

result = fit_ergm(net, [Edges(), NodeCov(:wealth), GWESP(0.5)])
println(result)
```

Output:

```
ERGM Results
============
Method: mple
Log-likelihood: -51.5358
AIC: 109.07, BIC: 117.43
Converged: true

Coefficients:
                 Estimate  Std.Error  z value  Pr(>|z|)
edges             -2.6148     0.5470  -4.7802   1.8e-06 ***
nodecov.wealth     0.0104     0.0048   2.1777    0.0294 *
gwesp.fixed.0.5    0.0333     0.1725   0.1931    0.8468
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Warning: this model contains dyad-dependent terms and was fit by
maximum pseudolikelihood (MPLE). The standard errors are based on the
naive pseudolikelihood and are suspect (typically anticonservative);
the p-values should not be trusted. Refit with method=:mcmle, or use
se=:bootstrap for parametric-bootstrap standard errors.
```

Because `GWESP` is a dyad-*dependent* term, the default MPLE fit prints
the warning above: its standard errors are naive and typically too small.
For publishable inference refit with `method=:mcmle` (see the
[migration guide](/migration/) for a worked MCMC-MLE fit of exactly this
model) — here the MCMLE coefficients are nearly identical.

**Interpretation.** The negative `edges` term is the baseline sparsity
(an intercept). `nodecov.wealth` is positive and significant: each
additional thousand lira of combined family wealth raises the log-odds of
a marriage tie by about 0.01 — richer families marry more. Conditional on
wealth, the shared-partner term `gwesp` is small and non-significant:
there is no evidence of extra triadic closure in marriage alliances.

**Why GWESP and not a raw triangle count?** A model with a bare
`Triangle()` term is the textbook cause of ERGM *degeneracy*: because
each new triangle creates further triangle opportunities, the fitted
model often places nearly all probability on the empty or the complete
graph. The geometrically-weighted term `GWESP(decay)` discounts
additional shared partners and keeps the model well-behaved — this is
exactly why the statnet lineage introduced it (Snijders et al. 2006;
Hunter 2007). See the [model families page](/models/) for background.

**Next steps:** networks observed at several time points call for a
[temporal ERGM](/examples/modelling-network-change/).
