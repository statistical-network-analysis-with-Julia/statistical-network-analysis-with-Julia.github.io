@def title = "Modelling Interaction Events"
@def hascode = true

# Modelling Interaction Events

Analyse time-stamped event sequences with a Relational Event Model
([REM.jl](https://github.com/statistical-network-analysis-with-Julia/REM.jl)).
Here we *simulate* 400 events among 8 actors from a model with known
inertia (repetition) and reciprocity effects, then check that estimation
recovers them — a pattern you can reuse to validate any specification.

```julia
using REM, Random

rng = Random.Xoshiro(2026)
n = 8
β = [0.6, 0.9]                      # true [repetition, reciprocity]
stats = [Repetition(), Reciprocity()]
dyads = [(s, r) for s in 1:n for r in 1:n if s != r]
state = EventNetworkState{Float64}(n_actors=n)
state.actors = Set(1:n)

events = Event{Float64}[]
for step in 1:400
    η = [sum(β .* compute_all(stats, state, s, r)) for (s, r) in dyads]
    w = exp.(η .- maximum(η)); w ./= sum(w)
    u = rand(rng); pick = findfirst(>=(u), cumsum(w))
    ev = Event(dyads[pick][1], dyads[pick][2], Float64(step))
    push!(events, ev)
    update!(state, ev)
end
seq = EventSequence(events)

result = fit_rem(seq, stats; n_controls=100, seed=42)
println(result)
```

Output:

```
Relational Event Model Results
==============================
Events: 400, Observations: 22400
Log-likelihood: -314.0359
Converged: true

             Estimate  Std.Error  z value  Pr(>|z|)
repetition     0.5949     0.1452   4.0960   4.2e-05 ***
reciprocity    0.9666     0.1421   6.8035   1.0e-11 ***
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

(Note the p-values print as `4.2e-05`, not a rounded `0.0000` — the
shared presentation layer floors underflowing p-values at `<1e-16`.)

**Interpretation.** Both estimates land close to the truth
(repetition 0.59 vs 0.6; reciprocity 0.97 vs 0.9), well within one
standard error. Substantively: having interacted with someone before
raises the rate of doing so again (`repetition` > 0), and receiving an
interaction raises the rate of returning it (`reciprocity` > 0). The
model is estimated by case-control sampling — each observed event is
compared against sampled non-events from the risk set — which is what
makes REMs tractable for long event streams.

REM.jl fits the *ordinal* model (event order, not exact waiting times).
For exact-timing and full-risk-set estimators, see
[Relevent.jl](https://github.com/statistical-network-analysis-with-Julia/Relevent.jl).
Background: the [model families page](/models/).
