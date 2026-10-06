@def title = "Modelling Cross-Sectional Data"
@def hascode = true

# Modelling Cross-Sectional Data

Fit an ERGM to the bundled Florentine marriage network: 16 families,
20 marriage ties, and family wealth recorded in thousands of lira.
The specification asks whether wealth and shared partners are associated
with marriage ties, conditional on each other.

```julia
using NetworkCore, ERGM, Random

net = load_dataset(:florentine_marriage)
terms = [Edges(), NodeCov(:wealth), GWESP(0.5)]
result = fit_ergm(net, terms; method=:mcmle, rng=Xoshiro(42))
println(result)
println(fit_metadata(result))
```

The `edges` coefficient captures baseline sparsity. `NodeCov(:wealth)`
adds the wealth of both endpoints; its coefficient gives the conditional
change in tie log-odds per additional thousand lira of combined wealth.
`GWESP(0.5)` represents shared-partner configurations with diminishing
increments. Its interpretation depends on the rest of the specification.

`GWESP` makes this model dyad-dependent, so the default `method=:auto`
would fit it by MCMC maximum likelihood anyway, as R's `ergm()` does; the
example names `method=:mcmle` to make the choice visible. For a formula with
no dyad-dependent term, `:auto` fits the MPLE, which is then the exact MLE.
`method=:mple` on this formula maximizes a pseudo-likelihood instead: it
reports estimates and standard errors but withholds z values, p-values and
intervals unless you ask for `se=:bootstrap`. A successful optimizer or a
convenient term choice alone does not establish adequate mixing,
convergence, or model fit.

```julia
println("converged = ", result.converged)
diagnostics = gof(result; n_sim=100, rng=Xoshiro(1))
println(diagnostics)
sims = simulate_ergm(result; n_sim=3, rng=Xoshiro(2))
println("simulated densities = ", network_density.(sims))
```

Check convergence and simulated distributions before interpreting Wald
intervals. An apparently small shared-partner coefficient is not evidence
that social closure is absent; this is one small observational network.
Wealth associations likewise do not identify the causal effect of wealth.
Geometrically weighted terms can reduce some degeneracy problems compared
with raw triangle terms, but they do not guarantee a well-behaved model.

For panels observed at several times, see the
[temporal ERGM example](/examples/modelling-network-change/).
