@def title = "Modelling Network Change"
@def hascode = true

# Modelling Network Change

Fit a separable temporal ERGM to the bundled `s50` friendship panels: 50
girls observed at three yearly waves in the Teenage Friends and Lifestyle
Study. The two components ask how absent ties form and how existing ties
persist between observations. The data and provenance are distributed with
[NetworkCore.jl](https://github.com/statistical-network-analysis-with-Julia/NetworkCore.jl/tree/main/data).

```julia
using NetworkCore, ERGM, TERGM

s50 = load_dataset(:s50)
panels = s50.friendship
@assert length(panels) == 3
@assert all(nv(net) == 50 for net in panels)

result = stergm(panels, [Edges()], [Edges()])
println(result)
logistic(x) = 1 / (1 + exp(-x))
println("formation probability = ", logistic(only(formation_coef(result))))
println("persistence probability = ", logistic(only(persistence_coef(result))))
```

Each probability describes one yearly transition under a model with constant
parameters and independent dyads. A positive persistence coefficient means
existing ties tend to survive; it is the coefficient of R's `Persist()`,
not the sign of `Diss()`. Use `persistence_coef` and `persistence_se` for
this component; there are no `dissolution_*` accessors.

Both formulas are dyad-independent, so the default `method=:auto` fits the
conditional MPLE, which here *is* the conditional MLE, without MCMC. Add a
dyad-dependent term such as `Mutual()` and `:auto` fits the conditional MLE
by MCMC (`method=:cmle`), as tergm's default `estimate = "CMLE"` does. The
conditional MPLE of such a formula (`method=:cmple`) is a pseudo-likelihood:
it reports no z values or p-values unless you ask for the parametric
bootstrap (`se=:bootstrap`). EGMME is not implemented and requesting it
raises an `ArgumentError`.

The observed panels omit changes between waves. These coefficients cannot
distinguish a tie that survived continuously from one that dissolved and
re-formed before the next survey. Friendship nominations are observational;
this example estimates transition associations, not causal effects.

For actor-oriented modelling of the same bundled panels, see the
[RSiena migration workflow](/migration/#saoms_rsiena_sienajl). For
visualizing network change, see
[NDTV.jl](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl).
