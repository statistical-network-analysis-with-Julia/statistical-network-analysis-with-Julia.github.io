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

Medici        degree = 6   betweenness = 47.5
Guadagni      degree = 4   betweenness = 23.17
Albizzi       degree = 3   betweenness = 19.33
```

**Interpretation.** Only 16.7% of possible marriage ties exist, and just
19% of open two-paths close into triangles — marriage alliances spread
across families rather than clustering. The centrality ranking recovers
the famous result: the **Medici** dominate both degree (6 marriage ties)
and betweenness (47.5, twice the runner-up Guadagni). They sit *between*
the other families, brokering alliances that never form directly — the
structural basis Padgett & Ansell identified for the rise of the Medici.

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

# Network regression: predict business ties from marriage ties
fit = netlogit(biz, flo; reps=1000, rng=Xoshiro(2))
println(fit)
```

Output:

```
Network Logit Model (QAP)
=========================
Null hypothesis: qapspp (1000 replications)
Dyadic observations: 120 (undirected dyads)

                  Estimate     z-value  Pr(>=|stat|)
--------------------------------------------------------
(intercept)      -2.586689     -6.5999           0.0 ***
x1                2.181224      3.6256           0.0 ***
--------------------------------------------------------
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Null deviance: 166.36, Residual deviance: 77.65
AIC: 81.65, BIC: 87.22
```

The observed graph correlation (0.38) exceeds every one of the 1000
permutation draws (`qt.pgreq == 0.0`), and the logit coefficient on
marriage says a marriage tie multiplies the odds of a business tie by
about `exp(2.18) ≈ 9` — marriage and business alliances went together in
Renaissance Florence. The permutation nulls (`nullhyp=:qapspp`, Dekker's
double semi-partialing) respect the dyadic dependence that would
invalidate a classical logistic test.

**Next steps:** model *why* this structure arose with an
[ERGM](/examples/modelling-cross-sectional-data/), or read about the
model families on the [theory page](/models/).
