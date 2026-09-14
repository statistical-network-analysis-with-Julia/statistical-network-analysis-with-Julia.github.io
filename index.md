@def title = "Statistical Network Analysis with Julia"
@def hascode = true

~~~
<div class="home-page">
<section class="hero" aria-labelledby="hero-title">
  <div class="hero-copy"><span class="kicker">Statistical network analysis · Julia</span>
    <h1 id="hero-title">Study structure.<br>Model <em>change.</em></h1>
    <p>Build networks, describe their patterns, and fit statistical models of relationships and interactions. A connected ecosystem of Julia packages, with examples to guide your analysis.</p>
    <div class="actions"><a class="button button-primary" href="/getting-started/">Start an analysis <span aria-hidden="true">→</span></a><a class="button button-secondary" href="/packages/">Explore packages</a></div>
  </div>
  <figure class="hero-figure"><div class="figure-header"><span>CONNECTED DATA</span><span>01 / NETWORK STRUCTURE</span></div>
<svg class="hero-network" viewBox="0 0 450 370" role="img" aria-labelledby="network-title network-description">
<title id="network-title">Actors connected by relationships</title><desc id="network-description">An illustrative network with clustered relationships and actors that connect different groups. This is a schematic, not an empirical dataset.</desc>
<g stroke="#bbcbb6" stroke-width="1.4"><line x1="60" y1="132" x2="109" y2="74"/>
<line x1="60" y1="132" x2="150" y2="160"/>
<line x1="60" y1="132" x2="75" y2="278"/>
<line x1="109" y1="74" x2="150" y2="160"/>
<line x1="109" y1="74" x2="205" y2="106"/>
<line x1="150" y1="160" x2="205" y2="106"/>
<line x1="150" y1="160" x2="132" y2="237"/>
<line x1="205" y1="106" x2="259" y2="58"/>
<line x1="205" y1="106" x2="318" y2="129"/>
<line x1="205" y1="106" x2="266" y2="196"/>
<line x1="259" y1="58" x2="318" y2="129"/>
<line x1="259" y1="58" x2="363" y2="91"/>
<line x1="318" y1="129" x2="363" y2="91"/>
<line x1="318" y1="129" x2="266" y2="196"/>
<line x1="318" y1="129" x2="405" y2="184"/>
<line x1="363" y1="91" x2="405" y2="184"/>
<line x1="334" y1="224" x2="266" y2="196"/>
<line x1="334" y1="224" x2="382" y2="287"/>
<line x1="334" y1="224" x2="405" y2="184"/>
<line x1="266" y1="196" x2="208" y2="258"/>
<line x1="266" y1="196" x2="132" y2="237"/>
<line x1="208" y1="258" x2="132" y2="237"/>
<line x1="208" y1="258" x2="230" y2="330"/>
<line x1="132" y1="237" x2="75" y2="278"/>
<line x1="382" y1="287" x2="405" y2="184"/>
<line x1="382" y1="287" x2="230" y2="330"/></g>
<g fill="none" stroke="#d3decd"><circle cx="205" cy="106" r="23"/><circle cx="266" cy="196" r="24"/><circle cx="132" cy="237" r="23"/></g>
<g><circle cx="60" cy="132" r="6" fill="#2e6852"/>
<circle cx="109" cy="74" r="6" fill="#2e6852"/>
<circle cx="150" cy="160" r="6" fill="#2e6852"/>
<circle cx="205" cy="106" r="10" fill="#7257a8"/>
<circle cx="259" cy="58" r="6" fill="#2e6852"/>
<circle cx="318" cy="129" r="6" fill="#2e6852"/>
<circle cx="363" cy="91" r="6" fill="#2e6852"/>
<circle cx="334" cy="224" r="6" fill="#2e6852"/>
<circle cx="266" cy="196" r="10" fill="#7257a8"/>
<circle cx="208" cy="258" r="6" fill="#2e6852"/>
<circle cx="132" cy="237" r="10" fill="#7257a8"/>
<circle cx="75" cy="278" r="6" fill="#2e6852"/>
<circle cx="382" cy="287" r="6" fill="#2e6852"/>
<circle cx="405" cy="184" r="6" fill="#2e6852"/>
<circle cx="230" cy="330" r="6" fill="#2e6852"/></g><g font-family="monospace" font-size="9" fill="#52675e"><text x="22" y="113">ACTORS</text><text x="318" y="333">RELATIONS</text></g></svg>
    <figcaption class="figure-caption"><span>Describe · fit · simulate · diagnose</span><span>Illustrative network</span></figcaption>
  </figure>
</section>
<div class="fact-strip"><span><strong>15</strong> interoperable packages</span><span><strong>Julia 1.12+</strong></span><span><strong>MIT</strong> licensed</span><span>Development documentation · v0.2.0 unreleased</span></div>
<section class="home-section" aria-labelledby="workflow-title">
  <div class="section-heading"><div><span class="kicker">Start with your data</span><h2 id="workflow-title">What are you studying?</h2></div><a href="/models/">Compare model families →</a></div>
  <div class="workflow-grid">
    <a class="workflow-card" href="/examples/describing-network-structure/"><span class="card-number">01 / NETWORK SNAPSHOTS</span><h3>Relationships and structure</h3><p>Explore density, centrality and cohesion. Then model observed ties with an ERGM.</p><span class="card-action">Networks · SNA · ERGM <span aria-hidden="true">→</span></span></a>
    <a class="workflow-card" href="/examples/modelling-network-change/"><span class="card-number">02 / NETWORK PANELS</span><h3>Networks observed over time</h3><p>Study tie formation and persistence, or model actors' opportunities to change their ties.</p><span class="card-action">TERGM · Siena <span aria-hidden="true">→</span></span></a>
    <a class="workflow-card" href="/examples/modelling-interaction-events/"><span class="card-number">03 / INTERACTION SEQUENCES</span><h3>Who interacts with whom, next?</h3><p>Model ordered interactions or event timing, with explicit risk sets and observation windows.</p><span class="card-action">REM · Relevent <span aria-hidden="true">→</span></span></a>
  </div>
</section>
<section class="home-section analysis-feature" aria-labelledby="first-analysis-title">
  <div><span class="kicker">A first look at real data</span><h2 id="first-analysis-title">Sixteen families.<br>A network of alliances.</h2><p>Load the bundled Florentine marriage network and calculate its density and centrality. Follow the example to interpret the measures and compare relationships.</p><a href="/examples/describing-network-structure/">Walk through the analysis →</a></div><div>
~~~

```julia
using Networks, SNA

net = load_dataset(:florentine_marriage)
gden(net)
degree_centrality(net)
```

~~~
  </div>
</section>
<section class="home-section project-note" aria-label="About this ecosystem">
  <div><h3>Familiar methods, explicit scope</h3><p>The packages draw on R's statnet ecosystem and RSiena. Coverage varies by package and estimator. Read the capability notes for supported data, uncertainty estimates and remaining limitations.</p><a href="/capabilities/">Check capabilities and limitations →</a></div>
  <div><h3>A shared foundation for your workflow</h3><p>Networks.jl connects data structures, missing-data policies and result conventions across the ecosystem. Explore the package documentation for the next step in your analysis.</p><a href="/packages/">Browse all 15 packages →</a></div>
</section>
</div>
~~~
