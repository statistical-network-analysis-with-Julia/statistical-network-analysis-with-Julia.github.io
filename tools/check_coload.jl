#!/usr/bin/env julia
# Load every package of the ecosystem into one session and check the property
# the shared contracts exist for: a name exported by several packages is the
# same binding in each (otherwise `using A, B` leaves it undefined), and no two
# methods across the packages are ambiguous.
#
#   julia --project=../.snippet-env tools/check_coload.jl
#
# Run it in the environment tools/prepare_workspace.jl builds. The package list
# is tools/workspace/Project.toml.
using Test
using TOML

const PACKAGES = sort!(collect(keys(TOML.parsefile(joinpath(@__DIR__, "workspace", "Project.toml"))["deps"])))

function load_all()
    for name in PACKAGES
        Core.eval(Main, :(using $(Symbol(name))))
    end
end

# Run in the world the packages were loaded into (call through invokelatest).
function main()
    modules = [getfield(Main, Symbol(name)) for name in PACKAGES]
    owners = Dict{Symbol,Vector{Tuple{Module,Any}}}()
    for m in modules, n in names(m)
        # names() also lists `public` names; only exported ones meet under `using`
        n === nameof(m) && continue
        Base.isexported(m, n) && isdefined(m, n) || continue
        push!(get!(owners, n, Tuple{Module,Any}[]), (m, getfield(m, n)))
    end
    conflicts = String[]
    for (n, bound) in sort!(collect(owners); by=first)
        distinct = unique(x -> objectid(x[2]), bound)
        length(distinct) > 1 &&
            push!(conflicts, "$n is exported as different objects by " * join((nameof(m) for (m, _) in distinct), ", "))
    end
    ambiguities = Test.detect_ambiguities(modules...; recursive=false)
    println("Loaded $(length(modules)) packages: ", join(PACKAGES, ", "))
    println("Distinct exported names: ", length(owners))
    println("Names bound to different objects: ", length(conflicts))
    foreach(c -> println("  ", c), conflicts)
    println("Method ambiguities across the packages: ", length(ambiguities))
    for (a, b) in ambiguities
        println("  ", a.module, ".", a.name, " :: ", a.sig, "\n    vs ", b.module, ".", b.name, " :: ", b.sig)
    end
    summary = get(ENV, "GITHUB_STEP_SUMMARY", "")
    isempty(summary) || open(summary, "a") do io
        println(io, "### Co-loading $(length(modules)) packages\n")
        println(io, "| Check | Count |\n|:---|---:|")
        println(io, "| Distinct exported names | $(length(owners)) |")
        println(io, "| Names bound to different objects | $(length(conflicts)) |")
        println(io, "| Method ambiguities | $(length(ambiguities)) |\n")
    end
    return isempty(conflicts) && isempty(ambiguities)
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    load_all()
    exit(Base.invokelatest(main) ? 0 : 1)
end
