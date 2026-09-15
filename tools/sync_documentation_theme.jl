#!/usr/bin/env julia
# Sync package icons. Documenter supplies the documentation themes unchanged.
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
    files = ("svg" => "logo.svg", "ico" => "favicon.ico")
    retired = ("snwj-docs.css", "snwj-docs.js")
    # Validate all destinations before copying so a missing sibling fails cleanly.
    for name in names
        isdir(joinpath(root, "$name.jl", "docs", "src")) || error("Missing documentation source: $name.jl")
        for (extension, _) in files
            isfile(joinpath(@__DIR__, "docs-theme", "icons", "$name.$extension")) || error("Missing icon: $name.$extension")
        end
    end
    mismatches = String[]
    for name in names
        assets = joinpath(root, "$name.jl", "docs", "src", "assets")
        for (extension, file) in files
            source = joinpath(@__DIR__, "docs-theme", "icons", "$name.$extension")
            target = joinpath(assets, file)
            if check
                if !isfile(target) || read(source) != read(target)
                    push!(mismatches, relpath(target, root))
                end
            else
                mkpath(assets)
                cp(source, target; force=true)
            end
        end
        for file in retired
            target = joinpath(assets, file)
            isfile(target) || continue
            check ? push!(mismatches, "Retired theme asset: $(relpath(target, root))") : rm(target)
        end
        makefile = joinpath(root, "$name.jl", "docs", "make.jl")
        config = read(makefile, String)
        if any(file -> occursin(file, config), retired) || !occursin("assets/favicon.ico", config)
            push!(mismatches, "$(relpath(makefile, root)): use assets = [\"assets/favicon.ico\"] with the native Documenter themes")
        end
    end
    isempty(mismatches) || error("Documentation assets need updating:\n" * join(mismatches, '\n'))
    println(check ? "Icons match and retired theme assets are absent in all $(length(names)) packages." : "Icons synced to $(length(names)) independent package sites using native Documenter themes.")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS)
end
