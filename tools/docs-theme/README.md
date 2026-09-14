# Package documentation theme

`snwj-docs.css` and `snwj-docs.js` are the canonical assets for the 15 Documenter
sites. Each package checks in a local copy under `docs/src/assets/`, so building
one package never needs this site repository or a theme service.

From the site checkout, synchronize or verify the copies with Julia 1.12+:

```bash
julia tools/sync_documentation_theme.jl
julia tools/sync_documentation_theme.jl --check
```

An optional first argument identifies a different sibling workspace. The package
list comes from `tools/workspace/Project.toml`; no second package list is maintained.
The sync command updates only these two assets, preserving package logos and pages.

Each `docs/make.jl` loads the local assets through `Documenter.HTML(assets=...)`,
sets its canonical base to `https://statistical-network-analysis-with-Julia.github.io/<Package>.jl/dev/`,
and uses `DOCS_PRETTY_URLS=true` to allow production-style paths without enabling CI.
Keep `warnonly=false` and `checkdocs=:exports`. The theme makes no deployment calls.

The ecosystem bar links to `/`, `/packages/`, `/getting-started/`, and `/capabilities/`.
These share the organization site's origin; use the combined site preview when
checking them locally. A standalone package build still works, but does not serve
the umbrella destinations itself. The static footer supplies the same links when
JavaScript is unavailable. Native Documenter search, sidebar, version selector,
theme selection, code copying, and docstring expansion remain in place.

The browser enhancement gives the version selector an accessible name and makes
actual overflowing code/table containers keyboard focusable, updating after syntax
highlighting, font loading, resizing, and docstring expansion. Non-overflowing
examples do not acquire extra tab stops. Native docstring summaries retain their
IDs and disclosure behavior; their nested binding link is moved into a visible
"Permalink" row inside the expanded body so a link is no longer nested in a button.
Source links are preserved. Light syntax colors and dark admonition headings have
readable contrast. These DOM enhancements run with JavaScript; disabling it retains
Documenter's original markup and the static ecosystem footer.

The primary light palette uses warm off-white, forest green, and a restrained
violet accent. The primary dark palette has corresponding dark surfaces and light
text. Alternate Catppuccin choices retain their native document/sidebar colors.
Typography and spacing are shared across all themes. No remote fonts or script
dependencies are added by this layer; Documenter's own assets are unchanged.

Standard Markdown is the preferred content format. Optional HTML hooks are
`.snwj-lead`, `.snwj-kicker`, and `.snwj-card-grid` containing `.snwj-card` elements.
Use descriptive link text and real headings inside cards. Do not duplicate the
global ecosystem bar in page content.

Absolute links to the ecosystem’s own GitHub Pages host are normalized to
host-relative paths in the browser, so older cross-package references stay in
the combined preview. Hash-only API permalinks and external scholarly/source
links retain their original targets.
