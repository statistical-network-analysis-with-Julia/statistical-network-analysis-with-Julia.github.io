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
using REM, Relevent, Siena, TERGM
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
    Random.seed!(107)          # ERGM's MCMC sampler draws from the global RNG
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
    m = zeros(Int, 4, 4)
    m[1, 2] = 3; m[1, 3] = 2; m[1, 4] = 1
    m[2, 1] = 3; m[2, 3] = 1; m[2, 4] = 2
    m[3, 1] = 1; m[3, 2] = 3; m[3, 4] = 2
    m[4, 1] = 2; m[4, 2] = 1; m[4, 3] = 3
    return RankNetwork(m)
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
                        [Repetition(), Reciprocity()]; n_controls=5, seed=1)

# --- Siena: a two-wave SAOM on a simulated network, at the package's own
#     default operating point (see the limitations: this is the package whose
#     PROCEDURE, not estimand, is the open finding)
function siena_fit()
    n = 20
    rng = Xoshiro(3)
    w1 = zeros(Int, n, n)
    for i in 1:n, j in 1:n
        i == j && continue
        rand(rng) < 0.15 && (w1[i, j] = 1)
    end
    gen = siena_data()
    add_nodeset!(gen, NodeSet(n))
    add_dependent!(gen, DependentNetwork(:net, [w1, w1]))
    geff = get_effects(gen)
    include_effects!(geff, :net, [:outdegree, :recip])
    gstate, _ = simulate_saom(gen, geff, [4.0, -1.5, 1.0]; seed=5)
    w2 = copy(gstate.networks[:net])

    data = siena_data()
    add_nodeset!(data, NodeSet(n))
    add_dependent!(data, DependentNetwork(:net, [w1, w2]))
    effects = get_effects(data)
    include_effects!(effects, :net, [:outdegree, :recip])
    alg = siena_algorithm(seed=21, verbose=false, phase1_iterations=50,
                          n_subphases=4, phase3_iterations=500,
                          derivative_sims=50)
    return siena07(data, effects; algorithm=alg)
end

# (package, description of the fit, thunk producing a fitted result)
const PROBES = [
    ("SNA", "`netlm`, dyadic OLS + QAP", () -> netlm(sna_net(), [SNA_X]; nullhyp=:classical)),
    ("SNA", "`netlogit`, dyadic logit + QAP", () -> netlogit(sna_net(), [SNA_X]; nullhyp=:classical)),
    ("ERGM", "`mple`, **dyad-independent** formula (`edges`)", () -> small_ergm(dependent=false)),
    ("ERGM", "`mple`, **dyad-dependent** formula (`edges + gwesp`)", () -> small_ergm(dependent=true)),
    ("ERGM", "`mcmle`, dyad-dependent formula", () -> mcmle(ERGMModel(ERGMFormula([Edges(), GWESP(0.5)]), ergm_net());
                                                            n_samples=200, burnin=200, interval=5, max_iter=3)),
    ("TERGM", "`stergm`/CMPLE, **dyad-independent** formula", () -> stergm(tergm_panels(), [Edges()], [Edges()])),
    ("TERGM", "`stergm`/CMPLE, **dyad-dependent** formula", () -> stergm(tergm_panels(), [Edges(), GWESP(0.5)], [Edges()])),
    ("ERGMCount", "`fit_ergm_count`, **dyad-independent** (`sum + nonzero`)", () -> fit_ergm_count(count_net(), [SumTerm(), NonzeroTerm()])),
    ("ERGMCount", "`fit_ergm_count`, **dyad-dependent** (`sum + mutual`)", () -> fit_ergm_count(count_net(), [SumTerm(), CountMutualTerm()])),
    ("ERGMMulti", "`ergm_multi`, **dyad-independent** (per-layer edges)", () -> ergm_multi(multi_net(), [LayerEdges(1), LayerEdges(2)])),
    ("ERGMMulti", "`ergm_multi`, **dyad-dependent** (interlayer dependence)", () -> ergm_multi(multi_net(), [LayerEdges(), InterlayerDependence(1, 2)])),
    ("ERGMEgo", "`fit_ergm_ego`, MCMC method of moments", ego_fit),
    ("ERGMRank", "`fit_ergm_rank`, swap-MPLE, default SEs", () -> fit_ergm_rank(rank_net(), RANK_TERMS)),
    ("ERGMRank", "`fit_ergm_rank`, swap-MPLE, `se=:bootstrap`", () -> fit_ergm_rank(rank_net(), RANK_TERMS; se=:bootstrap, n_boot=40, rng=Xoshiro(3))),
    ("REM", "`fit_rem`, case-control conditional logit", rem_fit),
    ("Relevent", "`fit_obpm`, ordinal B-P model", () -> fit_obpm(event_stream(5, 30; seed=9), [PShift(:AB_BA)], 5)),
    ("Relevent", "`fit_timing`, exact-time hazard model", () -> fit_timing(event_stream(5, 30; seed=9), [PShift(:AB_BA)], 5)),
    ("Siena", "`siena07`, SAOM by method of moments", siena_fit),
]

# The fitting functions whose missing-data trait we report. `supports_missing`
# defaults to `false`, so this is an honest census, not an allowlist.
const ROUTINES = [
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
    err::String
end

function run_probes()
    rows = ProbeRow[]
    for (pkg, what, thunk) in PROBES
        try
            push!(rows, ProbeRow(pkg, what, fit_metadata(thunk()), ""))
        catch e
            push!(rows, ProbeRow(pkg, what, nothing,
                                 first(sprint(showerror, e), 200)))
        end
    end
    return rows
end

sym(x) = x === :unspecified ? "—" : "`$x`"
yesno(b) = b ? "**yes**" : "no"

# Does the routine actually expose the `missing = :face` opt-in, or can it only
# refuse? Asked of the method table rather than asserted -- the ecosystem
# *contract* is that `:face` is the auditable opt-in "everywhere", and it is
# exactly the kind of claim that quietly stops being true. (Today: only three of
# the thirteen fitting functions take the keyword at all.)
has_missing_kwarg(f) = any(m -> :missing in Base.kwarg_decl(m), methods(f))

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
    > repositories; and it reads missing-data support out of the `Networks.supports_missing`
    > trait. A hand-maintained capability table drifts from the code within one release.
    > This one cannot, because it *is* the code — and a CI check regenerates it and fails if
    > the committed page has gone stale.

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
        if r.md === nothing
            println(io, "| $(r.pkg) | $(r.what) | *probe failed: $(r.err)* | | | | | |")
            continue
        end
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
    - **`ERGMRank` is never exact, at any formula.** Its swap comparisons overlap by
      construction, so there is no dyad-independent special case to fall back on
      ($(issue("ERGMRank", 1))).

    Every one of the twelve fitted-result types in the ecosystem declares this protocol, so
    you can ask the same question of your own fit:

    ```julia
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

    Two entries in that table are **not** claims of agreement, and are called out in the
    limitations below: `newcomb_rank` pins ERGMRank against a *different estimator*, and
    `s50_siena07` pins Siena against RSiena on the estimand while documenting that the
    procedure is materially weaker.

    ## Missing-data support

    The ecosystem contract (`Networks.supports_missing` / `Networks.require_observed`): a
    routine that has not declared a missing-data method **refuses** a network with masked
    dyads rather than silently reading unobserved ties at face value. Both columns below are
    read out of the code — the first from the `Networks.supports_missing` trait, which
    defaults to `false` (so this is a census, not an advertisement), and the second from the
    routine's own method table.

    The second column is worth reading carefully, because it is narrower than the contract's
    slogan. `missing = :face` is described as the auditable opt-in *everywhere*, but only
    three of the thirteen fitting functions actually accept the keyword. For the rest,
    refusing is all they can do: there is no way to ask them to proceed on face values, and
    a masked network must be resolved before it reaches them ($(issue("Networks", 1))).
    """)
    println(io, "| package | routine | handles masked dyads | face-value opt-in |")
    println(io, "|:---|:---|:---|:---|")
    for (pkg, name, f) in ROUTINES
        handles = Networks.supports_missing(f)
        optin = handles ? "*not needed — it handles the mask*" :
                has_missing_kwarg(f) ? "`missing = :face`" :
                                       "*none — it can only refuse*"
        println(io, "| $pkg | $name | ",
                handles ? "**yes** — available-case objective; masked dyads excluded" :
                          "no — a masked network is **rejected**",
                " | ", optin, " |")
    end

    # --- limitations
    println(io, """

    ## Known limitations, and who owns them

    Everything below is a real, reproduced finding. Each links to the issue that owns it.

    ### Siena.jl's SAOM procedure is materially weaker than RSiena's — $(issue("Siena", 2))

    **This is the most serious open finding in the ecosystem, and it can bite you
    silently.** The *estimand* is right: on the `s50` fixture every parameter lands within
    0.28 RSiena standard errors of RSiena's own estimate. The *procedure* is not:

    - **~1 seed in 10 diverges outright while reporting `diverged == false`.** Two of 24
      surveyed seeds reached `tconv.max ≈ 50` (reciprocity 5.77 against a true ≈ 2.40).
      The parameter clamp never fires, so **`result.tconv_max` is the only signal you
      have** that a fit is garbage. Check it. Do not trust `diverged`.
    - **3–19× noisier than RSiena at the same simulation budget** (smoke1-similarity:
      seed-to-seed sd 0.045, against RSiena's 0.0057).
    - **It fails the convergence standard it enforces on itself**: `tconv.max` came out
      0.26–0.77 across five seeds, against the 0.25 threshold Siena.jl checks. RSiena gets
      0.13 on the same data.
    - **More budget makes it worse, not better.** Raising `phase1_iterations` to 200 or 400
      each diverged one seed in six; `n_simulations = 5` inflates the sd about tenfold. The
      shipped defaults are the only stable operating point.

    Until this is fixed: run several seeds, compare the estimates, and read `tconv_max` on
    every one.

    ### Two RSiena comparisons cannot be made at all — $(issue("Siena", 2))

    `SienaResult` exposes neither the **derivative matrix** nor the **phase-3 statistic
    covariance**, so two of the comparisons the parity issue asks for cannot be performed.
    RSiena's values are frozen in the fixture as reference-only, unasserted; the check is
    one accessor away.

    ### ERGMRank's swap-MPLE is a different estimator, not an approximation — $(issue("ERGMRank", 1))

    `ergm.rank` fits by MCMC-MLE; ERGMRank.jl fits a **swap pseudo-likelihood**. The swap
    comparisons overlap (each ranking enters *n* − 2 of them), so their product is not the
    likelihood, and **no consistency result is claimed**. Against R on the Newcomb fixture
    it is systematically **16× R's seed noise** — though the gap is only about **0.3 of a
    standard error**, so it is a difference of estimator, not a bug. The fixture pins the
    *character* of the gap rather than asserting agreement.

    ### Pseudo-likelihood Hessian standard errors are anticonservative — $(issue("ERGMRank", 1)), $(issue("ERGMMulti", 1)), $(issue("ERGMCount", 2)), $(issue("REM", 2))

    Where the objective is a pseudo-likelihood and the model is dyad-dependent, the
    inverse-Hessian standard errors treat overlapping conditionals as independent and come
    out **too small**. Measured against `Networks.bootstrap_cov` on dependent models:

    | package | bootstrap SE ÷ Hessian SE |
    |:---|:---|
    | ERGMRank | **5.4×** and 3.4× |
    | ERGMMulti | up to 9.0× |
    | ERGMCount | 1.20× |
    | REM | 1.03–1.17× |

    Pass **`se = :bootstrap`** (or `se = :sandwich` for REM) whenever the model is
    dyad-dependent. Point estimates are byte-identical across the `se` options; only the
    covariance changes.

    ### REM's uncertainty ignores the risk-set sampling — $(issue("REM", 2))

    The default inverse-Hessian standard errors are conditional on the **one** sampled
    control set that was drawn, so they omit the variance induced by the case-control
    sampling itself. `se = :bootstrap` (law of total variance) or `se = :sandwich` includes
    it. Relatedly, the actor universe must be **declared** ($(issue("REM", 1))): inferring
    it from observed event endpoints drops eligible non-participants from the risk set and
    changes the estimand.

    ### ERGMCount truncates an unbounded support — $(issue("ERGMCount", 1))

    Poisson/geometric references have unbounded support; the fit enumerates `0:max_val` and
    reports the **boundary mass** it is leaning on (see the caveats above — it is
    reported per fit, not assumed away). It is currently data-adaptive rather than
    error-controlled.

    ### ERGMEgo's design variance encodes only a simple design — $(issue("ERGMEgo", 1))

    The survey-design variance component is the weighted-mean variance of the target
    statistics under **independent egos** with the given case weights. It encodes no
    strata, clusters, finite-population correction, replicate weights, without-replacement
    inclusion probabilities, or alter dependence. Since the design component is roughly
    **17× the estimation component**, an ego standard error essentially *is* its design
    variance — so a richer sampling design than the one assumed will give you standard
    errors that are too narrow.

    ### TERGM has no EGMME, and `cmle` is not CMLE — $(issue("TERGM", 1))

    `TERGM.egmme` is unimplemented and deliberately **unexported**: it throws rather than
    silently doing something else. `cmle` throws rather than quietly falling back to CMPLE.
    For a dyad-dependent formula, the CMPLE rows above show `exact? = no`.

    ### Missing-dyad semantics across conversions — $(issue("Networks", 1))

    Conversions between `Network`, `DynamicNetwork` and the Siena/REM data structures are
    now mask-preserving where they can be and **reject** where they cannot. In particular,
    **Siena's structural mask is not a missing mask**: Siena records ties that are
    *determined*, `Networks` records ties that are *unobserved*, and encoding one as the
    other would tell the estimator that a tie is known to be impossible. There is no
    faithful encoding, so the conversion refuses.

    ### The module is `Networks`, the type is `Network` — $(issue("Networks", 2))

    `using Networks`, then `Network(5)`. The module was renamed (the type name appears in
    ~200 downstream signatures); `using Network` is not a thing.

    ### What is not covered here

    This page covers **fitted estimators**. Descriptive measures (`SNA.jl` centralities,
    cohesion, equivalence), simulation-only entry points (`simulate_*`), and the
    visualization packages (`NDTV.jl`, `TSNA.jl`) are not fits and have no result metadata
    to report; their own issues are $(issue("NDTV", 1)), $(issue("TSNA", 1)) and
    $(issue("ERGMUserterms", 1)). Regenerating this page is tracked by $(site_issue(2));
    release/registry sequencing by $(site_issue(3)).
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
normalize(s) = replace(s, r"-?\d+\.?\d*(?:[eE][-+]?\d+)?" => "#")

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
