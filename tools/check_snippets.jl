#!/usr/bin/env julia
# check_snippets.jl — execute the fenced `julia` code blocks in every Markdown
# page of the StatNet-Julia ecosystem and report pass/fail per file.
#
# Usage:
#     julia tools/check_snippets.jl [filter...]
#
# The monorepo root (the directory that contains Networks.jl, ERGM.jl, ...,
# and this site repo side by side) is taken from ENV["SNWJ_ROOT"] if set,
# otherwise it defaults to the parent directory of this repo.
#
# Which files are checked:
#   * every package repo's top-level README.md,
#   * every package repo's docs/src/**/*.md,
#   * the site's own pages (*.md outside underscore-prefixed dirs).
# Any positional arguments are substring filters on the file path, e.g.
#     julia tools/check_snippets.jl ERGM.jl/docs getting_started
# runs only files whose path contains at least one of the filters.
#
# Which blocks are executed:
#   * fenced ```julia blocks, run sequentially per file inside one fresh
#     sandbox module (so later blocks see the earlier blocks' variables),
#     with REPL soft scope so top-level loops behave as they do in the REPL.
# Blocks are SKIPPED when:
#   * the fence is ```julia-repl (documentation of REPL transcripts),
#   * the line right above the fence contains `<!-- skip-check -->`,
#   * the block mutates a Pkg environment (Pkg.add / Pkg.develop / ... ) —
#     these are install instructions, usually with placeholder paths, and
#     running them would modify the shared checker environment,
#   * the block is clearly output-only (the nearest preceding text line is
#     an "Output:"-style label, or the block does not parse as Julia —
#     unparseable blocks are listed as warnings so real syntax errors in
#     examples still surface).
#
# Environment: run this script with --project pointing at an environment in
# which all the local packages are `Pkg.develop`ed (see tools/README.md for
# a one-liner that builds such an environment).  The script itself does not
# mutate any environment.

using REPL # for REPL.softscope

# ---------------------------------------------------------------------------
# Locate the files to check
# ---------------------------------------------------------------------------

const SITE_DIR = realpath(joinpath(@__DIR__, ".."))
const ROOT = get(ENV, "SNWJ_ROOT", dirname(SITE_DIR))

function collect_files(root::AbstractString)
    files = String[]
    for entry in sort(readdir(root))
        repo = joinpath(root, entry)
        isdir(repo) || continue
        startswith(entry, ".") && continue
        if realpath(repo) == SITE_DIR
            # The site's own pages: every .md outside underscore dirs.
            for (dir, _, names) in walkdir(repo)
                any(startswith(d, "_") for d in splitpath(relpath(dir, repo))) && continue
                for n in names
                    endswith(n, ".md") && push!(files, joinpath(dir, n))
                end
            end
        elseif isfile(joinpath(repo, "Project.toml"))
            # A package repo: README.md plus docs/src/**.
            readme = joinpath(repo, "README.md")
            isfile(readme) && push!(files, readme)
            docs = joinpath(repo, "docs", "src")
            if isdir(docs)
                for (dir, _, names) in walkdir(docs)
                    for n in names
                        endswith(n, ".md") && push!(files, joinpath(dir, n))
                    end
                end
            end
        end
    end
    return files
end

# ---------------------------------------------------------------------------
# Extract fenced julia blocks
# ---------------------------------------------------------------------------

struct Snippet
    line::Int          # line number of the opening fence
    code::String
    skip::Union{Nothing, String}  # reason to skip, or nothing to run it
end

const OUTPUT_LABEL = r"(?:^|\b)(?:example\s+)?output:?\**\s*$"i

function extract_snippets(path::AbstractString)
    lines = readlines(path)
    snippets = Snippet[]
    i = 1
    while i <= length(lines)
        m = match(r"^\s*```(julia[a-z-]*)\s*$", lines[i])
        if m === nothing
            i += 1
            continue
        end
        lang = m.captures[1]
        fence_line = i
        body = String[]
        i += 1
        while i <= length(lines) && !occursin(r"^\s*```\s*$", lines[i])
            push!(body, lines[i])
            i += 1
        end
        i += 1  # move past the closing fence
        code = join(body, "\n")

        skip = nothing
        if lang != "julia"
            skip = "fenced as $lang"
        elseif fence_line > 1 && occursin("<!-- skip-check -->", lines[fence_line - 1])
            skip = "skip-check marker"
        elseif occursin(r"\bPkg\.(add|develop|rm|activate|instantiate|update)\(", code)
            skip = "Pkg install instructions"
        else
            # Output-only heuristic: the nearest non-blank line above the
            # fence is an "Output:"-style label.
            j = fence_line - 1
            while j >= 1 && isempty(strip(lines[j]))
                j -= 1
            end
            if j >= 1 && occursin(OUTPUT_LABEL, strip(lines[j]))
                skip = "output-only block"
            end
        end
        push!(snippets, Snippet(fence_line, code, skip))
    end
    return snippets
end

# ---------------------------------------------------------------------------
# Execute one file's blocks in a fresh sandbox module
# ---------------------------------------------------------------------------

struct Failure
    line::Int          # line within the md file
    message::String
end

function run_file(path::AbstractString, snippets::Vector{Snippet})
    sandbox = Module(gensym(basename(path)))
    # Give the sandbox a self-referential eval/include so snippets that call
    # eval() or include_string() behave.
    Core.eval(sandbox, :(eval(x) = Core.eval($sandbox, x)))
    Core.eval(sandbox, :(include(f) = Base.include($sandbox, f)))

    failures = Failure[]
    warnings = Failure[]
    n_run = 0
    # Run in a scratch directory so examples that write files (Pajek export,
    # CSV output, rendered animations, ...) do not pollute the repos.
    old_dir = pwd()
    cd(mktempdir())
    try
        for sn in snippets
            sn.skip === nothing || continue
            parsed = try
                Meta.parseall(sn.code; filename = path)
            catch err
                push!(warnings, Failure(sn.line,
                    "does not parse (treated as output-only): " * sprint(showerror, err)))
                continue
            end
            # parseall wraps statements in a toplevel block; check for embedded
            # parse errors (Meta.parseall does not always throw).
            if _has_parse_error(parsed)
                push!(warnings, Failure(sn.line, "does not parse (treated as output-only)"))
                continue
            end
            n_run += 1
            ok = _eval_block(sandbox, parsed, sn, path, failures)
            ok || break   # later blocks depend on earlier state; stop at first failure
        end
    finally
        cd(old_dir)
    end
    return n_run, failures, warnings
end

_has_parse_error(ex) = ex isa Expr &&
    (ex.head in (:error, :incomplete) || any(_has_parse_error, ex.args))

function _eval_block(sandbox, parsed, sn::Snippet, path, failures)
    stmts = parsed isa Expr && parsed.head == :toplevel ? parsed.args : Any[parsed]
    cur_line = sn.line
    devnull_io = devnull
    for st in stmts
        if st isa LineNumberNode
            cur_line = sn.line + st.line   # st.line is 1-based within the block
            continue
        end
        try
            redirect_stdout(devnull_io) do
                Core.eval(sandbox, REPL.softscope(st))
            end
        catch err
            err isa InterruptException && rethrow()
            msg = sprint(showerror, err)
            first_line = split(msg, '\n'; limit = 2)[1]
            push!(failures, Failure(cur_line, first_line))
            return false
        end
    end
    return true
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function main(args)
    filters = collect(args)
    files = collect_files(ROOT)
    if !isempty(filters)
        files = [f for f in files if any(occursin(flt, f) for flt in filters)]
    end

    println("Monorepo root: $ROOT")
    println("Checking $(length(files)) Markdown file(s)\n")
    flush(stdout)

    n_pass = 0
    n_fail = 0
    n_blocks = 0
    all_warnings = Tuple{String, Failure}[]
    failed_files = Tuple{String, Vector{Failure}}[]

    for path in files
        rel = relpath(path, ROOT)
        snippets = extract_snippets(path)
        runnable = count(s -> s.skip === nothing, snippets)
        if runnable == 0
            continue
        end
        n_run, failures, warnings = run_file(path, snippets)
        n_blocks += n_run
        append!(all_warnings, (rel, w) for w in warnings)
        if isempty(failures)
            n_pass += 1
            println("PASS  $rel  ($n_run block(s))")
        else
            n_fail += 1
            push!(failed_files, (rel, failures))
            println("FAIL  $rel")
            for f in failures
                println("      $rel:$(f.line): $(f.message)")
            end
        end
        flush(stdout)
    end

    println("\n", "="^70)
    println("Summary: $n_pass file(s) passed, $n_fail failed, ",
            "$n_blocks block(s) executed")
    if !isempty(all_warnings)
        println("\nWarnings (blocks skipped as unparseable — check they are ",
                "really output, not broken examples):")
        for (rel, w) in all_warnings
            println("  $rel:$(w.line): $(w.message)")
        end
    end
    if !isempty(failed_files)
        println("\nFailures:")
        for (rel, failures) in failed_files, f in failures
            println("  $rel:$(f.line): $(f.message)")
        end
        exit(1)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
