@def title = "Modelling Interaction Events"
@def hascode = true

# Modelling Interaction Events

Model the bundled World Trade Center police radio-call sequence from Butts,
Petrescu-Prahova and Cross (2007). It contains 481 ordered events and an
eligible universe of 37 actors, including two actors absent from the event
endpoints. The bundled time column is an **event number**, not elapsed clock
time: use an ordinal model, not a waiting-time likelihood.

```julia
using Networks, REM, Relevent, Random

calls = load_dataset(:wtc_police_calls)
events = [Event(row[2], row[3], Float64(row[1])) for row in eachrow(calls.events)]
seq = EventSequence(events; actors=ActorSet(1:calls.n_actors))
@assert length(events) == 481
@assert calls.n_actors == 37

# Sample controls from the declared eligible universe for each event.
result = REM.fit_rem(seq, [Repetition(), Reciprocity()];
                     n_controls=50, rng=Xoshiro(42))
println(result)
println(fit_metadata(result))

# Full-risk-set ordinal model with two R relevent effects.
full = fit_obpm(events, [PShift(:AB_BA), CovSnd(Float64.(calls.is_icr))], calls.n_actors)
println(full)
```

The REM fit relates past interaction to the next selected dyad. Relevent's
`PShift(:AB_BA)` measures immediate turn reversal; `CovSnd` compares senders
in institutional coordinator roles with other senders. The two examples
have different statistics and cannot be compared as two estimates of the
same specification. Positive coefficients indicate greater relative event
propensity, conditional on the chosen risk set and history.

Declaring all eligible actors matters: deriving the universe from endpoints
would exclude legitimate non-events. Under a correctly specified sampled
conditional likelihood, Hessian uncertainty already reflects the loss of
information from control sampling. `se=:sandwich` provides an event-clustered
alternative for within-stratum misspecification. `control_draw_cov` measures
sensitivity to control redraws; it is not an extra variance term, and REM
rejects `se=:bootstrap`.

These are observational radio communications during one emergency. Role
coefficients need not be causal, and repeated events may reflect omitted
coordination processes. Inspect fit diagnostics and compare substantive
specifications. The [data provenance](https://github.com/statistical-network-analysis-with-Julia/Networks.jl/tree/main/data)
and [migration guide](/migration/) document the source and effect conventions.
