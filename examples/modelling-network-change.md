@def title = "Modelling Network Change"
@def hascode = true

# Modelling Network Change

Fit a temporal ERGM to network panels observed over time.

```julia
using Network, ERGM, TERGM

# Two network panels observed at t=1 and t=2
net1 = network(30; directed=false)
net2 = network(30; directed=false)
# ... add edges to both ...

# Fit a separable temporal ERGM (STERGM)
result = fit_stergm([net1, net2],
    formation = [Edges(), Triangle()],
    dissolution = [Edges()])
```
