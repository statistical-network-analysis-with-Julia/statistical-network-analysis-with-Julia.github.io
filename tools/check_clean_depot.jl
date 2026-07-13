# Clean-depot installation check (site issue #3).
#
# > "External URL installation remains order-sensitive because packages are
# >  unregistered and rely on sibling/path source metadata during development.
# >  Add CI that installs released metadata into an empty depot without sibling
# >  checkouts."
#
# The hazard this catches: every package's Project.toml carries a `[sources]`
# section pointing at a sibling checkout (`path = "../Networks.jl"`). That is
# what makes monorepo development work — and it is exactly what makes the
# packages *look* installable when they are not. In the monorepo the sibling is
# always there, so nothing ever exercises the path a real user takes. A package
# can be missing a dependency, or declare an unsatisfiable compat bound, and
# every local test will still pass.
#
# So this script installs into a FRESH, EMPTY DEPOT with no sibling directories
# on the path, in the registry's release order, and loads each package. It fails
# on the first package that cannot be installed or loaded.
#
# Usage:
#
#   julia tools/check_clean_depot.jl                # from the local checkouts
#   julia tools/check_clean_depot.jl --registry=... # from a registry (post-release)
#
# The `--registry` form is the one that matters once the packages are registered:
# it resolves purely from released metadata, with no path dependencies at all.

using Pkg

const SITE = normpath(joinpath(@__DIR__, ".."))
const ROOT = normpath(get(ENV, "SNWJ_ROOT", joinpath(SITE, "..")))

# Topological order: every package after all of its local dependencies. Kept in
# step with `setup_registry.jl` — if these two disagree, the release is wrong.
const ORDER = [
    "Networks",         # foundation: no local deps
    "NetworkDynamic",   # ← Networks
    "SNA",              # ← Networks
    "ERGM",             # ← Networks
    "Siena",            # ← Networks (extension)
    "REM",              # ← Networks (+ NetworkDynamic weakdep)
    "Relevent",         # ← Networks, REM
    "NDTV",             # ← Networks, NetworkDynamic
    "TSNA",             # ← Networks, NetworkDynamic, SNA
    "TERGM",            # ← Networks, ERGM
    "ERGMCount",        # ← Networks, ERGM
    "ERGMEgo",          # ← Networks, ERGM
    "ERGMMulti",        # ← Networks, ERGM
    "ERGMRank",         # ← Networks, ERGM
    "ERGMUserterms",    # ← Networks, ERGM
]

registry = nothing
for a in ARGS
    startswith(a, "--registry=") && (registry = split(a, "=", limit = 2)[2])
end

depot = mktempdir(; prefix = "snwj-clean-depot-")
project = mktempdir(; prefix = "snwj-clean-project-")
@info "clean depot" depot project registry

# An EMPTY depot: nothing precompiled, nothing cached, no sibling checkouts.
withenv("JULIA_DEPOT_PATH" => depot,
        "JULIA_PKG_SERVER" => get(ENV, "JULIA_PKG_SERVER", "")) do
    Pkg.activate(project)
    if registry !== nothing
        Pkg.Registry.add(Pkg.RegistrySpec(url = registry))
        Pkg.Registry.add("General")
    end

    failed = String[]
    for pkg in ORDER
        try
            if registry === nothing
                # Pre-registration: install from the local checkout. This still
                # exercises the real thing — a fresh depot with no siblings — but
                # `[sources]` path deps are resolved relative to the checkout, so
                # it cannot prove registry-installability. That is what
                # `--registry` is for.
                Pkg.develop(path = joinpath(ROOT, "$pkg.jl"))
            else
                Pkg.add(pkg)
            end
            # Installing is not the check. LOADING is: a missing dependency or a
            # broken extension only shows up at `using` time.
            Base.eval(Main, :(using $(Symbol(pkg))))
            @info "ok" pkg
        catch e
            @error "FAILED" pkg exception = (e, catch_backtrace())
            push!(failed, pkg)
            break   # stop at the first failure: the order is topological, so
                    # everything after it would fail for a downstream reason
        end
    end

    if isempty(failed)
        @info "all $(length(ORDER)) packages installed and loaded in a clean depot"
    else
        @error "clean-depot install FAILED" failed
        exit(1)
    end
end
