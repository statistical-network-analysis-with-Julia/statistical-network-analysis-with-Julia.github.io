@def title = "Learn"

# Learn

## Package Documentation

Each package has its own documentation site built with [Documenter.jl](https://documenter.juliadocs.org/):

| Package | Documentation | Description |
|---------|---------------|-------------|
| Network.jl | [Docs](https://statistical-network-analysis-with-Julia.github.io/Network.jl/stable/) | Core network data structures |
| SNA.jl | [Docs](https://statistical-network-analysis-with-Julia.github.io/SNA.jl/stable/) | Social network analysis |
| ERGM.jl | [Docs](https://statistical-network-analysis-with-Julia.github.io/ERGM.jl/stable/) | Exponential random graph models |
| REM.jl | [Docs](https://statistical-network-analysis-with-Julia.github.io/REM.jl/stable/) | Relational event models |
| Siena.jl | [Docs](https://statistical-network-analysis-with-Julia.github.io/Siena.jl/stable/) | Stochastic actor-oriented models |
| NetworkDynamic.jl | [Docs](https://statistical-network-analysis-with-Julia.github.io/NetworkDynamic.jl/stable/) | Dynamic network structures |

## Quick Start

### Creating a Network

```julia
using Network

# Create a directed network with 5 vertices
net = network(10)

# Add edges
add_edge!(net, 1, 2)
add_edge!(net, 2, 3)
add_edge!(net, 3, 1)

# Set vertex attributes
set_vertex_attribute!(net, :name, Dict(1 => "Alice", 2 => "Bob", 3 => "Carol"))
```

### Fitting an ERGM

```julia
using Network, ERGM

net = network(20; directed=false)
# ... add edges ...

result = fit_ergm(net, [Edges(), Triangle()])
println(result)
```

### Fitting a Relational Event Model

```julia
using REM

events = [Event(1, 2, 1.0), Event(2, 1, 2.0), Event(1, 3, 3.0)]
seq = EventSequence(events)

stats = [Repetition(), Reciprocity(), SenderActivity()]
result = fit_rem(seq, stats; n_controls=100, seed=42)
```

## R StatNet Lineage

This ecosystem ports the [R StatNet](https://statnet.org/) collection. Researchers familiar with R StatNet will find analogous functionality and naming conventions in these Julia packages.

| Julia Package | R Package | Domain |
|---------------|-----------|--------|
| Network.jl | network | Network data structures |
| SNA.jl | sna | Descriptive analysis |
| ERGM.jl | ergm | ERG models |
| REM.jl | eventnet | Relational event models |
| Siena.jl | RSiena | Longitudinal models |
| NetworkDynamic.jl | networkDynamic | Dynamic networks |
| TERGM.jl | tergm | Temporal ERGMs |
| TSNA.jl | tsna | Temporal analysis |
| NDTV.jl | ndtv | Temporal visualization |
| Relevent.jl | relevent | Extended REMs |
