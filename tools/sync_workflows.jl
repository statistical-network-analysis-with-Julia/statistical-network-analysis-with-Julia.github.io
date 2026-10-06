#!/usr/bin/env julia
# Keep the packages' GitHub workflows on one sibling-clone mechanism.
#
#   julia tools/sync_workflows.jl [WORKSPACE] [--check] [--package=Name ...]
#
# * Every package's CI.yml and Documentation.yml carry the step in
#   tools/workflows/layout-step.yml between its `# >>> ecosystem layout` and
#   `# <<< ecosystem layout` lines, byte for byte.
# * Documentation.yml is tools/workflows/Documentation.yml with the package
#   name substituted.
# * The packages in DOWNSTREAM also carry tools/workflows/Downstream.yml, and
#   no other package carries a Downstream workflow.
# * No workflow keeps an older clone mechanism (a literal `for pkg in` loop,
#   a sed pipeline or a `checkout_sources.jl` script).
# * Every sibling named in a `[sources]` table of any Project.toml of a
#   package (main, docs/, benchmark/, examples/…) is a `path` entry that
#   resolves to that sibling's checkout. The layout step clones exactly the
#   path sources, so a `url`/`rev` source (which a Pkg command can write)
#   would silently test against the published `main` instead of the workspace.
#
# Without --check the workflow files are rewritten. CI.yml is package-owned
# apart from the marked block, so a CI.yml without the markers is reported, not
# rewritten; source and Downstream problems are always reported, never fixed.
using TOML

const TEMPLATES = joinpath(@__DIR__, "workflows")
const DOWNSTREAM = ("NetworkCore", "ERGM")
const BEGIN_MARK = "      # >>> ecosystem layout"
const END_MARK = "      # <<< ecosystem layout\n"

layout_step() = read(joinpath(TEMPLATES, "layout-step.yml"), String)

function documentation_workflow(name)
    text = read(joinpath(TEMPLATES, "Documentation.yml"), String)
    text = replace(text, "      # __LAYOUT_STEP__\n" => layout_step())
    return replace(text, "__PKG__" => name)
end

downstream_workflow() = read(joinpath(TEMPLATES, "Downstream.yml"), String)

"""Return `text` with its marked layout block replaced, or `nothing` without markers."""
function with_layout(text)
    first_mark = findfirst(BEGIN_MARK, text)
    last_mark = findfirst(END_MARK, text)
    (first_mark === nothing || last_mark === nothing) && return nothing
    start = first(first_mark)
    stop = last(last_mark)
    start < stop || return nothing
    return text[1:prevind(text, start)] * layout_step() * text[nextind(text, stop):end]
end

const STALE = (r"for pkg in [A-Za-z$]" => "a shell clone loop",
               r"checkout_sources\.jl" => "a checkout_sources.jl script",
               r"sed -n [^\n]*Project\.toml" => "a sed pipeline over Project.toml")

function problems(name, file, text)
    found = String[]
    for (pattern, what) in STALE
        occursin(pattern, text) && push!(found, "$file: still uses $what")
    end
    occursin(BEGIN_MARK, text) && !occursin("path: $name.jl\n", text) &&
        push!(found, "$file: check the package out with `path: $name.jl` before the layout step")
    return found
end

"""
    source_problems(root, name, siblings) -> Vector{String}

Every `[sources]` entry naming one of `siblings` in a `Project.toml` under
`root/name.jl` must be `{path = ...}` and resolve to `root/<dep>.jl`.
"""
function source_problems(root, name, siblings)
    found = String[]
    package = joinpath(root, "$name.jl")
    for (dir, subdirs, files) in walkdir(package)
        # Never descend into git data, built docs or hidden directories
        filter!(d -> !startswith(d, ".") && !(d == "build" && basename(dir) == "docs"), subdirs)
        "Project.toml" in files || continue
        file = joinpath(dir, "Project.toml")
        where = relpath(file, root)
        sources = get(TOML.parsefile(file), "sources", Dict{String,Any}())
        for dep in sort!(collect(keys(sources)))
            dep in siblings || continue
            spec = sources[dep]
            if !(spec isa AbstractDict) || !haskey(spec, "path")
                push!(found, "$where: [sources] $dep is not a path source ($(spec)); " *
                             "write $dep = {path = \"$(relpath(joinpath(root, "$dep.jl"), dir))\"}")
            elseif rstrip(normpath(joinpath(dir, spec["path"])), '/') != rstrip(normpath(joinpath(root, "$dep.jl")), '/')
                push!(found, "$where: [sources] $dep points at $(spec["path"]), not the sibling $dep.jl")
            end
        end
    end
    return found
end

"""True for a workflow file that is (or claims to be) the downstream dispatcher."""
is_downstream_workflow(file, text) =
    lowercase(file) in ("downstream.yml", "downstream.yaml") ||
    occursin(r"(?m)^name:\s*Downstream\s*$", text) || occursin("DOWNSTREAM_DISPATCH_TOKEN", text)

"""A Downstream workflow outside the DOWNSTREAM packages would dispatch from the wrong repository."""
function downstream_problems(name, dir)
    name in DOWNSTREAM && return String[]
    return ["$name.jl/.github/workflows/$file: only $(join(DOWNSTREAM, " and ")) carry the Downstream workflow"
            for file in sort!(readdir(dir))
            if (endswith(file, ".yml") || endswith(file, ".yaml")) &&
               is_downstream_workflow(file, read(joinpath(dir, file), String))]
end

# Packages whose suites have nothing a second thread would exercise. Every other
# package's CI.yml must run at least one cell with JULIA_NUM_THREADS = 4: the
# thread-count-independence testsets are tautologies on one thread.
const SINGLE_THREADED = ("NDTV", "ERGMUserterms")

"""True when `ci` sets four Julia threads on some cell (job env, step env or a matrix `threads:` entry)."""
function has_threaded_cell(ci)
    lines = split(ci, '\n')
    uses_matrix = any(l -> occursin("JULIA_NUM_THREADS", l) && occursin("matrix.threads", l), lines)
    return any(lines) do l
        startswith(lstrip(l), "#") && return false
        occursin("JULIA_NUM_THREADS", l) && occursin(r"\b4\b", l) && !occursin("matrix.threads", l) ||
            uses_matrix && occursin(r"^\s*threads: '?4'?\s*$", l)
    end
end

function main(args)
    unknown = filter(a -> startswith(a, "--") && a != "--check" && !startswith(a, "--package="), args)
    isempty(unknown) || error("Unknown option(s): $(join(unknown, ", "))")
    roots = filter(a -> !startswith(a, "--"), args)
    length(roots) <= 1 || error("Usage: julia tools/sync_workflows.jl [WORKSPACE] [--check] [--package=Name ...]")
    root = isempty(roots) ? normpath(joinpath(@__DIR__, "..", "..")) : abspath(only(roots))
    check = "--check" in args
    selected = [split(a, '='; limit=2)[2] for a in args if startswith(a, "--package=")]
    workspace = TOML.parsefile(joinpath(@__DIR__, "workspace", "Project.toml"))
    names = isempty(selected) ? sort!(collect(keys(workspace["sources"]))) : selected
    for name in names
        haskey(workspace["sources"], name) || error("Unknown package: $name")
        isdir(joinpath(root, "$name.jl", ".github", "workflows")) || error("Missing workflows: $name.jl")
    end
    mismatches = String[]
    siblings = Set(keys(workspace["sources"]))
    for name in names
        dir = joinpath(root, "$name.jl", ".github", "workflows")
        append!(mismatches, source_problems(root, name, siblings))
        append!(mismatches, downstream_problems(name, dir))
        expected = Dict("Documentation.yml" => documentation_workflow(name))
        name in DOWNSTREAM && (expected["Downstream.yml"] = downstream_workflow())
        for (file, text) in expected
            path = joinpath(dir, file)
            if check
                isfile(path) && read(path, String) == text ||
                    push!(mismatches, "$name.jl/.github/workflows/$file differs from the template")
            else
                write(path, text)
            end
        end
        ci_path = joinpath(dir, "CI.yml")
        ci = read(ci_path, String)
        updated = with_layout(ci)
        if updated === nothing
            push!(mismatches, "$name.jl/.github/workflows/CI.yml has no `# >>> ecosystem layout` block")
        elseif updated != ci
            check ? push!(mismatches, "$name.jl/.github/workflows/CI.yml: the layout block differs from the template") :
                    write(ci_path, updated)
        end
        name in SINGLE_THREADED || has_threaded_cell(read(ci_path, String)) ||
            push!(mismatches, "$name.jl/.github/workflows/CI.yml: no cell runs with JULIA_NUM_THREADS = 4 " *
                              "(the thread-count-independence tests need more than one thread)")
        for file in sort!(readdir(dir))
            endswith(file, ".yml") || continue
            append!(mismatches, problems(name, "$name.jl/.github/workflows/$file", read(joinpath(dir, file), String)))
        end
    end
    isempty(mismatches) || error("Workflows need attention:\n" * join(mismatches, '\n'))
    println(check ? "Workflows of $(length(names)) packages share one layout step and match the templates." :
                    "Workflows of $(length(names)) packages synced.")
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS)
end
