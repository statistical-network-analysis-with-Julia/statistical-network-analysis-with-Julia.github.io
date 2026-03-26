# statistical-network-analysis-with-Julia.github.io

Organization website for [Statistical Network Analysis with Julia](https://statistical-network-analysis-with-julia.github.io/), built with [Franklin.jl](https://franklinjl.org/).

**Live site:** <https://statistical-network-analysis-with-julia.github.io/>

## Local Development

```bash
cd statistical-network-analysis-with-Julia.github.io
julia --project -e 'using Pkg; Pkg.instantiate()'
julia --project -e 'using Franklin; serve()'
```

Then open <http://localhost:8000> in your browser.

## Deployment

The site is automatically built and deployed to GitHub Pages via the `deploy.yml` workflow on every push to `main`.
