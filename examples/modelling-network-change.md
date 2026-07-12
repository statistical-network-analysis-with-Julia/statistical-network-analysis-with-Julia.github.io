@def title = "Modelling Network Change"
@def hascode = true

# Modelling Network Change

Model network panels observed at discrete time points with a **separable
temporal ERGM** (STERGM) using
[TERGM.jl](https://github.com/statistical-network-analysis-with-Julia/TERGM.jl).
A STERGM is a specific temporal ERGM that factors each transition into a
*formation* model (which new ties appear?) and a *dissolution* model
(which existing ties persist?). We simulate 5 panels with known dynamics
and recover the coefficients.

```julia
using Network, ERGM, TERGM, Random

rng = Random.Xoshiro(7)
init = network(30)                  # 30 actors, directed
for i in 1:30, j in 1:30
    i != j && rand(rng) < 0.08 && add_edge!(init, i, j)
end

formula = STERGM([Edges()], [Edges()])
θ_formation = [-2.5]                # sparse tie formation
θ_persistence = [1.0]               # ties tend to persist

panels = simulate_network_sequence(formula, init, 4,
                                   θ_formation, θ_persistence;
                                   burnin=4000, rng=rng)

result = stergm(panels, [Edges()], [Edges()])
println(result)
```

Output:

```
STERGM Results (cmple)
========================================
Panels: 5; converged: true
Pseudo-log-likelihood: formation -822.059, dissolution -290.224

Formation:
       Estimate  Std.Error   z value  Pr(>|z|)
edges   -2.4720     0.0681  -36.3127    <1e-16 ***

Dissolution (persistence):
       Estimate  Std.Error  z value  Pr(>|z|)
edges    0.8393     0.1001   8.3868    <1e-16 ***
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

**Interpretation.** Estimation recovers the generating process: the
formation coefficient −2.47 (truth −2.5) says a non-tied dyad forms a tie
in a given period with probability logistic(−2.47) ≈ 7.8%, and the
dissolution coefficient 0.84 (truth 1.0) says an existing tie *persists*
with probability logistic(0.84) ≈ 70% — note TERGM.jl parameterizes
dissolution as **persistence**, so positive values mean longer-lived
ties. Estimation is by conditional maximum pseudo-likelihood over the
Krivitsky–Handcock formation network (union of consecutive panels) and
dissolution network (intersection); for dyad-independent models like this
one, that *is* the conditional MLE.

**Next steps:** actor-oriented alternatives to tie-oriented temporal
models are covered on the [model families page](/models/); for
visualizing change, see
[NDTV.jl](https://github.com/statistical-network-analysis-with-Julia/NDTV.jl).
