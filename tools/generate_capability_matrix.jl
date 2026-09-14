# Generate the ecosystem capability/parity matrix.
#
# Site issue #2: "Feature status is scattered across package prose. Users cannot
# quickly tell whether a term/estimator is implemented, approximate,
# simulation-only, tested against R, missing-data aware, or suitable only below a
# certain scale." And: "Generate package-specific tables from shared
# machine-readable data to avoid drift."
#
# So this file GENERATES the matrix; it does not hand-maintain one. Every column
# is read out of the code itself:
#
#   estimand / objective / is_exact / se_method / missing_method / tie_method
#       -- from the shared result-metadata protocol (Networks.jl `src/results.jl`),
#          by actually FITTING a small model of each family and asking the result
#          what it did. A capability table that is written by hand drifts away
#          from the code within one release; one that is produced by running the
#          code cannot.
#
#   tested against R / tested scale
#       -- from the golden fixtures on disk (`*/test/fixtures/*.toml`), read
#          through `Networks.load_golden`, so the reference package, its version
#          and the size of the validated dataset come from the fixture's own
#          [provenance] block rather than from somebody's memory. No fixture,
#          no claim.
#
#   missing-data support
#       -- from the `Networks.supports_missing` trait, queried on the actual
#          fitting functions. The trait defaults to `false`, so a routine that
#          has never thought about missingness is reported as not handling it.
#
# `is_exact` is a property of the FIT, not of the estimator -- that is the whole
# point of the protocol. MPLE of a dyad-independent formula IS maximum
# likelihood; of a dyad-dependent one it is not. So the ERGM-family probes below
# come in pairs, dyad-independent and dyad-dependent, and both rows are shown.
#
# Usage (from the monorepo root, with the root workspace project active):
#
#   # write the page
#   julia --project=. .../tools/generate_capability_matrix.jl
#
#   # CI freshness gate: regenerate and diff against the committed page
#   julia --project=. .../tools/generate_capability_matrix.jl --check
#
#   # or send it somewhere else
#   julia --project=. .../tools/generate_capability_matrix.jl --out=/tmp/cap.md

using Networks
using SNA, ERGM, ERGMCount, ERGMEgo, ERGMMulti, ERGMRank
using REM, Relevent, Siena, TERGM, TSNA
using Random

const SITE = normpath(joinpath(@__DIR__, ".."))
# Where the sibling package checkouts live. Defaults to the parent of this site
# repo (the monorepo layout); CI reconstructs the layout elsewhere and points
# SNWJ_ROOT at it, exactly as `check_snippets.jl` does.
const ROOT = normpath(get(ENV, "SNWJ_ROOT", joinpath(SITE, "..")))
const PAGE = joinpath(SITE, "capabilities.md")
const ORG = "statistical-network-analysis-with-Julia"

issue(pkg, n) = "[$pkg#$n](https://github.com/$ORG/$pkg.jl/issues/$n)"
site_issue(n) = "[site#$n](https://github.com/$ORG/$ORG.github.io/issues/$n)"

# ---------------------------------------------------------------------------
# The canonical small fits, one per model family (two where the dyad-dependence
# contrast applies). Everything here is deliberately tiny: the whole sweep must
# run in well under a couple of minutes, because a generator nobody runs is a
# hand-maintained table with extra steps.
# ---------------------------------------------------------------------------

# --- SNA: dyadic regression on a small undirected graph with one dyad covariate
function sna_net()
    net = network(6; directed=false)
    for (i, j) in [(1, 2), (1, 3), (2, 3), (3, 4), (4, 5), (5, 6), (2, 6)]
        add_edge!(net, i, j)
    end
    return net
end
const SNA_X = [abs(i - j) * 1.0 for i in 1:6, j in 1:6]

# --- ERGM / TERGM / ERGMCount / ERGMMulti: the dyad-independent vs
#     dyad-dependent pair that makes `is_exact` mean something
function ergm_net(n=10)
    net = network(n; directed=false)
    for i in 1:n, j in (i + 1):n
        ((i + j) % 3 == 0) && add_edge!(net, i, j)
    end
    return net
end
small_ergm(; dependent::Bool) =
    mple(ERGMModel(ERGMFormula(dependent ? [Edges(), GWESP(0.5)] : [Edges()]),
                   ergm_net()))

function tergm_panels()
    t0 = network(5)
    for (i, j) in [(1, 2), (2, 1), (3, 4), (4, 5)]
        add_edge!(t0, i, j)
    end
    t1 = network(5)
    for (i, j) in [(1, 2), (3, 4), (2, 3), (5, 1)]
        add_edge!(t1, i, j)
    end
    return [t0, t1]
end

function count_net(n=6; seed=11)
    rng = Xoshiro(seed)
    net = network(n; directed=true)
    for i in 1:n, j in 1:n
        i == j && continue
        if rand(rng) < 0.4
            add_edge!(net, i, j)
            set_edge_attribute!(net, :weight, i, j, rand(rng, 1:4))
        end
    end
    return net
end

function multi_net()
    m = MultilayerNetwork(4; directed=true)
    add_layer!(m, :friendship)
    add_layer!(m, :advice)
    for (i, j) in [(1, 2), (2, 1), (1, 3), (3, 4)]
        add_layer_edge!(m, :friendship, i, j)
    end
    for (i, j) in [(1, 2), (2, 3), (3, 4), (4, 3)]
        add_layer_edge!(m, :advice, i, j)
    end
    return m
end

# --- ERGMEgo: an egocentric census of a small simulated population
function ego_fit()
    rng = Xoshiro(21)
    n = 20
    net = network(n; directed=false)
    for i in 1:n, j in (i + 1):n
        rand(rng) < 0.15 && add_edge!(net, i, j)
    end
    ed = simulate_ego_sample(net, n; rng=rng)
    return fit_ergm_ego(ed, [EgoEdges()]; ppopsize=n, n_samples=100,
                        burnin=200, interval=5, rng=rng)
end

# --- ERGMRank: the same swap-MPLE under its two standard-error options, which
#     is the contrast that matters for this package (see the limitations below)
function rank_net()
    n = 6
    rng = MersenneTwister(1)
    ranks = zeros(Int, n, n)
    for ego in 1:n
        alters = [actor for actor in 1:n if actor != ego]
        ranks[ego, alters] = randperm(rng, n - 1)
    end
    return RankNetwork(ranks)
end

const RANK_TERMS = [RankDeference(), RankNonconformity()]

# --- REM / Relevent: one simulated event stream with a reciprocity signal,
#     with the actor universe DECLARED (REM#1: inferring it from the observed
#     endpoints silently changes the estimand)
function event_stream(n, T; seed)
    rng = Xoshiro(seed)
    events = Event{Float64}[]
    prev = (1, 2)
    for t in 1.0:1.0:Float64(T)
        s, r = rand(rng) < 0.6 ? (prev[2], prev[1]) : (rand(rng, 1:n), rand(rng, 1:n))
        s == r && (r = mod1(s + 1, n))
        push!(events, Event(s, r, t))
        prev = (s, r)
    end
    return events
end

rem_fit() = REM.fit_rem(EventSequence(event_stream(6, 30; seed=5);
                                      actors=ActorSet(collect(1:6))),
                        [Repetition(), Reciprocity()]; n_controls=5, rng=Xoshiro(1))

# --- Siena: small strict-converged mechanics probe, not substantive inference.
function siena_fit()
    n = 10
    before = zeros(Int, n, n)
    for i in 1:n
        before[i, mod1(i + 1, n)] = 1
    end
    after = copy(before)
    for i in 1:5
        after[i, mod1(i + 2, n)] = 1
    end
    data = siena_data()
    add_nodeset!(data, NodeSet(n))
    add_dependent!(data, DependentNetwork(:net, [before, after]))
    effects = get_effects(data)
    include_effects!(effects, :net, [:outdegree])
    return fit_siena(data, effects; rng=MersenneTwister(1),
        algorithm=SienaAlgorithm(verbose=false, phase3_iterations=2000))
end

# (package, description of the fit, thunk producing a fitted result)
const PROBES = [
    ("SNA", "`netlm`, dyadic OLS, classical inference", () -> netlm(sna_net(), [SNA_X]; nullhyp=:classical)),
    ("SNA", "`netlogit`, dyadic logit, classical inference", () -> netlogit(sna_net(), [SNA_X]; nullhyp=:classical)),
    ("ERGM", "`mple`, **dyad-independent** formula (`edges`)", () -> small_ergm(dependent=false)),
    ("ERGM", "`mple`, **dyad-dependent** formula (`edges + gwesp`)", () -> small_ergm(dependent=true)),
    ("ERGM", "`mcmle`, dyad-dependent formula", () -> mcmle(ERGMModel(ERGMFormula([Edges(), GWESP(0.5)]), ergm_net());
                                                            n_samples=400, maxiter=40, rng=Xoshiro(10))),
    ("TERGM", "`stergm`/CMPLE, **dyad-independent** formula", () -> stergm(tergm_panels(), [Edges()], [Edges()])),
    ("TERGM", "`stergm`/CMPLE, **dyad-dependent** formula", () -> stergm(tergm_panels(), [Edges(), GWESP(0.5)], [Edges()])),
    ("ERGMCount", "`fit_ergm_count`, **dyad-independent** (`sum + nonzero`)", () -> fit_ergm_count(count_net(), [SumTerm(), NonzeroTerm()])),
    ("ERGMCount", "`fit_ergm_count`, **dyad-dependent** (`sum + mutual`)", () -> fit_ergm_count(count_net(), [SumTerm(), CountMutualTerm()])),
    ("ERGMMulti", "`ergm_multi`, **dyad-independent** (per-layer edges)", () -> ergm_multi(multi_net(), [LayerEdges(1), LayerEdges(2)])),
    ("ERGMMulti", "`ergm_multi`, **dyad-dependent** (interlayer dependence)", () -> ergm_multi(multi_net(), [LayerEdges(), InterlayerDependence(1, 2)])),
    ("ERGMEgo", "`fit_ergm_ego`, MCMC method of moments", ego_fit),
    ("ERGMRank", "`fit_ergm_rank`, swap-MPLE, default SEs", () -> fit_ergm_rank(rank_net(), RANK_TERMS)),
    ("ERGMRank", "`fit_ergm_rank`, swap-MPLE, `se=:bootstrap`", () -> fit_ergm_rank(rank_net(), RANK_TERMS; se=:bootstrap, n_boot=40, rng=Xoshiro(3))),
    ("ERGMRank", "`fit_ergm_rank`, MCMC-MLE", () -> fit_ergm_rank(rank_net(), RANK_TERMS; method=:mcmle, n_samples=1000, maxiter=40, rng=Xoshiro(17))),
    ("REM", "`fit_rem`, case-control conditional logit", rem_fit),
    ("Relevent", "`fit_obpm`, ordinal B-P model", () -> fit_obpm(event_stream(5, 30; seed=9), [PShift(:AB_BA)], 5)),
    ("Relevent", "`fit_timing`, exact-time hazard model", () -> fit_timing(event_stream(5, 30; seed=9), [PShift(:AB_BA)], 5)),
    ("Siena", "`siena07`, SAOM by method of moments", siena_fit),
]

# The fitting functions whose missing-data trait we report. `supports_missing`
# defaults to `false`, so this is an honest census, not an allowlist.
const ROUTINES = [
    ("Networks", "`network_density`", network_density),
    ("SNA", "`degree_centrality`", degree_centrality),
    ("TSNA", "`t_density`", t_density),
    ("TSNA", "`t_reciprocity`", t_reciprocity),
    ("ERGM", "`mple`", mple),
    ("ERGM", "`mcmle`", mcmle),
    ("SNA", "`netlm`", netlm),
    ("SNA", "`netlogit`", netlogit),
    ("TERGM", "`stergm`", stergm),
    ("ERGMCount", "`fit_ergm_count`", fit_ergm_count),
    ("ERGMEgo", "`fit_ergm_ego`", fit_ergm_ego),
    ("ERGMMulti", "`ergm_multi`", ergm_multi),
    ("ERGMRank", "`fit_ergm_rank`", fit_ergm_rank),
    ("REM", "`fit_rem`", REM.fit_rem),
    ("Relevent", "`fit_obpm`", fit_obpm),
    ("Relevent", "`fit_timing`", fit_timing),
    ("Siena", "`siena07`", siena07),
]

const PACKAGES = ["Networks", "SNA", "ERGM", "TERGM", "ERGMCount", "ERGMEgo",
                  "ERGMMulti", "ERGMRank", "REM", "Relevent", "Siena"]

# ---------------------------------------------------------------------------
# Golden fixtures actually present on disk, with the reference they pin against
# ---------------------------------------------------------------------------

# The fixtures' `dataset` line names the data and then, in some of them, explains
# how the data were frozen. Only the first clause is the *scale that was
# validated*, which is the column this page wants; the rest belongs in the
# fixture, not in a table cell. Cut at the first `--` or `;`.
function scale_of(dataset::AbstractString)
    s = first(split(String(dataset), " -- "))
    s = first(split(s, "; "))
    return replace(strip(s), "|" => "\\|")
end

function fixtures_for(pkg::AbstractString)
    dir = joinpath(ROOT, "$pkg.jl", "test", "fixtures")
    isdir(dir) || return NamedTuple[]
    out = NamedTuple[]
    for f in sort(readdir(dir))
        endswith(f, ".toml") || continue
        g = load_golden(joinpath(dir, f))
        p = g.provenance
        # The reference implementation is whatever *_version keys the fixture
        # recorded (`network` is R's data container, not the estimator, so it is
        # not what the claim is against).
        refs = sort([String(k) for k in keys(p)
                     if endswith(String(k), "_version") &&
                        !(String(k) in ("r_version", "network_version"))])
        push!(out, (name = g.name,
                    file = f,
                    refs = join(["`$(replace(k, "_version" => ""))` $(p[k])" for k in refs], ", "),
                    r = get(p, "r_version", "?"),
                    dataset = scale_of(get(p, "dataset", "")),
                    script = get(p, "script", "")))
    end
    return out
end

# ---------------------------------------------------------------------------
# Run the probes
# ---------------------------------------------------------------------------

struct ProbeRow
    pkg::String
    what::String
    md::Union{Networks.ResultMetadata, Nothing}
    fit::Any
end

function run_probes()
    rows = ProbeRow[]
    for (pkg, what, thunk) in PROBES
        println(stderr, "Capability probe: $pkg — $what")
        fit = thunk()  # A failed probe must fail the gate, not become a page row.
        push!(rows, ProbeRow(pkg, what, fit_metadata(fit), fit))
    end
    return rows
end

sym(x) = x === :unspecified ? "—" : "`$x`"
yesno(b) = b ? "**yes**" : "no"

# ---------------------------------------------------------------------------
# Emit the Franklin page
# ---------------------------------------------------------------------------

function render(io::IO, rows::Vector{ProbeRow})
    println(io, """
    +++
    title = "Capability and parity matrix"
    +++

    # Capability and parity matrix

    ~~~
    <p class="lead">What every estimator in the ecosystem actually does — the objective it
    maximises, whether that objective is exact for the model at hand, where its standard
    errors come from, what it does with unobserved dyads and tied events, and whether any
    of it has been checked against R.</p>
    ~~~

    > **This page is generated, not written.** `tools/generate_capability_matrix.jl` fits a
    > small model of every family and asks the fitted result what it did, through the shared
    > result-metadata protocol (`Networks.fit_metadata`); it reads the "validated against R"
    > rows out of the `[provenance]` block of the golden fixtures committed in the package
    > repositories; and it reads the `Networks.supports_missing` and
    > `Networks.missing_policies` traits. The StatsAPI table executes the accessors on those
    > same fits. CI rejects failed probes and checks the page for drift. These small probes
    > establish the reported API behavior, not general scientific validity or scalability.

    ## How to read the columns

    - **objective** — what was actually maximised, *not* what the model is named after:
      `likelihood`, `pseudolikelihood`, `conditional_pseudolikelihood`, `mc_likelihood`,
      `moment` (method of moments / Robbins–Monro), `partial_likelihood`, `least_squares`.
    - **exact?** — whether that objective coincides with the exact likelihood **for this
      particular model**. This is deliberately a property of the *fit*, not of the
      estimator: maximum pseudo-likelihood of a dyad-independent formula **is** maximum
      likelihood; of a dyad-dependent one it is a different estimator with
      anticonservative standard errors. That contrast is the most important thing on this
      page, so the ERGM-family rows below come in pairs.
    - **standard errors** — `hessian` (inverse observed information; for a
      pseudo-likelihood under dependence this is generally **anticonservative**, i.e. too
      small), `fisher`, `sandwich`, `bootstrap`, or `none`.
    - **missing / ties** — how unobserved dyads and tied event times were treated by *this*
      fit. `rejected` means the routine refuses masked data rather than reading it at face
      value.

    ## Fitted-estimator status
    """)

    println(io, "| package | fit | estimand | objective | exact? | standard errors | missing dyads | tied events |")
    println(io, "|:---|:---|:---|:---|:---:|:---|:---|:---|")
    for r in rows
        m = r.md
        ties = m.tie_method === :not_applicable ? "n/a" : "`$(m.tie_method)`"
        println(io, "| $(r.pkg) | $(r.what) | $(sym(m.estimand)) | $(sym(m.objective)) | ",
                yesno(m.is_exact), " | $(sym(m.se_method)) | $(sym(m.missing_method)) | $ties |")
    end

    println(io, """

    Two rows are worth a second look, because they are exactly what a hand-written table
    would have got wrong:

    - **`ERGMCount`'s dyad-independent fit is still not exact.** Dyad independence is not
      enough here: the Poisson reference has unbounded support and the fit enumerates a
      truncated one, so it reports `exact? = no` and tells you the boundary mass it is
      leaning on ($(issue("ERGMCount", 1))).
    - **`ERGMRank` offers two estimators.** The default swap-MPLE multiplies overlapping
      comparisons and is not an exact likelihood. `method=:mcmle` fits the ranking ERGM
      by Monte Carlo likelihood; its simulation and convergence caveats remain relevant.

    You can ask the same question of your own fit:

    ```julia
    using Networks, ERGM
    net = load_dataset(:florentine_marriage)
    fit = ergm(net, [Edges(), GWESP(0.5)])
    md = fit_metadata(fit)
    md.objective      # :pseudolikelihood
    md.is_exact       # false — the formula is dyad-dependent
    md.se_method      # :hessian, therefore anticonservative here
    md.approximations # the caveats below, attached to the object
    ```

    ## The caveats the fits declare about themselves

    These are not editorial. Each line is an entry of `approximations(fit)` on the
    corresponding row above — attached to the fitted object, printed by its `show` method,
    and reproduced here verbatim.
    """)

    for r in rows
        (r.md === nothing || isempty(r.md.approximations)) && continue
        println(io, "#### $(r.pkg) — $(r.what)\n")
        for a in r.md.approximations
            println(io, "- ", a)
        end
        println(io)
    end

    clean = [r for r in rows if r.md !== nothing && isempty(r.md.approximations)]
    if !isempty(clean)
        println(io, """
        #### Fits that declare no approximation at all

        | package | fit | why there is nothing to declare |
        |:---|:---|:---|""")
        for r in clean
            println(io, "| $(r.pkg) | $(r.what) | ",
                    r.md.is_exact ?
                        "the objective **is** the exact likelihood of this model" :
                        "no further caveat is declared by the package",
                    " |")
        end
        println(io)
    end

    # --- validation
    println(io, """
    ## Validation against the reference implementations

    A row exists here only if a golden fixture exists in the package repository: a frozen
    set of numbers produced by the R implementation, together with the script that produced
    them, the R and package versions, and the seed. **No fixture, no claim.** The dataset
    column is the scale that has actually been validated — not a claim about the scale the
    code will run at.
    """)
    println(io, "| package | fixture | reference implementation | R | validated on |")
    println(io, "|:---|:---|:---|:---|:---|")
    for pkg in PACKAGES
        fx = fixtures_for(pkg)
        if isempty(fx)
            println(io, "| $pkg | — | *no golden fixture* | | |")
        else
            for f in fx
                println(io, "| $pkg | `$(f.name)` | $(f.refs) | $(f.r) | $(f.dataset) |")
            end
        end
    end

    println(io, """

    Fixtures can compare different estimators or document residual differences. Read the
    fixture's assertions and tolerances before treating a listed reference as equivalence.

    ## Shared result accessors

    Each cell below comes from calling the accessor on the same fitted object used above.
    `yes` means the call returned; `NaN` means a scalar criterion is explicitly unavailable;
    `—` means the call is unsupported. For moment estimators and pseudo-likelihoods,
    a returned AIC/BIC is not evidence that ordinary likelihood comparisons are justified.
    """)
    accessors = [:coef, :stderror, :vcov, :confint, :loglikelihood, :nobs, :dof, :aic, :bic, :coeftable]
    println(io, "| package | fit | ", join(["`$f`" for f in accessors], " | "), " |")
    println(io, "|:---|:---|", join(fill(":---:", length(accessors)), "|"), "|")
    for r in rows
        cells = String[]
        for key in accessors
            f = getproperty(Networks.StatsAPI, key)
            status = try
                value = f(r.fit)
                value isa Real && isnan(value) ? "NaN" : "yes"
            catch err
                err isa Union{MethodError, ArgumentError} || rethrow()
                "—"
            end
            push!(cells, status)
        end
        println(io, "| $(r.pkg) | $(r.what) | ", join(cells, " | "), " |")
    end

    println(io, """

    ## Missing-data support

    A masked dyad is unobserved, not absent. The first column reports the
    `supports_missing` declaration verbatim; the second reports `missing_policies(f)`.
    A true trait alone does not say whether a routine excludes, conditions on, or refuses
    a mask: read the accepted policies and the routine documentation. `:error` alone
    promises rejection and may mean there is no `missing=` keyword. `:face` uses stored
    values; `:condition_on_face` fixes them during MCMC. Neither is missing-data MLE.
    ERGM's `:mle` instead integrates missing ties with free and constrained chains;
    inspect convergence and Monte Carlo diagnostics for that fit.
    """)
    println(io, "| package | routine | `supports_missing` | accepted `missing` policies |")
    println(io, "|:---|:---|:---:|:---|")
    for (pkg, name, f) in ROUTINES
        policies = join(["`:$p`" for p in Networks.missing_policies(f)], ", ")
        println(io, "| $pkg | $name | `$(Networks.supports_missing(f))` | $policies |")
    end

    println(io, """

    ## Scientific limitations

    ### Siena convergence and inference

    `siena07` uses simulated method of moments. It rejects an unconverged fit by default;
    `siena_algorithm(allow_unconverged=true)` explicitly returns a diagnostic fit with a
    warning. Inspect `converged`, every t-ratio, `tconv_max`, `derivative_matrix`, and
    `phase3_cov`; repeat independent seeds and assess goodness of fit before inference.
    Convergence requires every absolute t-ratio below 0.1 and `tconv_max` below 0.25.
    Newton refinement improves convergence, but a passing diagnostic does not establish
    equivalence to RSiena across models, effects, or datasets. Maximum-likelihood and
    Bayesian estimation remain unsupported; structural zeros/ones are not missing ties.

    ### Rank and other pseudo-likelihood estimators

    ERGMRank's default swap-MPLE is a different objective from ranking MCMC-MLE. Use
    `method=:mcmle` for the latter and inspect convergence and Monte Carlo diagnostics.
    Dependent ERGM-family pseudo-likelihood Hessian errors can underestimate uncertainty.
    Where offered, `se=:bootstrap` changes the covariance, not the objective or consistency
    properties. Check each routine's documentation; this option is not universal.

    ### REM risk sets and uncertainty

    Declare the complete eligible actor universe, including nonparticipants. Omitting
    eligible actors changes the risk set and the estimand. Under a correctly specified
    nested case-control model, the sampled likelihood's Hessian already accounts for the
    information lost by sampling controls. `se=:sandwich` uses event-clustered scores for
    robustness to within-stratum misspecification; it does not establish robustness to
    arbitrary dependence between events. REM rejects `se=:bootstrap`. `control_draw_cov`
    measures sensitivity to control redraws and must not be added to the fitted covariance
    as a supposed missing variance component.

    ### Relevent timing and effect coverage

    Ordinal models condition on event order; timing models assume piecewise exponential
    waiting times and require statistics constant between events. `fit_timing` rejects
    finite-half-life decay statistics because their integrated hazard is not implemented;
    these statistics remain available for ordinal/conditional fits. Cumulative-history
    variants with `halflife=Inf` are interval-constant. For timing fits, `coef`,
    `stderror`, `vcov` and `coeftable` include the
    log-baseline first, followed by the effects. The legacy `.coefficients` and
    `.std_errors` fields contain effects only. Choose tie handling explicitly where times
    coincide. Time-varying covariate arrays and Bayesian fitting are unsupported.

    Both fitters reject a verified separating direction: the likelihood keeps improving
    toward an infinite coefficient, so no finite maximum-likelihood estimate exists.
    This check does not detect every boundary case; inspect convergence and uncertainty.

    ### Count support and egocentric survey designs

    Poisson/geometric count ERGMs enumerate a finite support. Adaptive doubling checks
    coefficient movement in standard-error units, omitted tail mass and boundary mass;
    this controls a numerical approximation and does not make infinite support exact.
    Inspect the fitted support diagnostics. Egocentric inference assumes independent egos
    with supplied case weights. Strata, clusters, replicate weights and richer inclusion
    designs require additional survey-design variance treatment.

    ### Temporal models and observation

    TERGM fits formation and persistence by CMPLE, exact for dyad-independent formulas.
    `method=:cmle` and `TERGM.egmme` throw; dependent CMLE and EGMME are unavailable.
    TSNA uses active-vertex density and dyadic reciprocity by default. Its temporal
    analyses reject masks unless `missing=:face` is explicit; face values cannot recover
    unobserved histories. Conversions preserve representable masks and reject incompatible
    encodings: Siena structural masks describe determined ties, not unobserved ties.

    ### Scope and installation

    These tables cover small fitted models and selected missing-data policies. They do
    not validate every descriptive measure, simulation, visualization, or scale. The
    [migration guide](/migration/) describes current API differences. The published
    [workspace recipe](https://github.com/$ORG/$ORG.github.io/tree/main/tools/workspace)
    reconstructs sibling checkouts. A passing local snapshot installation check does not
    establish registry publication or the availability of unpushed changes.
    """)
    return nothing
end

# ---------------------------------------------------------------------------
# main — write, or check freshness
# ---------------------------------------------------------------------------

# The categorical columns of this page (objective, exactness, SE method, missing
# and tie policy, which fixtures exist, which reference they pin against) are
# deterministic. A handful of the self-declared caveats quote a *number* the fit
# measured — a boundary mass, a case-control inclusion probability, a Monte-Carlo
# convergence statistic — and those can move in the last digits with the Julia
# version or the thread count even under a fixed seed. So the freshness check
# compares the page with numeric literals masked out: it catches structural
# drift (an estimator that changed its objective, a caveat that appeared or
# disappeared, a fixture that was added or lost) and does not fail CI over
# Monte-Carlo jitter in a quoted quantity.
function normalize(s)
    # Only self-reported fit caveats contain Monte Carlo quantities. Keep fixture
    # versions, data scales, scientific thresholds, and executable examples exact.
    start = findfirst("## The caveats the fits declare about themselves", s)
    stop = findfirst("## Validation against the reference implementations", s)
    (start === nothing || stop === nothing) && return s
    before = s[begin:prevind(s, first(start))]
    caveats = s[first(start):prevind(s, first(stop))]
    after = s[first(stop):end]
    return before * replace(caveats, r"-?\d+\.?\d*(?:[eE][-+]?\d+)?" => "#") * after
end

function main()
    check = "--check" in ARGS
    outarg = findfirst(a -> startswith(a, "--out="), ARGS)
    out = outarg === nothing ? PAGE : ARGS[outarg][7:end]

    buf = IOBuffer()
    render(buf, run_probes())
    text = String(take!(buf))

    if check
        isfile(PAGE) || (println(stderr, "capability matrix: $PAGE does not exist — run the generator"); exit(1))
        committed = read(PAGE, String)
        if normalize(committed) == normalize(text)
            println("capability matrix: $(basename(PAGE)) is up to date with the code.")
            exit(0)
        end
        println(stderr, """
            capability matrix: $(basename(PAGE)) is STALE.

            The committed page no longer matches what the code reports. Regenerate it:

                julia --project=. $(relpath(@__FILE__, ROOT))

            and commit the result. (Numeric literals are masked before comparison, so this
            failure is a structural change — an objective, an exactness verdict, a standard-error
            method, a declared caveat, or a golden fixture — not Monte-Carlo jitter.)
            """)
        # A short diff of the first differing lines, to say what moved.
        a, b = split(normalize(committed), '\n'), split(normalize(text), '\n')
        shown = 0
        for i in 1:max(length(a), length(b))
            ai = i <= length(a) ? a[i] : "<missing>"
            bi = i <= length(b) ? b[i] : "<missing>"
            ai == bi && continue
            println(stderr, "  line $i:\n    committed: $ai\n    generated: $bi")
            (shown += 1) >= 10 && (println(stderr, "  ..."); break)
        end
        exit(1)
    end

    write(out, text)
    println("capability matrix: wrote $out ($(count(==('\n'), text)) lines)")
    return nothing
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
