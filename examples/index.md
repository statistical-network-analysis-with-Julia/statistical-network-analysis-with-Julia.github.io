@def title = "Worked examples"

# From data to interpretation

Four executable analyses introduce network structure, cross-sectional models,
interaction sequences and change over time. Each example uses bundled empirical
data, explains the model's question, and identifies limits on interpretation.

New to the ecosystem? [Prepare your Julia environment](/getting-started/)
first. Read [the method comparison](/models/) when choosing a model, or use
[the package directory](/packages/) to go directly to a reference guide.

~~~
<div class="example-grid">
  <a class="example-card" href="/examples/describing-network-structure/"><span class="kicker">Networks · SNA / Florentine families</span><h2>Describe network structure</h2><p>Measure density and centrality, compare marriage and business ties, and interpret a QAP association test.</p></a>
  <a class="example-card" href="/examples/modelling-cross-sectional-data/"><span class="kicker">ERGM / Florentine marriage ties</span><h2>Model an observed network</h2><p>Choose binary-network statistics, fit an ERGM, and distinguish pseudolikelihood from MCMC likelihood inference.</p></a>
  <a class="example-card" href="/examples/modelling-interaction-events/"><span class="kicker">REM · Relevent / WTC radio events</span><h2>Model interaction sequences</h2><p>Compare risk-set approaches using ordered radio interactions. Keep event order distinct from elapsed time.</p></a>
  <a class="example-card" href="/examples/modelling-network-change/"><span class="kicker">TERGM · Siena / s50 friendship panels</span><h2>Study networks over time</h2><p>Fit formation and persistence, inspect estimation diagnostics, then continue to the actor-oriented workflow.</p></a>
</div>
~~~

The package documentation expands these examples into data preparation, model
specification, API references and diagnostics. [Capabilities and limitations](/capabilities/)
records which estimators and reference comparisons are currently supported.
