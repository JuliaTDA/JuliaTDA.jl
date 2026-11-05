# JuliaTDA Studio

The standalone application is now maintained at
[MapperStudio.jl](https://github.com/JuliaTDA/MapperStudio.jl).
With Julia 1.12 or newer, install it in package mode with
`app add https://github.com/JuliaTDA/MapperStudio.jl`, then run `mapperstudio`
in your terminal. The instructions below describe the original workspace copy.

A local Mapper and TDA workbench with a Julia scientific backend and a browser
interface in Portuguese. It reconstructs the main Ayasdi-style exploration
workflow using this ecosystem's implementations, with explicit scientific
limits and no dependency on an external service.

![Interactive Mapper, linked projection and population inspector](docs/screenshots/desktop.png)

## Start

From the ecosystem directory containing the sibling Julia packages:

```bash
julia --startup-file=no JuliaTDA.jl/apps/MapperStudio/scripts/setup.jl
julia --startup-file=no --project=JuliaTDA.jl/apps/MapperStudio --threads=auto JuliaTDA.jl/apps/MapperStudio/scripts/serve.jl
```

Open **[http://localhost:8090](http://localhost:8090)**. Use
`MAPPER_STUDIO_PORT=8091` to choose another port. Ctrl+C stops the server. Julia
1.10 or newer is required. Setup develops the existing sibling packages in an
isolated environment; package registration is not required. The first analysis
includes Julia's compilation time. All browser assets are local: no CDN, font,
JavaScript library, or online calculation is needed after setup.
Use the same Julia version for setup and execution. If you switch Julia minor
versions, resolve dependencies in a fresh app environment; a generated Manifest
from another minor version may contain incompatible transitive package versions.

## Explore

1. Start with the three-branch example, a circle, a torus, three populations,
   or the real diabetes dataset already present in the reproduction directory.
   Import your own CSV/TSV using **Importar CSV**.
2. Choose numeric variables, scaling, distance, one or two lenses, resolution,
   gain, cover, clustering and an edge rule. **Construir Mapper** applies the
   settings. Color/layout changes update the view without recomputation.
3. Click nodes, Shift-click to extend selection, or select an area. The linked
   PCA projection and original-data table use the same original row IDs. Drag
   nodes, pan, zoom or use keyboard Tab/Enter. Save selected rows as groups.
4. **Explicar diferenças** compares a deduplicated population with the rest or
   another saved group. Histograms, KS/total-variation distances, effect sizes,
   permutation p-values and BH q-values are available for export.
5. Explore Rips H0/H1/H2, diagrams, barcodes, Betti curves and entropy in
   **Persistência**. **Sensibilidade** compares cover parameters and saves
   model snapshots. **Laboratório** provides ToMATo, sliding-window PH,
   function-Rips Hilbert/Euler surfaces, and cubical image PH/Euler curves.
6. Save a workspace JSON to keep data, groups, selection, model configurations,
   positions and visual settings. Open it to reconstruct the model in Julia.
   SVG, graph/results JSON, row CSV and a self-contained Julia analysis script
   are also exportable. An imported workspace is data, never evaluated code.

The browser's data table shows original values. Median imputation and scaling
are applied to a separate geometry matrix, with a preprocessing audit. Numeric
values use Float64. Blank cells are missing, not zero. Categorical variables are
available for coloring, Explain and export; they are not silently encoded for
geometry.

## Scientific scope

- The graph's cycle rank `E−V+C` is labeled separately from persistence of the
  original point cloud. Layout and color do not affect memberships.
- Gain means overlap `1−1/gain` in the covered coordinate. Equalization covers
  tied mean ranks; ties can prevent equal population sizes. This differs from
  treating TDAmapper's `expansion` as an overlap percentage.
- PCA uses the geometry variables. Metric MDS uses up to 200 farthest-point
  landmarks and an out-of-sample projection. Diffusion uses a Gaussian affinity
  and symmetric normalization, and is limited to 600 rows. These are not claims
  of equivalence to Ayasdi's proprietary Neighborhood lenses.
- K-means uses a fixed RNG and Euclidean geometry. DBSCAN noise becomes
  singleton nodes, preventing a disconnected noise population from forming an
  artificial node. Ball Mapper uses a greedy epsilon net in the selected metric.
- Explain uses seeded permutation calibration, including ties. Minimum possible
  p is `1/(permutations+1)`. BH covers the tested feature family, not the bias of
  choosing a group after seeing the data. An overlapping reference loses the
  intersection so no observation appears in both samples.
- PH uses Vietoris–Rips and F₂ with the same selected metric/scaling. Original
  row IDs identify every landmark. Indistinguishable zero-distance observations
  are collapsed for PH and counted in the output. Essential or threshold-censored
  deaths serialize as JSON `null`, not fabricated finite values. Sampling may
  alter topology. Higher-order distances such as cosine/correlation are
  dissimilarities; general metric stability results need their own assumptions.
- Temporal embeddings use original series values, Euclidean distances, row
  order and index-based delays. Images explicitly downsample to at most 96×96,
  use unit pixel spacing and the vertex lower-star cubical convention. Image
  filtration values are translated to start at zero, with the offset exported.
- Function-Rips uses Euclidean geometry, finite F₂ calculations, at most 28
  landmarks and a 10×10 grid. Its Euler surface is that of the truncated complex.

Limits: 3,000 source rows, 80 geometry variables, 160 total columns, 20 MB per
request, 2,000 Mapper nodes, at most 300 Rips landmarks for H0/H1 or 80 for H2,
20 cover configurations and 25 temporal windows. The server queues one expensive
computation at a time. It retains eight tables and sixteen graph results; a
workspace file is the persistent backup. There is no million-row/distributed
backend, accounts, remote collaboration or guaranteed automatic model optimum.

See the [full Ayasdi research and feature matrix](docs/ayasdi-research.md),
[design/implementation plan](docs/implementation-plan.md),
[REST contract](docs/api.md), and [validation report](docs/validation.md).
The full research is also served at `/research`.

## Julia API

```julia
using MapperStudio

ds = parse_csv(read("data.csv", String); name="My data")
cfg = Dict("columns"=>["x", "y"], "resolution"=>12, "gain"=>1.7,
           "lens1"=>"pca1", "lens2"=>"pca2")
graph = analyze(ds, cfg)
rows = graph["nodes"][1]["members"]
# Requires at least two selected and two reference observations.
differences = explain(ds, rows; permutations=999, seed=2007)
ph = persistence_analysis(ds, cfg; sample=220, dimension=1)
```

## Verification

```bash
julia --startup-file=no --project=JuliaTDA.jl/apps/MapperStudio --threads=4 JuliaTDA.jl/apps/MapperStudio/test/runtests.jl
node --check JuliaTDA.jl/apps/MapperStudio/web/app.js
```

Tests check analytic circle/annulus references, SciPy KS fixtures, overlap
geometry, memberships/nerve edges, all refiners and lenses, deterministic
clustering, duplicate distances, preprocessing, advanced workflows and REST
boundaries. Browser checks exercise real Julia calculations and downloaded
workspace/script round trips; their results are recorded in the validation guide.

Code is under the parent repository's MIT license. Historical Ayasdi sources
and upstream Julia packages retain their own attribution and licenses. The app
does not use Ayasdi code, logos, data, or proprietary implementation details.
