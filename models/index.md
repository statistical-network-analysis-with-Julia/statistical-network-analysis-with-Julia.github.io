@def title = "Families of Models"

~~~
<div class="sidebar-layout">
  <nav class="sidebar">
    <ul>
      <li><a href="#saoms">SAOMs</a></li>
      <li><a href="#rems">REMs</a></li>
      <li><a href="#ergms">ERGMs</a></li>
      <li><a href="#references">References</a></li>
    </ul>
  </nav>
  <div class="sidebar-content">

    <h1>Families of Models</h1>
    <p>This page provides theoretical and methodological background for the families of models implemented in this ecosystem. For hands-on, runnable code with output and interpretation, see the <a href="/examples/">Examples</a>.</p>

    <details open>
      <summary id="saoms"><h2>Stochastic Actor-Oriented Models (SAOMs)</h2></summary>
      <p>Stochastic Actor-Oriented Models, introduced by Snijders <a href="#ref-snijders2001">[1]</a>, model the co-evolution of networks and behavior over time. The core idea is that actors make sequential, myopic decisions to change their outgoing ties or behavior, guided by an objective function that encodes preferences for particular local network configurations.</p>
      <p>The model distinguishes three components: a <strong>rate function</strong> governing how often actors get opportunities to change, an <strong>objective function</strong> determining which changes are attractive, and a <strong>behavior function</strong> when co-evolving behavior is included. Estimation uses a Method of Moments procedure (Robbins-Monro stochastic approximation), matching simulated network statistics to observed ones across two or more time points <a href="#ref-snijders2010">[2]</a>.</p>
      <p>SAOMs are particularly suited to panel data where the same network is observed at discrete time points and the researcher is interested in disentangling selection from influence processes.</p>
      <p><strong>Implemented in:</strong> <a href="https://statistical-network-analysis-with-Julia.github.io/Siena.jl/stable/">Siena.jl</a></p>
    </details>

    <details open>
      <summary id="rems"><h2>Relational Event Models (REMs)</h2></summary>
      <p>Relational Event Models, developed by Butts <a href="#ref-butts2008">[3]</a>, analyze time-stamped sequences of interaction events between actors. Unlike panel-based models, REMs treat each individual event as a unit of analysis, modeling the instantaneous rate or probability that a specific dyad interacts at a given moment.</p>
      <p>The event rate is expressed as a function of sufficient statistics computed from the event history up to that point. These statistics capture endogenous network effects (reciprocity, repetition, transitivity) and exogenous covariates. Estimation typically proceeds via conditional logistic regression with case-control sampling, comparing the observed event to a set of non-events drawn from the risk set.</p>
      <p>REMs are appropriate for continuous-time interaction data such as email exchanges, communication logs, or any setting where the exact timing and ordering of events is recorded.</p>
      <p><strong>Implemented in:</strong> <a href="https://statistical-network-analysis-with-Julia.github.io/REM.jl/stable/">REM.jl</a>, <a href="https://statistical-network-analysis-with-Julia.github.io/Relevent.jl/stable/">Relevent.jl</a></p>
    </details>

    <details open>
      <summary id="ergms"><h2>Exponential Random Graph Models (ERGMs)</h2></summary>
      <p>Exponential Random Graph Models <a href="#ref-frank1986">[4]</a> specify a probability distribution over graphs of a given size, where the probability of observing a particular network is an exponential function of a vector of network statistics. The general form is:</p>
      <p style="text-align: center;"><em>P(Y = y) = (1/&kappa;(&theta;)) exp(&theta;&prime; g(y))</em></p>
      <p>where <em>g(y)</em> is a vector of sufficient statistics (e.g., number of edges, triangles, degree distributions), <em>&theta;</em> is the parameter vector, and <em>&kappa;(&theta;)</em> is a normalizing constant that is typically intractable for all but the smallest networks.</p>
      <p>Estimation relies on either <strong>Maximum Pseudolikelihood Estimation (MPLE)</strong> <a href="#ref-strauss1990">[5]</a>, which approximates the likelihood by treating dyads as conditionally independent, or <strong>Monte Carlo Maximum Likelihood Estimation (MCMLE)</strong> <a href="#ref-hunter2006">[6]</a>, which uses MCMC sampling to approximate the ratio of normalizing constants. Goodness of fit is assessed by simulating networks from the fitted model and comparing their properties to the observed network <a href="#ref-hunter2008">[7]</a>.</p>
      <p>The ERGM framework has been extended in several directions: temporal ERGMs (TERGMs) for longitudinal network data <a href="#ref-hanneke2010">[8]</a>, valued ERGMs for count or rank data <a href="#ref-krivitsky2012">[9]</a>, ego-centric ERGMs for inference from sampled ego-network data <a href="#ref-krivitsky2023">[10]</a>, and multilayer ERGMs for networks with multiple relation types <a href="#ref-krivitsky2020">[11]</a>.</p>
      <p><strong>Implemented in:</strong> <a href="https://statistical-network-analysis-with-Julia.github.io/ERGM.jl/stable/">ERGM.jl</a> and extensions (<a href="https://statistical-network-analysis-with-Julia.github.io/TERGM.jl/stable/">TERGM.jl</a>, <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMCount.jl/stable/">ERGMCount.jl</a>, <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMEgo.jl/stable/">ERGMEgo.jl</a>, <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMMulti.jl/stable/">ERGMMulti.jl</a>, <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMRank.jl/stable/">ERGMRank.jl</a>, <a href="https://statistical-network-analysis-with-Julia.github.io/ERGMUserterms.jl/stable/">ERGMUserterms.jl</a>)</p>
    </details>

    <details open>
      <summary id="references"><h2>References</h2></summary>
      <ol class="references">
        <li id="ref-snijders2001">Snijders, T. A. B. (2001). The statistical evaluation of social network dynamics. <em>Sociological Methodology</em>, 31(1), 361&ndash;395.</li>
        <li id="ref-snijders2010">Snijders, T. A. B., van de Bunt, G. G., &amp; Steglich, C. E. G. (2010). Introduction to stochastic actor-based models for network dynamics. <em>Social Networks</em>, 32(1), 44&ndash;60.</li>
        <li id="ref-butts2008">Butts, C. T. (2008). A relational event framework for social action. <em>Sociological Methodology</em>, 38(1), 155&ndash;200.</li>
        <li id="ref-frank1986">Frank, O. &amp; Strauss, D. (1986). Markov graphs. <em>Journal of the American Statistical Association</em>, 81(395), 832&ndash;842.</li>
        <li id="ref-strauss1990">Strauss, D. &amp; Ikeda, M. (1990). Pseudolikelihood estimation for social networks. <em>Journal of the American Statistical Association</em>, 85(409), 204&ndash;212.</li>
        <li id="ref-hunter2006">Hunter, D. R. &amp; Handcock, M. S. (2006). Inference in curved exponential family models for networks. <em>Journal of Computational and Graphical Statistics</em>, 15(3), 565&ndash;583.</li>
        <li id="ref-hunter2008">Hunter, D. R., Goodreau, S. M., &amp; Handcock, M. S. (2008). Goodness of fit of social network models. <em>Journal of the American Statistical Association</em>, 103(481), 248&ndash;258.</li>
        <li id="ref-hanneke2010">Hanneke, S., Fu, W., &amp; Xing, E. P. (2010). Discrete temporal models of social networks. <em>Electronic Journal of Statistics</em>, 4, 585&ndash;605.</li>
        <li id="ref-krivitsky2012">Krivitsky, P. N. (2012). Exponential-family random graph models for valued networks. <em>Electronic Journal of Statistics</em>, 6, 1100&ndash;1128.</li>
        <li id="ref-krivitsky2023">Krivitsky, P. N., Morris, M., &amp; Handcock, M. S. (2023). Inference for social network models from egocentrically sampled data, with application to understanding persistent racial disparities in HIV prevalence in the US. <em>The Annals of Applied Statistics</em>, 17(4), 2991&ndash;3014.</li>
        <li id="ref-krivitsky2020">Krivitsky, P. N., Koehly, L. M., &amp; Marcum, C. S. (2020). Exponential-family random graph models for multi-layer networks. <em>Psychometrika</em>, 85(3), 630&ndash;659.</li>
      </ol>
    </details>

  </div>
</div>
~~~
