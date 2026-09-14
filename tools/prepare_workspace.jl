#!/usr/bin/env julia
# Reconstruct the published sibling layout and its executable-docs environment.
using Pkg
using TOML

function main(args)
    length(args) in (1, 2) || error("Usage: julia tools/prepare_workspace.jl ROOT [--clone]")
    clone = length(args) == 2 && args[2] == "--clone"
    length(args) == 1 || clone || error("Unknown option: $(args[2])")
    root = abspath(args[1])
    mkpath(root)
    template = TOML.parsefile(joinpath(@__DIR__, "workspace", "Project.toml"))
    sources = template["sources"]
    queue = sort!(collect(keys(sources)))
    paths = Dict{String,String}()
    while !isempty(queue)
        name = popfirst!(queue)
        haskey(paths, name) && continue
        path = joinpath(root, "$name.jl")
        if !isdir(path)
            clone || error("Missing $path; pass --clone to fetch the sibling repositories")
            run(`git clone --depth=1 https://github.com/statistical-network-analysis-with-Julia/$name.jl $path`)
        end
        project = TOML.parsefile(joinpath(path, "Project.toml"))
        project["name"] == name || error("Unexpected package in $path")
        paths[name] = path
        # Follow local source declarations, including newly added package dependencies.
        for (dep, source) in get(project, "sources", Dict())
            haskey(source, "path") || continue
            dependency = normpath(joinpath(path, source["path"]))
            dependency == joinpath(root, "$dep.jl") || error("Unsupported sibling source for $dep in $path")
            haskey(paths, dep) || push!(queue, dep)
        end
    end
    Pkg.activate(joinpath(root, ".snippet-env"))
    # Resolve all unregistered siblings together; alphabetical one-by-one develop fails
    # when a package refers to a sibling not yet known to the resolver.
    Pkg.develop([Pkg.PackageSpec(path=paths[name]) for name in sort!(collect(keys(paths)))])
    Pkg.add(["CSV", "DataFrames", "Distributions", "Graphs", "StatsAPI", "StatsBase"])
    Pkg.instantiate()
    println("Workspace ready: julia --project=$(joinpath(root, ".snippet-env"))")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS)
end
