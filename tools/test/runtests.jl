using Test
using TOML

module SnippetChecks
include(joinpath(@__DIR__, "..", "check_snippets.jl"))
end

module InstallChecks
include(joinpath(@__DIR__, "..", "check_clean_depot.jl"))
end

module BenchmarkChecks
include(joinpath(@__DIR__, "..", "run_benchmarks.jl"))
end

@testset "Default installation workspace path" begin
    # Exercise the documented invocation without the coordinator's override.
    # normpath(joinpath(dir, "..")) retains a trailing slash in Julia;
    # dirname on that result returns the site instead of its parent.
    withenv("SNWJ_ROOT" => nothing) do
        defaults = Module(gensym(:InstallDefaults))
        Base.include(defaults, joinpath(@__DIR__, "..", "check_clean_depot.jl"))
        site = dirname(dirname(@__DIR__))
        @test Base.invokelatest(getproperty, defaults, :SITE) == site
        @test Base.invokelatest(getproperty, defaults, :ROOT) == dirname(site)
    end
end

@testset "Installation dependency closure" begin
    mktempdir() do root
        function project(name, uuid, deps)
            dir = joinpath(root, name * ".jl")
            mkpath(dir)
            open(joinpath(dir, "Project.toml"), "w") do io
                TOML.print(io, Dict("name"=>name, "uuid"=>uuid, "deps"=>deps))
            end
        end
        a = "00000000-0000-0000-0000-000000000001"
        b = "00000000-0000-0000-0000-000000000002"
        project("Foundation", a, Dict{String,String}())
        project("Consumer", b, Dict("Foundation"=>a))
        order, _, _ = InstallChecks.package_order(root, ["Consumer"])
        @test order == ["Foundation", "Consumer"]
        @test_throws ErrorException InstallChecks.package_order(root, ["Unknown"])
        project("Foundation", a, Dict("Consumer"=>b))
        @test_throws ErrorException InstallChecks.package_order(root, ["Consumer"])
    end
end

@testset "Regression-only benchmark selection" begin
    mktempdir() do root
        for name in ("Full", "Gated")
            dir = joinpath(root, name * ".jl", "benchmark")
            mkpath(dir)
            write(joinpath(dir, "benchmarks.jl"), "")
        end
        write(joinpath(root, "Gated.jl", "benchmark", "regression_tests.jl"), "")
        @test length(BenchmarkChecks.collect_suites(root, String[])) == 2
        @test basename.(BenchmarkChecks.collect_suites(root, String[]; regressions_only=true)) == ["Gated.jl"]
    end
end

@testset "Executable documentation gate" begin
    mktempdir() do dir
        file = joinpath(dir, "example.md")
        write(file, "```julia\nx = 2\n```\n\n```julia\n@assert x + 1 == 3\n```\n")
        count, failures, warnings = SnippetChecks.run_file(file, SnippetChecks.extract_snippets(file))
        @test count == 2
        @test isempty(failures)
        @test isempty(warnings)

        # A syntactically broken example must fail the CI gate, not be
        # reclassified as output. Following blocks must not execute.
        write(file, "```julia\nfunction broken(\n```\n\n```julia\nerror(\"must not run\")\n```\n")
        count, failures, warnings = SnippetChecks.run_file(file, SnippetChecks.extract_snippets(file))
        @test count == 0
        @test length(failures) == 1
        @test occursin("syntax", only(failures).message)
        @test isempty(warnings)

        write(file, "<!-- skip-check -->\n```julia\nfunction intentional_fragment(\n```\n")
        count, failures, _ = SnippetChecks.run_file(file, SnippetChecks.extract_snippets(file))
        @test count == 0
        @test isempty(failures)
    end
    root = SnippetChecks.ROOT
    @test SnippetChecks.matches_filter(joinpath(root, "SNA.jl", "README.md"), "SNA.jl/")
    @test !SnippetChecks.matches_filter(joinpath(root, "TSNA.jl", "README.md"), "SNA.jl/")
    @test SnippetChecks.matches_filter(joinpath(root, "SNA.jl", "docs", "src", "index.md"), "SNA.jl/docs")
    @test SnippetChecks.matches_filter(joinpath(root, "SNA.jl", "README.md"), "SNA.jl/README")
    @test_throws ErrorException SnippetChecks.main(["NotARepository.jl"])
end

@testset "Committed inventory and working snapshot fidelity" begin
    mktempdir() do root
        repo = joinpath(root, "Fixture.jl")
        mkpath(repo)
        write(joinpath(repo, "Project.toml"),
              "name = \"Fixture\"\nuuid = \"00000000-0000-0000-0000-000000000001\"\nversion = \"0.1.0\"\n")
        write(joinpath(repo, "tracked.txt"), "tracked contents")
        write(joinpath(repo, ".gitignore"), "")
        run(`git -C $repo init --quiet`)
        run(`git -C $repo add -A`)
        run(`git -C $repo -c user.name=LocalValidation -c user.email=validation@localhost -c commit.gpgsign=false commit --quiet --no-verify -m baseline`)
        rm(joinpath(repo, "Project.toml"))
        @test first(InstallChecks.package_order(root, String[]; committed=true)) == ["Fixture"]
        write(joinpath(repo, ".gitignore"), "tracked.txt\nignored.txt\n")
        write(joinpath(repo, "ignored.txt"), "untracked and ignored")
        destination = joinpath(root, "snapshot")
        revision = InstallChecks.snapshot(repo, destination, "working-tree")
        files = split(read(`git -C $destination ls-tree -r --name-only $revision`, String), '\n')
        @test "tracked.txt" in files
        @test !("ignored.txt" in files)
        @test !("Project.toml" in files)
        @test read(joinpath(destination, "tracked.txt"), String) == "tracked contents"
    end
end

module CapabilityChecks
# Load the generator's pure comparison function without running model probes or
# requiring the ecosystem environment for these stdlib-only tooling tests.
Base.include(@__MODULE__, joinpath(@__DIR__, "..", "generate_capability_matrix.jl")) do ex
    if ex isa Expr && ex.head == :function
        signature = ex.args[1]
        if signature isa Expr && signature.head == :call && first(signature.args) == :normalize
            return ex
        end
    end
    return nothing
end
end

@testset "Capability freshness preserves scientific and fixture numbers" begin
    page = """
    ## Fitted-estimator status
    Exact: yes
    ## The caveats the fits declare about themselves
    - Monte Carlo diagnostic 0.123
    ## Validation against the reference implementations
    R fixture version 1.6.6
    ## Scientific limitations
    Convergence threshold 0.25
    """
    @test CapabilityChecks.normalize(page) ==
          CapabilityChecks.normalize(replace(page, "0.123" => "0.124"))
    @test CapabilityChecks.normalize(page) !=
          CapabilityChecks.normalize(replace(page, "1.6.6" => "1.6.7"))
    @test CapabilityChecks.normalize(page) !=
          CapabilityChecks.normalize(replace(page, "0.25" => "0.35"))
    @test CapabilityChecks.normalize(page) !=
          CapabilityChecks.normalize(replace(page, "Monte Carlo diagnostic" => "Unconverged"))
end
