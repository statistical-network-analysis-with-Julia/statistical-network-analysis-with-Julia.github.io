#!/usr/bin/env julia
# run_benchmarks.jl — run every package's BenchmarkTools suite and print one
# consolidated table.
#
# Usage:
#     julia tools/run_benchmarks.jl [filter...]
#
# The monorepo root (the directory that contains Network.jl, ERGM.jl, ...,
# and this site repo side by side) is taken from ENV["SNWJ_ROOT"] if set,
# otherwise it defaults to the parent directory of this repo. Any positional
# arguments are substring filters on the package name, e.g.
#     julia tools/run_benchmarks.jl ERGM Siena
# runs only the ERGM.jl and Siena.jl suites.
#
# What it does, per package repo that ships a `benchmark/benchmarks.jl`:
#   1. instantiates the package's own `benchmark/` project (each suite runs
#      in its package's environment — this script needs no dependencies),
#   2. runs `benchmark/benchmarks.jl`, which prints one tab-separated
#      `BENCHJL\t<name>\t<median ns>\t<allocs>\t<bytes>` line per benchmark
#      (plus `SCALING` lines where a suite asserts complexity, e.g. ERGM's
#      O(degree) change statistics) and exits non-zero on assertion failure,
#   3. runs `benchmark/regression_tests.jl` (allocation-regression @test
#      blocks) where the package ships one.
#
# The consolidated table plus a per-package pass/fail summary go to stdout;
# the script exits non-zero if any suite or regression test failed.

# ---------------------------------------------------------------------------
# Locate the suites
# ---------------------------------------------------------------------------

const SITE_DIR = realpath(joinpath(@__DIR__, ".."))
const ROOT = get(ENV, "SNWJ_ROOT", dirname(SITE_DIR))

function collect_suites(root::AbstractString, filters::Vector{String})
    suites = String[]
    for entry in sort(readdir(root))
        repo = joinpath(root, entry)
        isdir(repo) || continue
        startswith(entry, ".") && continue
        realpath(repo) == SITE_DIR && continue
        isfile(joinpath(repo, "benchmark", "benchmarks.jl")) || continue
        if isempty(filters) || any(occursin(f, entry) for f in filters)
            push!(suites, repo)
        end
    end
    return suites
end

# ---------------------------------------------------------------------------
# Run one package's suite in its own benchmark environment
# ---------------------------------------------------------------------------

struct BenchRow
    package::String
    name::String
    time_ns::Float64
    allocs::Int
    memory::Int
end

function run_suite(repo::AbstractString)
    pkg = basename(repo)
    benchdir = joinpath(repo, "benchmark")
    rows = BenchRow[]
    notes = String[]

    println(stderr, "── $pkg: instantiating benchmark environment ...")
    instcmd = `$(Base.julia_cmd()) --project=$benchdir -e "using Pkg; Pkg.instantiate()"`
    if !success(pipeline(instcmd; stdout=stderr, stderr=stderr))
        return rows, notes, false, "environment instantiation failed"
    end

    println(stderr, "── $pkg: running benchmarks.jl ...")
    out = IOBuffer()
    cmd = `$(Base.julia_cmd()) --project=$benchdir $(joinpath(benchdir, "benchmarks.jl"))`
    ok = success(pipeline(cmd; stdout=out, stderr=stderr))
    for line in eachline(IOBuffer(take!(out)))
        fields = split(line, '\t')
        if fields[1] == "BENCHJL" && length(fields) == 5
            push!(rows, BenchRow(pkg, fields[2],
                                 parse(Float64, fields[3]),
                                 parse(Int, fields[4]),
                                 parse(Int, fields[5])))
        elseif fields[1] == "SCALING" && length(fields) >= 4
            push!(notes, "$pkg scaling $(fields[2]) [$(fields[3])]: $(fields[4])x")
        else
            println(line)   # pass through anything else the suite printed
        end
    end
    ok || return rows, notes, false, "benchmarks.jl failed (see output above)"

    regfile = joinpath(benchdir, "regression_tests.jl")
    if isfile(regfile)
        println(stderr, "── $pkg: running regression_tests.jl ...")
        regcmd = `$(Base.julia_cmd()) --project=$benchdir $regfile`
        if success(pipeline(regcmd; stdout=stderr, stderr=stderr))
            push!(notes, "$pkg regression_tests.jl: PASS")
        else
            push!(notes, "$pkg regression_tests.jl: FAIL")
            return rows, notes, false, "regression_tests.jl failed"
        end
    end

    return rows, notes, true, ""
end

# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------

function fmt_time(ns::Float64)
    ns < 1e3 && return string(round(ns; digits=1), " ns")
    ns < 1e6 && return string(round(ns / 1e3; digits=2), " μs")
    ns < 1e9 && return string(round(ns / 1e6; digits=2), " ms")
    return string(round(ns / 1e9; digits=2), " s")
end

function fmt_bytes(b::Int)
    b < 1024 && return string(b, " B")
    b < 1024^2 && return string(round(b / 1024; digits=1), " KiB")
    return string(round(b / 1024^2; digits=2), " MiB")
end

function print_table(rows::Vector{BenchRow})
    headers = ("Package", "Benchmark", "Median time", "Allocs", "Memory")
    cells = [(r.package, r.name, fmt_time(r.time_ns), string(r.allocs),
              fmt_bytes(r.memory)) for r in rows]
    widths = [max(length(headers[c]), maximum(length(row[c]) for row in cells;
                                              init=0)) for c in 1:5]
    line(row) = string("| ",
        join([c <= 2 ? rpad(row[c], widths[c]) : lpad(row[c], widths[c])
              for c in 1:5], " | "), " |")
    rule = string("|", join(["-"^(w + 2) for w in widths], "|"), "|")
    println(line(headers))
    println(rule)
    foreach(println ∘ line, cells)
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

function main(args)
    suites = collect_suites(ROOT, String.(args))
    if isempty(suites)
        println(stderr, "no benchmark suites found under $ROOT",
                isempty(args) ? "" : " matching $(join(args, ", "))")
        exit(1)
    end

    all_rows = BenchRow[]
    all_notes = String[]
    failures = String[]
    for repo in suites
        rows, notes, ok, reason = run_suite(repo)
        append!(all_rows, rows)
        append!(all_notes, notes)
        ok || push!(failures, "$(basename(repo)): $reason")
    end

    println()
    println("Benchmark results (medians; ", basename(ROOT), ", ",
            length(suites), " suites)")
    println()
    isempty(all_rows) || print_table(all_rows)

    if !isempty(all_notes)
        println()
        println("Assertions and regression tests:")
        foreach(n -> println("  * ", n), all_notes)
    end

    if !isempty(failures)
        println()
        println("FAILED suites:")
        foreach(f -> println("  * ", f), failures)
        exit(1)
    end
end

main(ARGS)
