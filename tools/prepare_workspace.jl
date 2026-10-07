#!/usr/bin/env julia
# Reconstruct the published sibling layout and its executable-docs environment.
using Pkg
using TOML

function main(args)
    usage = "Usage: julia tools/prepare_workspace.jl ROOT [--clone | --clone-only]"
    length(args) in (1, 2) || error(usage)
    option = length(args) == 2 ? args[2] : ""
    option in ("", "--clone", "--clone-only") || error("Unknown option: $option\n$usage")
    # --clone-only fetches the checkouts and stops before building .snippet-env,
    # for checks that read the repositories rather than load the packages.
    clone = option in ("--clone", "--clone-only")
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
    if option == "--clone-only"
        println("Checkouts ready: ", join(sort!(collect(keys(paths))), ", "))
        return
    end
    Pkg.activate(joinpath(root, ".snippet-env"))
    # A package retired from the workspace (Relevent.jl, merged into Revel.jl)
    # may still have a checkout beside the others; drop it from an existing
    # environment, or it would be loaded beside the package that replaced it.
    retired = sort!([name for name in keys(Pkg.project().dependencies)
                     if !haskey(paths, name) && isdir(joinpath(root, "$name.jl"))])
    isempty(retired) || Pkg.rm(retired)
    # Resolve all unregistered siblings together; alphabetical one-by-one develop fails
    # when a package refers to a sibling not yet known to the resolver.
    Pkg.develop([Pkg.PackageSpec(path=paths[name]) for name in sort!(collect(keys(paths)))])
    Pkg.add(["CSV", "DataFrames", "Distributions", "Graphs", "StatsAPI", "StatsBase"])
    # Re-read every developed package's Project.toml: a checkout that gained a
    # dependency since the last run would otherwise fail to precompile against
    # the old Manifest.
    Pkg.resolve()
    Pkg.instantiate()
    println("Workspace ready: julia --project=$(joinpath(root, ".snippet-env"))")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS)
end
