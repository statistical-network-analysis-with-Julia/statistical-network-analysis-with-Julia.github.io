@def title = "Describing Network Structure"
@def hascode = true

# Describing Network Structure

Compute density, reciprocity, transitivity, and centrality scores for a network.

```julia
using Network, SNA

net = network(20; directed=false)
# ... add edges ...

# Density, reciprocity, transitivity
gden(net)
grecip(net)
gtrans(net)

# Centrality scores
degree_centrality(net)
betweenness_centrality(net)
closeness_centrality(net)
```
