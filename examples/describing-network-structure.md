@def title = "Describing Network Structure"
@def hascode = true

# Describing Network Structure

Compute density, transitivity, the triad census, and centrality scores
with [SNA.jl](https://github.com/statistical-network-analysis-with-Julia/SNA.jl),
using a classic dataset: Padgett's network of marriage ties among 16
Renaissance Florentine families. Every measure below matches R `sna` on
the same data (the package's test suite pins these values).

```julia
using Networks, SNA

net = load_dataset(:florentine_marriage)
families = vertex_attribute_vector(net, :name, String)

# Graph-level indices
println("density = ", gden(net))
println("transitivity = ", gtrans(net))
println("triad census = ", triad_census(net))

# Vertex-level centrality
deg = degree_centrality(net)
bet = betweenness_centrality(net)
for v in sortperm(bet; rev=true)[1:3]
    println(families[v], ": degree = ", deg[v], ", betweenness = ", bet[v])
end
```

**Interpretation.** Only 16.7% of possible marriage ties exist, and just
19% of open two-paths close into triangles — marriage alliances spread
across families rather than clustering. The centrality ranking recovers
the famous result: the **Medici** dominate both degree (6 marriage ties)
and betweenness (47.5, twice the runner-up Guadagni). They sit *between*
the other families, brokering alliances that never form directly — a structural pattern discussed by Padgett & Ansell in their account of
the rise of the Medici. These descriptive statistics alone do not establish
a causal explanation.

## Centralization and comparing two relations

How concentrated is the network on its most central family, and is the
marriage relation associated with the *business* relation among the same
families? Freeman centralization and QAP inference (both new in the 0.2
series, following R `sna`) answer these:

```julia
using Statistics, Random

flo = load_dataset(:florentine_marriage)   # same network, bundled
biz = load_dataset(:florentine_business)   # business ties, same families

# Freeman graph centralization of a vertex centrality measure
centralization(flo, :degree)        # 0.2667
centralization(flo, :betweenness)   # 0.3835

# QAP test: is the graph correlation between the two relations larger
# than expected under random relabelling of the families?
gcor(a, b) = cor(vec(a), vec(b))
qt = qaptest(gcor, flo, biz; reps=1000, rng=Xoshiro(1))

# A separate model: business ties versus absolute family wealth difference
wealth = vertex_attribute_vector(flo, :wealth, Float64)
wealth_difference = abs.(wealth .- wealth')
fit = netlogit(biz, wealth_difference; reps=1000, rng=Xoshiro(2))
println(fit)
```

The QAP correlation test evaluates whether marriage and business relations
are associated. Inspect `qt.pgreq` for its upper-tail permutation proportion.
Zero exceedances in 1000 draws means resolution below 0.001, not a zero
population probability; the display reports that limit.

The separate logistic model asks whether families with more similar wealth
are more likely to have a business tie. Its slope is approximately −0.0032
per thousand lira of absolute wealth difference, with QAP p ≈ 0.806 for this
seeded run. These data provide little evidence for that particular wealth
similarity association. It is a different question from the correlation
between the two observed relations.

QAP simultaneously relabels actors to preserve each matrix's structure.
Inference depends on the permutation null and exchangeability of labels;
it does not adjust for arbitrary unobserved confounding or establish
causation. Measures are binary by default, including networks that carry
edge weights. Directed components use strong connectivity by default; directed clique
symmetrization requires mutual arcs. These are distinct conventions, matching
R `sna`; request weak components or either-direction symmetrization explicitly.
Masked dyads are rejected unless `missing=:face` is supplied.

**Next steps:** model patterns of tie formation with an
[ERGM](/examples/modelling-cross-sectional-data/), or read about the
model families on the [theory page](/models/).
