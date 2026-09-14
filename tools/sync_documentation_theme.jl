#!/usr/bin/env julia
# Copy the canonical theme into independent package documentation sites.
using TOML

function main(args)
    unknown = filter(arg -> startswith(arg, "--") && arg != "--check", args)
    isempty(unknown) || error("Unknown option(s): $(join(unknown, ", "))")
    roots = filter(arg -> !startswith(arg, "--"), args)
    length(roots) <= 1 || error("Usage: julia tools/sync_documentation_theme.jl [WORKSPACE] [--check]")
    root = isempty(roots) ? normpath(joinpath(@__DIR__, "..", "..")) : abspath(only(roots))
    check = "--check" in args
    project = TOML.parsefile(joinpath(@__DIR__, "workspace", "Project.toml"))
    names = sort!(collect(keys(project["sources"])))
    files = ("snwj-docs.css", "snwj-docs.js")
    # Validate all destinations before copying so a missing sibling fails cleanly.
    for name in names
        isdir(joinpath(root, "$name.jl", "docs", "src")) || error("Missing documentation source: $name.jl")
    end
    mismatches = String[]
    for name in names, file in files
        source = joinpath(@__DIR__, "docs-theme", file)
        target = joinpath(root, "$name.jl", "docs", "src", "assets", file)
        if check
            if !isfile(target) || read(source) != read(target)
                push!(mismatches, relpath(target, root))
            end
        else
            mkpath(dirname(target))
            cp(source, target; force=true)
        end
    end
    isempty(mismatches) || error("Theme copies differ; run sync_documentation_theme.jl:\n" * join(mismatches, '\n'))
    println(check ? "Theme copies match in all $(length(names)) packages." : "Theme assets synced to $(length(names)) independent package sites.")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS)
end
