@def title = "Statistical Network Analysis with Julia"

~~~
<div class="hero">
  <div class="container text-center">
    <h1>Statistical Network Analysis with Julia</h1>
    <p class="lead">Fit the most prominent statistical models to networks. In Julia.</p>
  </div>
</div>
~~~

This project provides Julia implementations of established families of models for the statistical analysis of networks. The ecosystem covers network construction, descriptive analysis, Exponential Random Graph Models (ERGMs) and their extensions, Relational Event Models (REMs), and Stochastic Actor-Oriented Models (SAOMs).

All packages require **Julia 1.12+** and are MIT-licensed. If you know the R statnet stack or RSiena, start with the [migration guide](/migration/).

**Installing**: the packages are not yet in the General registry. Add them by URL in dependency order (each README has the ordered `Pkg.add(url=...)` block), or clone all repositories side by side and start Julia with the root workspace project (`julia --project=.` in the clone root) — the `[sources]` path dependencies wire everything together. A LocalRegistry is being prepared (this site repository's `tools/setup_registry.jl`, run after the packages are committed/tagged) so plain `Pkg.add("ERGM")` will eventually work.

~~~
<h3 class="section-title">Stochastic Actor-Oriented Models (SAOMs)</h3>
<div class="pkg-grid">
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/Siena.jl">Siena.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Stochastic actor-oriented models (SAOM) for longitudinal network analysis with 150+ effects.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/Siena.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/Siena.jl/stable/">Docs</a>
      <span class="r-port">based on R RSiena</span>
    </div>
  </div>
</div>

<h3 class="section-title">Relational Event Models (REMs)</h3>
<div class="pkg-grid">
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/REM.jl">REM.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Relational event models for time-stamped interaction sequences with 25+ statistics and case-control sampling.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/REM.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/REM.jl/stable/">Docs</a>
      <span class="r-port">based on R eventnet</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/Relevent.jl">Relevent.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Extended relational event model features with ordinal BPM and timing models.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/Relevent.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/Relevent.jl/stable/">Docs</a>
      <span class="r-port">based on R relevent</span>
    </div>
  </div>
</div>

<h3 class="section-title">Exponential Random Graph Models (ERGMs) and Extensions</h3>
<div class="pkg-grid">
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/ERGM.jl">ERGM.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>ERGM fitting via MPLE and MCMLE, network simulation, and goodness-of-fit diagnostics.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/ERGM.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/ERGM.jl/stable/">Docs</a>
      <span class="r-port">based on R ergm</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/TERGM.jl">TERGM.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Temporal ERGMs with formation/dissolution dynamics and separable models (STERGM).</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/TERGM.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/TERGM.jl/stable/">Docs</a>
      <span class="r-port">based on R tergm</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl">ERGMCount.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>ERGMs for count-valued (weighted) networks with Poisson, geometric, and binomial references.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/ERGMCount.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMCount.jl/stable/">Docs</a>
      <span class="r-port">based on R ergm.count</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl">ERGMEgo.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>ERGMs from ego-centric network data with pseudo-population inference.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/ERGMEgo.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMEgo.jl/stable/">Docs</a>
      <span class="r-port">based on R ergm.ego</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl">ERGMMulti.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>ERGMs for multilayer and multilevel networks with cross-layer terms.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/ERGMMulti.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMMulti.jl/stable/">Docs</a>
      <span class="r-port">based on R ergm.multi</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl">ERGMRank.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>ERGMs for rank-order relational data.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/ERGMRank.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMRank.jl/stable/">Docs</a>
      <span class="r-port">based on R ergm.rank</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl">ERGMUserterms.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Tools for developing custom ERGM terms with validation and benchmarking utilities.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/ERGMUserterms.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMUserterms.jl/stable/">Docs</a>
      <span class="r-port">based on R ergm.userterms</span>
    </div>
  </div>
</div>

<h3 class="section-title">Infrastructure</h3>
<div class="pkg-grid">
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/Networks.jl">Networks.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Core network data structures with vertex, edge, and network-level attributes. Implements the Graphs.jl interface.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/Networks.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/Networks.jl/stable/">Docs</a>
      <span class="r-port">based on R network</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/SNA.jl">SNA.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Social network analysis: centrality, cohesion, equivalence, and network-level measures.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/SNA.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/SNA.jl/stable/">Docs</a>
      <span class="r-port">based on R sna</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/NetworkDynamic.jl">NetworkDynamic.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Dynamic network data structures with activity spells, time-varying attributes, and network extraction.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/NetworkDynamic.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/NetworkDynamic.jl/stable/">Docs</a>
      <span class="r-port">based on R networkDynamic</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/TSNA.jl">TSNA.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Temporal social network analysis: temporal centrality, time-respecting paths, reachability.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/TSNA.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/TSNA.jl/stable/">Docs</a>
      <span class="r-port">based on R tsna</span>
    </div>
  </div>
  <div class="pkg-card">
    <h4><a href="https://github.com/statistical-network-analysis-with-Julia/NDTV.jl">NDTV.jl</a> <span class="badge-julia">Julia</span></h4>
    <p>Network dynamic temporal visualization with layout algorithms and animation export.</p>
    <div class="links">
      <a href="https://github.com/statistical-network-analysis-with-Julia/NDTV.jl">GitHub</a>
      <a href="https://statistical-network-analysis-with-Julia.github.io/NDTV.jl/stable/">Docs</a>
      <span class="r-port">based on R ndtv</span>
    </div>
  </div>
</div>
~~~
