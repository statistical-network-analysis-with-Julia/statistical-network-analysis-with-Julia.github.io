#!/usr/bin/env julia
# Install committed snapshots (default), working-tree snapshots, or registry
# releases in a NEW Julia process with a genuinely empty, isolated depot.
# Local snapshots are installed by Git URL, never developed from live siblings.
# Usage: julia tools/check_clean_depot.jl [--source=committed|working-tree]
#        [--registry=URL] [--package=Name] [--keep]
using Pkg
using TOML

const SITE = dirname(@__DIR__)
const ROOT = normpath(get(ENV, "SNWJ_ROOT", dirname(SITE)))

function package_order(root, selected; committed=false)
    projects = Dict{String,Any}()
    paths = Dict{String,String}()
    for path in readdir(root; join=true)
        isdir(path) || continue
        file = joinpath(path, "Project.toml")
        startswith(basename(path), ".") && continue
        project = if committed
            # A tracked project may be deleted only in the working tree. Its
            # committed package must still belong to the committed inventory.
            output = IOBuffer()
            success(pipeline(`git -C $path show HEAD:Project.toml`;
                             stdout=output, stderr=devnull)) || continue
            TOML.parse(String(take!(output)))
        else
            isfile(file) || continue
            TOML.parsefile(file)
        end
        haskey(project, "name") && haskey(project, "uuid") || continue
        name = project["name"]
        projects[name] = project
        paths[name] = path
    end
    isempty(projects) && error("No package projects found in $root")
    wanted = isempty(selected) ? sort(collect(keys(projects))) : selected
    order = String[]
    visiting = Set{String}()
    function visit(name)
        name in order && return
        haskey(projects, name) || error("Unknown package: $name")
        name in visiting && error("Local dependency cycle at $name")
        push!(visiting, name)
        for dep in sort(collect(keys(get(projects[name], "deps", Dict()))))
            haskey(projects, dep) && visit(dep)
        end
        delete!(visiting, name)
        push!(order, name)
    end
    foreach(visit, wanted)
    return order, projects, paths
end

function snapshot(repo, destination, mode)
    if mode == "committed"
        run(`git clone --quiet --bare --no-hardlinks $repo $destination`)
        return strip(read(`git -C $repo rev-parse HEAD`, String))
    end
    mkpath(destination)
    # Include tracked modifications/deletions and nonignored new source files;
    # exclude gitignored manifests, documentation output, and cache files.
    files = split(read(`git -C $repo ls-files -z --cached --others --exclude-standard`, String), '\0'; keepempty=false)
    for file in unique(files)
        source = joinpath(repo, file)
        ispath(source) || islink(source) || continue
        target = joinpath(destination, file)
        mkpath(dirname(target))
        cp(source, target; follow_symlinks=false)
    end
    run(`git -C $destination init --quiet`)
    # The copied inventory already excludes ignored untracked files. Force
    # staging preserves tracked files newly covered by a changed .gitignore.
    run(`git -C $destination add -f -A`)
    run(`git -C $destination -c user.name=LocalValidation -c user.email=validation@localhost -c commit.gpgsign=false commit --quiet --no-verify -m "Local validation snapshot"`)
    return strip(read(`git -C $destination rev-parse HEAD`, String))
end

function child(config_path)
    config = TOML.parsefile(config_path)
    depot = config["depot"]
    DEPOT_PATH == [depot] || error("Depot isolation failed: $(DEPOT_PATH)")
    Pkg.depots() == [depot] || error("Pkg is not using the isolated depot")
    Pkg.activate(config["project"])
    Pkg.Registry.add("General")
    registry = get(config, "registry", "")
    isempty(registry) || Pkg.Registry.add(Pkg.RegistrySpec(url=registry))
    results = Dict{String,Any}[]
    for package in config["packages"]
        name = package["name"]
        println("INSTALL ", name, " [", config["mode"], "]")
        try
            if isempty(registry)
                Pkg.add(Pkg.PackageSpec(url=package["url"], rev=package["rev"]))
            else
                Pkg.add(Pkg.PackageSpec(name=name, uuid=package["uuid"]))
            end
            Base.eval(Main, :(using $(Symbol(name))))
            # URL/registry installs must not smuggle live developed paths in.
            for (uuid, info) in Pkg.dependencies()
                info.is_tracking_path && error("Unexpected developed dependency $(info.name): $(info.source)")
                info.source === nothing && continue
                live_root = config["live_root"]
                startswith(realpath(info.source), realpath(live_root) * string(Base.Filesystem.path_separator)) &&
                    error("Dependency $(info.name) resolved into live workspace")
            end
            push!(results, Dict("package"=>name, "pass"=>true, "source_revision"=>get(package, "rev", "registry")))
            println("PASS ", name)
        catch err
            push!(results, Dict("package"=>name, "pass"=>false, "error"=>sprint(showerror, err)))
            showerror(stderr, err, catch_backtrace())
            println(stderr)
            break
        end
    end
    open(config["results"], "w") do io
        TOML.print(io, Dict("mode"=>config["mode"], "julia"=>string(VERSION),
                           "isolated_depot"=>depot, "checks"=>results))
    end
    all_pass = length(results) == length(config["packages"]) && all(r["pass"] for r in results)
    println(all_pass ? "PASS: all packages installed and loaded in an isolated child process" : "FAIL: installation/loading did not complete")
    exit(all_pass ? 0 : 1)
end

function main(args)
    if length(args) == 2 && args[1] == "--child"
        return child(args[2])
    end
    mode, registry, keep = "committed", "", false
    selected = String[]
    for arg in args
        if startswith(arg, "--source=")
            mode = split(arg, '='; limit=2)[2]
        elseif startswith(arg, "--registry=")
            registry = split(arg, '='; limit=2)[2]
        elseif startswith(arg, "--package=")
            push!(selected, split(arg, '='; limit=2)[2])
        elseif arg == "--keep"
            keep = true
        else
            error("Unknown option: $arg")
        end
    end
    mode in ("committed", "working-tree") || error("--source must be committed or working-tree")
    order, projects, paths = package_order(ROOT, selected;
        committed=isempty(registry) && mode == "committed")
    scratch = mktempdir(; prefix="snwj-install-check-", cleanup=false)
    depot, project = joinpath(scratch, "depot"), joinpath(scratch, "environment")
    mkpath(depot)
    mkpath(project)
    packages = Dict{String,Any}[]
    for (i, name) in enumerate(order)
        package = Dict{String,Any}("name"=>name, "uuid"=>projects[name]["uuid"])
        if isempty(registry)
            # Randomized parent directories ensure original ../Sibling.jl
            # paths cannot resolve against any neighbouring snapshot.
            destination = joinpath(scratch, "sources", string(i), "snapshot")
            mkpath(dirname(destination))
            package["rev"] = snapshot(paths[name], destination, mode)
            package["url"] = destination
        end
        push!(packages, package)
    end
    config = Dict("mode"=>isempty(registry) ? mode : "registry", "registry"=>registry,
                  "depot"=>depot, "project"=>project, "packages"=>packages,
                  "live_root"=>ROOT, "results"=>joinpath(scratch, "results.toml"))
    config_path = joinpath(scratch, "config.toml")
    open(io -> TOML.print(io, config), config_path, "w")
    println("Installation mode: ", config["mode"], "; evidence: ", scratch)
    println("Order: ", join(order, " -> "))
    cmd = `$(Base.julia_cmd()) --startup-file=no --project=$project $(@__FILE__) --child $config_path`
    env = merge(copy(ENV), Dict("JULIA_DEPOT_PATH"=>depot,
                               "JULIA_LOAD_PATH"=>"@:@stdlib",
                               "JULIA_PKG_PRECOMPILE_AUTO"=>"0"))
    ok = success(pipeline(setenv(cmd, env); stdout=stdout, stderr=stderr))
    if ok && !keep
        rm(scratch; recursive=true)
    else
        println("Evidence retained at ", scratch)
    end
    isempty(registry) && println("Local snapshot validation does not establish registry publication or remote availability.")
    return ok ? 0 : 1
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main(ARGS))
end
