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

module WorkflowChecks
include(joinpath(@__DIR__, "..", "sync_workflows.jl"))
end

module RegistryChecks
include(joinpath(@__DIR__, "..", "setup_registry.jl"))
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

@testset "Committed snapshots are checkouts Pkg can add" begin
    # Pkg refuses a local URL without a .git directory, which made the default
    # --source=committed mode fail at its first package with a bare clone.
    mktempdir() do root
        repo = joinpath(root, "Fixture.jl")
        mkpath(repo)
        write(joinpath(repo, "Project.toml"),
              "name = \"Fixture\"\nuuid = \"00000000-0000-0000-0000-000000000001\"\nversion = \"0.1.0\"\n")
        write(joinpath(repo, "tracked.txt"), "committed contents")
        run(`git -C $repo init --quiet`)
        run(`git -C $repo add -A`)
        run(`git -C $repo -c user.name=LocalValidation -c user.email=validation@localhost -c commit.gpgsign=false commit --quiet --no-verify -m baseline`)
        write(joinpath(repo, "tracked.txt"), "uncommitted edit")
        destination = joinpath(root, "snapshot")
        revision = InstallChecks.snapshot(repo, destination, "committed")
        @test revision == readchomp(`git -C $repo rev-parse HEAD`)
        @test isdir(joinpath(destination, ".git"))
        @test readchomp(`git -C $destination rev-parse HEAD`) == revision
        @test read(joinpath(destination, "tracked.txt"), String) == "committed contents"
    end
end

# The run: | block of a workflow step, dedented, as the shell receives it
function step_script(text, name)
    start = findfirst("- name: $name\n", text)
    start === nothing && error("No step named $name")
    lines = split(text[last(start)+1:end], '\n')
    i = findfirst(==("        run: |"), lines)
    i === nothing && error("No run block for step $name")
    body = String[]
    for line in lines[i+1:end]
        # A YAML block scalar keeps its blank lines; the first less-indented line ends it
        if isempty(strip(line))
            push!(body, "")
            continue
        end
        startswith(line, "          ") || break
        push!(body, line[11:end])
    end
    return rstrip(join(body, '\n'))
end

@testset "Workflow templates and the layout block" begin
    templates = joinpath(@__DIR__, "..", "workflows")
    layout = read(joinpath(templates, "layout-step.yml"), String)
    @test startswith(layout, WorkflowChecks.BEGIN_MARK)
    @test endswith(layout, WorkflowChecks.END_MARK)
    # The Julia the steps run is valid Julia
    for (file, name) in (("layout-step.yml", "Reconstruct the ecosystem layout from [sources]"),
                         ("Downstream.yml", "Dispatch the CI of every dependent package"))
        script = step_script(read(joinpath(templates, file), String), name)
        @test !Meta.isexpr(Meta.parseall(script), :error)
        @test !any(ex -> Meta.isexpr(ex, (:error, :incomplete)), Meta.parseall(script).args)
    end
    docs = WorkflowChecks.documentation_workflow("Fixture")
    @test occursin("path: Fixture.jl\n", docs)
    @test occursin(layout, docs)
    @test !occursin("__PKG__", docs) && !occursin("__LAYOUT_STEP__", docs)
    # The block is replaced in place; everything else in CI.yml is kept
    ci = "steps:\n      - uses: actions/checkout@v7\n        with:\n          path: Fixture.jl\n" *
         WorkflowChecks.BEGIN_MARK * " (old)\n      - run: echo old\n" * WorkflowChecks.END_MARK *
         "      - name: Run tests\n"
    updated = WorkflowChecks.with_layout(ci)
    @test updated == replace(ci, r"      # >>> ecosystem layout.*# <<< ecosystem layout\n"s => layout)
    @test WorkflowChecks.with_layout(updated) == updated
    @test WorkflowChecks.with_layout("steps:\n      - run: echo\n") === nothing
    @test isempty(WorkflowChecks.problems("Fixture", "CI.yml", updated))
    # A threaded cell is recognised in each of the three forms the packages use
    @test WorkflowChecks.has_threaded_cell("    env:\n      JULIA_NUM_THREADS: 4\n")
    @test WorkflowChecks.has_threaded_cell("          JULIA_NUM_THREADS: \${{ (matrix.version == '1') && '4' || '1' }}\n")
    @test WorkflowChecks.has_threaded_cell("            threads: '4'\n    env:\n      JULIA_NUM_THREADS: \${{ matrix.threads || '1' }}\n")
    @test !WorkflowChecks.has_threaded_cell("      JULIA_NUM_THREADS: \${{ matrix.threads || 1 }}\n")
    @test !WorkflowChecks.has_threaded_cell("      # JULIA_NUM_THREADS: 4\n      JULIA_NUM_THREADS: 1\n")
    stale = "          for pkg in NetworkCore ERGM; do\n            git clone\n"
    @test length(WorkflowChecks.problems("Fixture", "CI.yml", updated * stale)) == 1
    @test length(WorkflowChecks.problems("Fixture", "CI.yml", "run: julia SNA.jl/.github/checkout_sources.jl\n")) == 1
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

# Write a Project.toml from a Dict, creating its directory
function write_project(dir, contents)
    mkpath(dir)
    open(io -> TOML.print(io, contents), joinpath(dir, "Project.toml"), "w")
end

@testset "Sibling [sources] entries must be path sources" begin
    mktempdir() do root
        siblings = Set(["Core", "Model"])
        write_project(joinpath(root, "Core.jl"), Dict("name" => "Core"))
        write_project(joinpath(root, "Model.jl"),
                      Dict("name" => "Model", "sources" => Dict("Core" => Dict("path" => "../Core.jl"))))
        write_project(joinpath(root, "Model.jl", "docs"),
                      Dict("sources" => Dict("Core" => Dict("path" => "../../Core.jl"),
                                             "Model" => Dict("path" => ".."))))
        @test isempty(WorkflowChecks.source_problems(root, "Model", siblings))
        # A non-sibling may come from anywhere
        write_project(joinpath(root, "Model.jl", "benchmark"),
                      Dict("sources" => Dict("Other" => Dict("url" => "https://example.org/Other.jl"))))
        @test isempty(WorkflowChecks.source_problems(root, "Model", siblings))
        # The Siena incident: a Pkg command rewrote a sibling source as a URL
        write_project(joinpath(root, "Model.jl", "benchmark"),
                      Dict("sources" => Dict("Core" => Dict("url" => "https://github.com/org/Core.jl",
                                                            "rev" => "main"))))
        found = WorkflowChecks.source_problems(root, "Model", siblings)
        @test length(found) == 1 && occursin("benchmark/Project.toml: [sources] Core is not a path source", only(found))
        # A path source that misses the sibling checkout
        write_project(joinpath(root, "Model.jl", "benchmark"),
                      Dict("sources" => Dict("Core" => Dict("path" => "../Core.jl"))))
        found = WorkflowChecks.source_problems(root, "Model", siblings)
        @test length(found) == 1 && occursin("points at ../Core.jl", only(found))
        # Built documentation and hidden directories are not package projects
        rm(joinpath(root, "Model.jl", "benchmark"); recursive=true)
        bad = Dict("sources" => Dict("Core" => Dict("url" => "x")))
        write_project(joinpath(root, "Model.jl", "docs", "build"), bad)
        write_project(joinpath(root, "Model.jl", ".git", "x"), bad)
        @test isempty(WorkflowChecks.source_problems(root, "Model", siblings))
    end
end

@testset "Only the DOWNSTREAM packages carry a Downstream workflow" begin
    downstream = read(joinpath(@__DIR__, "..", "workflows", "Downstream.yml"), String)
    mktempdir() do dir
        write(joinpath(dir, "CI.yml"), "name: CI\n")
        @test isempty(WorkflowChecks.downstream_problems("SNA", dir))
        write(joinpath(dir, "Downstream.yml"), downstream)
        @test length(WorkflowChecks.downstream_problems("SNA", dir)) == 1
        for name in WorkflowChecks.DOWNSTREAM
            @test isempty(WorkflowChecks.downstream_problems(name, dir))
        end
        # A renamed copy is still the dispatcher
        mv(joinpath(dir, "Downstream.yml"), joinpath(dir, "dependents.yml"))
        @test length(WorkflowChecks.downstream_problems("SNA", dir)) == 1
    end
end

@testset "Downstream CI reports NOT DISPATCHED and waits for the runs" begin
    text = read(joinpath(@__DIR__, "..", "workflows", "Downstream.yml"), String)
    # Without the token the job fails, and its summary says why
    missing_token = step_script(text, "Fail when the dispatch token is missing")
    @test occursin("NOT DISPATCHED", missing_token)
    @test occursin("GITHUB_STEP_SUMMARY", missing_token)
    @test occursin(r"(?m)^exit 1$", missing_token)
    @test occursin("if: env.GH_TOKEN == ''\n        run: |", text)
    # The run of a dispatched CI is the earliest workflow_dispatch run created
    # after the dispatch; earlier runs belong to someone else.
    script = Meta.parseall(step_script(text, "Dispatch the CI of every dependent package"))
    finder = only(ex for ex in script.args
                  if Meta.isexpr(ex, :function) && ex.args[1].args[1] == :find_run)
    stub = Module(:DownstreamStub)
    Core.eval(stub, :(using Dates))
    Core.eval(stub, :(org = "org"))
    Core.eval(stub, :(gh(args...) = join([
        "11\t2026-10-06T09:00:00Z\tcompleted\tfailure\thttps://x/11",
        "13\t2026-10-06T10:02:00Z\tin_progress\t\thttps://x/13",
        "12\t2026-10-06T10:01:00Z\tcompleted\tsuccess\thttps://x/12"], '\n')))
    Core.eval(stub, finder)
    found = Base.invokelatest(stub.find_run, "Pkg.jl", stub.DateTime(2026, 10, 6, 10))
    @test found.id == "12" && found.state == "completed" && found.conclusion == "success"
    pending = Base.invokelatest(stub.find_run, "Pkg.jl", stub.DateTime(2026, 10, 6, 10, 1, 30))
    @test pending.id == "13" && pending.state == "in_progress" && pending.conclusion == ""
    @test Base.invokelatest(stub.find_run, "Pkg.jl", stub.DateTime(2026, 10, 6, 11)) === nothing
    # Anything but success fails the job, with every dependent in the table
    @test occursin("length(passed) == length(status) ||", text)
    @test occursin("timeout-minutes:", text)
end

@testset "Registration order is derived from the Project.toml graph" begin
    mktempdir() do root
        write_project(joinpath(root, "Core.jl"), Dict("name" => "Core"))
        write_project(joinpath(root, "Model.jl"),
                      Dict("name" => "Model", "sources" => Dict("Core" => Dict("path" => "../Core.jl"))))
        write_project(joinpath(root, "Events.jl"),
                      Dict("name" => "Events",
                           "sources" => Dict("Core" => Dict("path" => "../Core.jl"),
                                             "Model" => Dict("path" => "../Model.jl"))))
        @test RegistryChecks.registration_order(root, ["Events", "Model", "Core"]) ==
              ["Core.jl", "Model.jl", "Events.jl"]
        @test_throws ErrorException RegistryChecks.registration_order(root, ["Events", "Model"])
        @test_throws ErrorException RegistryChecks.registration_order(root, ["Core", "Missing"])
        write_project(joinpath(root, "Core.jl"),
                      Dict("name" => "Core", "sources" => Dict("Events" => Dict("path" => "../Events.jl"))))
        @test_throws ErrorException RegistryChecks.registration_order(root, ["Events", "Model", "Core"])
    end
    # On the ecosystem itself: every package once, each after what it sources
    root = dirname(dirname(dirname(@__DIR__)))
    packages = RegistryChecks.workspace_packages()
    if all(name -> isfile(joinpath(root, "$name.jl", "Project.toml")), packages)
        order = RegistryChecks.registration_order(root)
        @test sort(order) == sort(packages .* ".jl")
        @test first(order) == "NetworkCore.jl"
        position = Dict(name => i for (i, name) in enumerate(order))
        for name in packages
            project = TOML.parsefile(joinpath(root, "$name.jl", "Project.toml"))
            for dep in keys(get(project, "sources", Dict()))
                dep == name || @test position["$dep.jl"] < position["$name.jl"]
            end
        end
    else
        @info "Sibling checkouts missing; the registration order is checked on fixtures only"
    end
end
