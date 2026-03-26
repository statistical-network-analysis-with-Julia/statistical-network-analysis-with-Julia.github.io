@def title = "Modelling Cross-Sectional Data"
@def hascode = true

# Modelling Cross-Sectional Data

Fit an Exponential Random Graph Model (ERGM) to an observed network.

```julia
using Network, ERGM

net = network(20; directed=false)
# ... add edges ...

# Fit an ERGM with edge and triangle terms
result = fit_ergm(net, [Edges(), Triangle()])
println(result)
```
