@def title = "Modelling Interaction Events"
@def hascode = true

# Modelling Interaction Events

Analyse time-stamped event sequences with a Relational Event Model (REM).

```julia
using REM

events = [Event(1, 2, 1.0), Event(2, 1, 2.0), Event(1, 3, 3.0)]
seq = EventSequence(events)

stats = [Repetition(), Reciprocity(), SenderActivity()]
result = fit_rem(seq, stats; n_controls=100, seed=42)
```
