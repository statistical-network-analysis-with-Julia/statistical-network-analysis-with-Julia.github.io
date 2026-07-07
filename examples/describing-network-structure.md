@def title = "Describing Network Structure"
@def hascode = true

# Describing Network Structure

Compute density, transitivity, the triad census, and centrality scores
with [SNA.jl](https://github.com/statistical-network-analysis-with-Julia/SNA.jl),
using a classic dataset: Padgett's network of marriage ties among 16
Renaissance Florentine families. Every measure below matches R `sna` on
the same data (the package's test suite pins these values).

```julia
using Network, SNA

# Padgett's Florentine marriage network: 16 families, 20 marriage ties
families = ["Acciaiuoli", "Albizzi", "Barbadori", "Bischeri", "Castellani",
            "Ginori", "Guadagni", "Lamberteschi", "Medici", "Pazzi",
            "Peruzzi", "Pucci", "Ridolfi", "Salviati", "Strozzi", "Tornabuoni"]
net = network(16; directed=false)
ties = [(1, 9), (2, 6), (2, 7), (2, 9), (3, 5), (3, 9), (4, 7), (4, 11),
        (4, 15), (5, 11), (5, 15), (7, 8), (7, 16), (9, 13), (9, 14),
        (9, 16), (10, 14), (11, 15), (13, 15), (13, 16)]
for (i, j) in ties
    add_edge!(net, i, j)
end

# Graph-level indices
gden(net)          # density
gtrans(net)        # transitivity
triad_census(net)  # undirected triad census (0, 1, 2, 3 edges)

# Vertex-level centrality
deg = degree_centrality(net)
bet = betweenness_centrality(net)
```

Output:

```
gden = 0.1667
gtrans = 0.1915
triad_census = [324, 195, 38, 3]

Medici        degree/2 = 6   betweenness = 47.5
Guadagni      degree/2 = 4   betweenness = 23.17
Albizzi       degree/2 = 3   betweenness = 19.33
```

**Interpretation.** Only 16.7% of possible marriage ties exist, and just
19% of open two-paths close into triangles — marriage alliances spread
across families rather than clustering. The centrality ranking recovers
the famous result: the **Medici** dominate both degree (6 marriage ties)
and betweenness (47.5, twice the runner-up Guadagni). They sit *between*
the other families, brokering alliances that never form directly — the
structural basis Padgett & Ansell identified for the rise of the Medici.

**Next steps:** model *why* this structure arose with an
[ERGM](/examples/modelling-cross-sectional-data/), or read about the
model families on the [theory page](/models/).
