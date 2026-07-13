#!/usr/bin/env julia
# setup_registry.jl — stand up a LocalRegistry for the StatNet-Julia ecosystem
# and register every package in dependency order, so released versions can
# drop the [sources] path-dependency sections from their Project.toml files.
#
# Usage:
#     julia tools/setup_registry.jl                  # dry run (default, safe)
#     julia tools/setup_registry.jl --register       # actually create + register
#     julia tools/setup_registry.jl --register --registry-path ~/SNWJRegistry
#
# Options:
#     --register             perform the real registration (default: dry run)
#     --registry-path PATH   where to create the registry working copy
#                            (default: ~/.julia/registries-dev/SNWJRegistry)
#     --registry-repo URL    optional git remote for the registry (e.g. a
#                            GitHub URL); omit for a purely local registry
#     --registry-name NAME   registry name (default: SNWJRegistry)
#
# IMPORTANT: LocalRegistry registers the *committed* git state of each
# package, not the working tree.  Commit (and ideally tag) every package
# before running with --register; the dry run flags dirty trees for you.
#
# The monorepo root (the directory that contains Networks.jl, ERGM.jl, ...,
# and this site repo side by side) is taken from ENV["SNWJ_ROOT"] if set,
# otherwise it defaults to the parent directory of this repo.
#
# Registration order (dependents strictly after their dependencies):
#   Networks → NetworkDynamic / SNA / ERGM / Siena → REM → Relevent,
#   NDTV / TSNA, and the ERGM satellite packages (ERGMCount, ERGMEgo,
#   ERGMMulti, ERGMRank, ERGMUserterms, TERGM).
#
# In --register mode the script installs LocalRegistry into a temporary
# environment, creates the registry if it does not exist yet, and calls
# `LocalRegistry.register` on each package path in the order above.

using Pkg
using TOML

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

const SITE_DIR = realpath(joinpath(@__DIR__, ".."))
const ROOT = get(ENV, "SNWJ_ROOT", dirname(SITE_DIR))

# Topological order: every package appears after all of its local deps.
const REGISTRATION_ORDER = [
    "Networks.jl",         # foundation: no local deps
    "NetworkDynamic.jl",  # ← Networks
    "SNA.jl",             # ← Networks
    "ERGM.jl",            # ← Networks
    "Siena.jl",           # ← Networks (extension)
    "REM.jl",             # ← Networks (+ NetworkDynamic weakdep)
    "Relevent.jl",        # ← Networks, REM
    "NDTV.jl",            # ← Networks, NetworkDynamic
    "TSNA.jl",            # ← Networks, NetworkDynamic, SNA
    "TERGM.jl",           # ← Networks, ERGM
    "ERGMCount.jl",       # ← Networks, ERGM
    "ERGMEgo.jl",         # ← Networks, ERGM
    "ERGMMulti.jl",       # ← Networks, ERGM
    "ERGMRank.jl",        # ← Networks, ERGM
    "ERGMUserterms.jl",   # ← Networks, ERGM
]

# ---------------------------------------------------------------------------
# CLI parsing
# ---------------------------------------------------------------------------

function parse_args(args)
    opts = Dict{String,Any}(
        "register"      => false,
        "registry-path" => joinpath(homedir(), ".julia", "registries-dev", "SNWJRegistry"),
        "registry-repo" => nothing,
        "registry-name" => "SNWJRegistry",
    )
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--register"
            opts["register"] = true
        elseif a in ("--registry-path", "--registry-repo", "--registry-name")
            i < length(args) || error("missing value for $a")
            opts[a[3:end]] = expanduser(args[i+1])
            i += 1
        elseif a in ("-h", "--help")
            for line in eachline(@__FILE__)
                startswith(line, "#!") && continue
                startswith(line, "#") || break
                println(lstrip(lstrip(line, '#')))
            end
            exit(0)
        else
            error("unknown argument: $a (try --help)")
        end
        i += 1
    end
    return opts
end

# ---------------------------------------------------------------------------
# Readiness checks
# ---------------------------------------------------------------------------

struct PkgInfo
    dir::String
    name::String
    uuid::String
    version::VersionNumber
end

function git(dir::AbstractString, args...)
    io = IOBuffer()
    ok = success(pipeline(Cmd(["git", "-C", dir, args...]); stdout = io, stderr = devnull))
    return ok, strip(String(take!(io)))
end

"""
    check_package(dir) -> (info, problems)

Read the package's Project.toml and collect registration blockers:
missing metadata, a dirty git tree (LocalRegistry registers committed
state only), no commits, or local `[sources]` deps whose targets are not
scheduled for registration ahead of this package.
"""
function check_package(dir::AbstractString, seen::Set{String})
    problems = String[]
    project = joinpath(dir, "Project.toml")
    isfile(project) || return nothing, ["no Project.toml"]
    toml = TOML.parsefile(project)
    for key in ("name", "uuid", "version")
        haskey(toml, key) || push!(problems, "Project.toml has no `$key`")
    end
    info = PkgInfo(dir,
                   get(toml, "name", basename(dir)),
                   get(toml, "uuid", "?"),
                   VersionNumber(get(toml, "version", "0.0.0")))

    if !isdir(joinpath(dir, ".git"))
        push!(problems, "not a git repository")
    else
        ok, out = git(dir, "status", "--porcelain")
        ok || push!(problems, "`git status` failed")
        isempty(out) || push!(problems, "dirty working tree ($(length(split(out, '\n'))) path(s)) — commit before registering")
        ok, _ = git(dir, "rev-parse", "--verify", "HEAD")
        ok || push!(problems, "no commits on HEAD")
    end

    for dep in keys(get(toml, "sources", Dict{String,Any}()))
        dep in seen || push!(problems, "[sources] dep `$dep` is not registered before this package")
    end

    compat = get(toml, "compat", Dict{String,Any}())
    for dep in keys(get(toml, "deps", Dict{String,Any}()))
        haskey(compat, dep) || push!(problems, "missing [compat] bound for `$dep`")
    end
    haskey(compat, "julia") || push!(problems, "missing [compat] bound for `julia`")

    return info, problems
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function main(args)
    opts = parse_args(args)
    dry = !opts["register"]

    println(dry ? "== DRY RUN (no changes; pass --register to run for real) ==" :
                  "== REGISTRATION RUN ==")
    println("monorepo root:  $ROOT")
    println("registry name:  $(opts["registry-name"])")
    println("registry path:  $(opts["registry-path"])")
    println("registry repo:  $(something(opts["registry-repo"], "(local only)"))")
    println()

    # -- readiness ----------------------------------------------------------
    ready = true
    infos = PkgInfo[]
    seen = Set{String}()
    for (k, repo) in enumerate(REGISTRATION_ORDER)
        dir = joinpath(ROOT, repo)
        if !isdir(dir)
            println("$(lpad(k, 2)). $repo  —  MISSING checkout at $dir")
            ready = false
            continue
        end
        info, problems = check_package(dir, seen)
        status = isempty(problems) ? "ready" : "NOT READY"
        println("$(lpad(k, 2)). $(rpad(repo, 20)) v$(info.version)  —  $status")
        for p in problems
            println("      * $p")
        end
        isempty(problems) || (ready = false)
        push!(infos, info)
        push!(seen, info.name)
    end
    println()

    if dry
        println(ready ? "All packages pass the readiness checks." :
                        "Fix the problems above, commit, then rerun with --register.")
        return ready ? 0 : 1
    end

    if !ready
        println("Refusing to register: not all packages are ready (see above).")
        return 1
    end

    # -- real registration --------------------------------------------------
    # LocalRegistry lives in a temporary environment so this script never
    # touches the packages' own environments.
    Pkg.activate(mktempdir())
    Pkg.add("LocalRegistry")
    @eval using LocalRegistry

    regpath = opts["registry-path"]
    if isdir(joinpath(regpath, ".git"))
        println("Using existing registry at $regpath")
    else
        println("Creating registry $(opts["registry-name"]) at $regpath")
        mkpath(dirname(regpath))
        if opts["registry-repo"] === nothing
            # Purely local registry: create a bare "remote" next to the
            # working copy so LocalRegistry can push to it.
            bare = regpath * ".git"
            run(`git init --bare --initial-branch=master $bare`)
            Base.invokelatest(LocalRegistry.create_registry, regpath, bare;
                              description = "Local registry for the StatNet-Julia ecosystem",
                              push = true)
        else
            Base.invokelatest(LocalRegistry.create_registry, regpath, opts["registry-repo"];
                              description = "Local registry for the StatNet-Julia ecosystem",
                              push = true)
        end
    end

    for info in infos
        println("registering $(info.name) v$(info.version) from $(info.dir) ...")
        # `register` reads the package's committed state; [sources] sections
        # are dev-time only and are not written into the registry.
        Base.invokelatest(LocalRegistry.register, info.dir;
                          registry = regpath, push = true)
    end

    println()
    println("Done. Make the registry available to Julia with:")
    println("    using Pkg; Pkg.Registry.add(RegistrySpec(path = \"$regpath\"))")
    println("After that, released packages can drop their [sources] sections.")
    return 0
end

exit(main(ARGS))
