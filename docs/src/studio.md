# MapperStudio

MapperStudio is the ecosystem's local visual workbench. A Julia backend runs
the analyses; the browser provides interactive graphs, linked projections,
row selections and population comparison. It has its own package environment
in [its own repository](https://github.com/JuliaTDA/MapperStudio.jl), so the
umbrella package gains no web dependencies.

With Julia 1.12 or newer, press `]` to enter package mode and install:

```julia
pkg> app add https://github.com/JuliaTDA/MapperStudio.jl
```

Then start the app from your terminal:

```sh
mapperstudio
```

Open `http://localhost:8090`. Start with an included example, or import a CSV.
Choose geometry variables, scaling, metric, lenses, cover and clustering;
construct Mapper; select a population; then compare its feature distributions
with the rest of the data or another saved group. Color and layout are display
controls, separate from the model parameters.

Additional views cover Rips persistence (diagrams, barcodes, Betti curves),
cover-parameter sensitivity, ToMATo, temporal embeddings/window PH, cubical
image filtrations and Euler curves, and finite-grid function-Rips surfaces.
Workspaces preserve data, groups and configurations; JSON, CSV, SVG and Julia
analysis scripts provide reproducible exports.

The app uses explicit bounds: 3,000 rows, 80 geometry variables, at most 300
H0/H1 landmarks or 80 for H2, and 28 for multiparameter calculations. It does
not claim proprietary Ayasdi lens equivalence or million-row enterprise scale.
Population tests selected after visual exploration are exploratory; BH does
not account for selection bias. The displayed graph cycle rank is distinct
from persistent homology of the data.

The app's [README](https://github.com/JuliaTDA/MapperStudio.jl#install-and-start)
contains setup, usage and full limits. Its source-local `docs/ayasdi-research.md`
records the Ayasdi investigation and functionality mapping, and `docs/api.md`
documents the REST interface. The complete research is also served at `/research`.
