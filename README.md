# JuliaTDA.jl

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaTDA.github.io/JuliaTDA.jl/)
[![Build Status](https://github.com/JuliaTDA/JuliaTDA.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaTDA/JuliaTDA.jl/actions/workflows/CI.yml?query=branch%3Amain)

**JuliaTDA.jl** is the umbrella package for the
[JuliaTDA](https://github.com/JuliaTDA) ecosystem — a coherent toolkit for
**Topological Data Analysis** in Julia. A single

```julia
using JuliaTDA
```

re-exports the whole stack: metric-space geometry, the Mapper algorithm,
Makie-based plotting, persistent homology, persistence-diagram tooling /
vectorizations, statistical inference, ToMATo clustering, and the bundled
two-parameter reference algorithms.

## Visual workbench

[MapperStudio](https://github.com/JuliaTDA/MapperStudio.jl) is a local, browser-based Mapper
and TDA workbench with calculations in Julia. It includes linked graph/point
selection, saved populations and statistical Explain, persistence diagrams,
cover sensitivity, ToMATo, time-series PH, cubical image analysis and finite-grid
multiparameter views. Its isolated app environment keeps web dependencies out
of `using JuliaTDA`. With Julia 1.12 or newer, install it in package mode with
`app add https://github.com/JuliaTDA/MapperStudio.jl`, then run `mapperstudio`
in your terminal. See the [Ayasdi research](https://github.com/JuliaTDA/MapperStudio.jl/blob/main/docs/ayasdi-research.md)
for historical feature correspondence and explicit first-release limits.

## The ecosystem

| Package | Role | What it brings |
|:--------|:-----|:---------------|
| [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl) | Geometry foundation | `EuclideanSpace`, distances, samplers, filters (`eccentricity`, `kde`, `dtm_density`, `knn_density`), transformations (`center`, `scale`, `standardize`, `embed`), `geodesic_distance`, `nerve_1d`/`nerve_2d`, and the `Datasets` submodule (`sphere`, `torus`, `mammoth`, …) |
| [TDAmapper.jl](https://github.com/JuliaTDA/TDAmapper.jl) | Mapper | `mapper`, `classical_mapper`, `ball_mapper`; cover / refiner / nerve submodules; the Tables.jl helpers `euclidean_space` and `node_statistics` |
| [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) | Plotting (Makie) | `mapper_plot`, `metricspace_plot`, the interactive `mapper_explorer`, persistence / barcode plots, 21 graph layouts |
| [TDARipserer.jl](https://github.com/JuliaTDA/Ripserer.jl) | Persistent homology | `ripserer`, `Rips`, `Alpha`, `Cubical`, `EdgeCollapsedRips`, … |
| [TDAPersistenceDiagrams.jl](https://github.com/JuliaTDA/PersistenceDiagrams.jl) | Diagrams & ML | `PersistenceDiagram`, `Bottleneck`, `Wasserstein`, `Landscape`, `PersistenceImage`, `BettiCurve`, entropy curves, MLJ integration |
| [PersistenceInference.jl](https://github.com/JuliaTDA/PersistenceInference.jl) | Statistical inference | Confidence bands, multiplier bootstrap, maximum-persistence significance and HSIC independence tests |
| [ToMATo.jl](https://github.com/JuliaTDA/ToMATo.jl) | Clustering | `tomato`, `proximity_graph` |
| [MultiparameterPersistence](lib/MultiparameterPersistence) | Two-parameter reference algorithms | Function-Rips bifiltrations, F₂ Hilbert/Koszul Betti/Euler surfaces, signed measures and optional MLJ features |

The [P2 examples](examples/p2/README.md) also cover ECC/ECT/SECT, optimal cycles
and filling volumes, time-series embeddings, image filtrations and trainable
MLP/Flux/Lux Mapper filters. Heavy integrations use optional package extensions.

### How they compose

```
MetricSpaces  ──►  TDAmapper  ──►  TDAplots
                                      │
TDARipserer  ──►  TDAPersistenceDiagrams ◄──┘   (TDARipserer re-exports the basics)

ToMATo  (density-based clustering, built on MetricSpaces)
```

## Quick start

```julia
using JuliaTDA
# The Mapper building blocks live in submodules; bring them into scope:
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners, JuliaTDA.Nerves
using Statistics: mean
using CairoMakie # install this optional backend in your analysis environment

# Datasets are a submodule of MetricSpaces — access them qualified:
X = JuliaTDA.MetricSpaces.Datasets.sphere(240)   # 240 points on a circle

# Cover the circle by x-coordinate; cluster each strip in the original geometry:
f = first.(X)

# Run the classical Mapper and plot it, coloured by the filter:
M = classical_mapper(X, R1Cover(f, Uniform(length = 10, expansion = 0.3)),
                     DBscan(radius = 0.2), SimpleNerve())
mapper_plot(M; node_values = [mean(f[c]) for c in M.C])

# Persistent homology of a point cloud:
dgms = ripserer(X)        # dgms[2] holds the H₁ (loop) features
```

## Tables.jl integration (built in)

JuliaTDA depends on `Tables` directly, so TDAmapper's `TDAmapperTablesExt`
extension is **always loaded** for umbrella users — no extra `using Tables`
needed. Any Tables.jl source (a `NamedTuple` of columns, a `DataFrame`, CSV
rows, …) works:

```julia
tbl = (x = randn(200), y = randn(200), z = randn(200), label = rand(["a","b"], 200))
using Statistics: std
X   = euclidean_space(tbl; cols = (:x, :y, :z), standardize = true)
M   = classical_mapper(X, R1Cover(eccentricity(X), Uniform(length = 8)),
                       DBscan(), SimpleNerve())
node_statistics(M, tbl; stats = (mean, std))   # per-node summary, one row per node
```

## A note on `knn_density`

Both `MetricSpaces` and `ToMATo` export a function named `knn_density`, with
**different** implementations. To keep `using JuliaTDA` unambiguous:

* the unqualified `knn_density` is **MetricSpaces'** version (the general-purpose
  density filter), reached through the TDAplots re-export chain;
* ToMATo's clustering-oriented variant stays available, fully qualified, as
  `JuliaTDA.ToMATo.knn_density`.

(Separately, `MetricSpaces` and `Graphs` both export `eccentricity` and
`center`; JuliaTDA pins both unqualified names to the **MetricSpaces** meaning.)

## Installation

### Development install (now)

Registration is deferred. From a checkout of this repository, run:

```sh
julia --startup-file=no scripts/setup.jl
```

This resolves the seven sibling packages from their public GitHub repositories
and the bundled multiparameter package in one transaction. No sibling checkouts
are required. To use local sibling checkouts instead, run
`julia scripts/setup.jl --local`. The local directory names are `MetricSpaces.jl`,
`TDAmapper.jl`, `TDAplots.jl`, `ToMATo.jl`, `TDARipserer.jl`,
`TDAPersistenceDiagrams.jl` and `PersistenceInference.jl`.

To prepare a separate analysis environment, pass its directory:

```sh
julia scripts/setup.jl /path/to/shape-analysis
julia --project=/path/to/shape-analysis -e 'using Pkg; Pkg.add("CairoMakie")'
julia --project=/path/to/shape-analysis scripts/smoke.jl
```

`TDARipserer` and `TDAPersistenceDiagrams` are independent experimental forks
with their own UUIDs and version series. Their GitHub repository URLs still
use the original slugs, while local checkout directories and Julia imports
use the new names. The public functions (`ripserer`, `PersistenceDiagram`,
etc.) remain re-exported by `using JuliaTDA`.

> The `Manifest.toml` is intentionally **not** committed, so each developer
> resolves against their own local checkouts / forks.

### Registry install (later)

Once the ecosystem is registered, the dev incantation above collapses to a
single line:

```julia
using Pkg; Pkg.add("JuliaTDA")
```

## Documentation

The source documentation has several entry points:

- [Your first shape analysis](docs/src/getting_started.md): install the local
  stack, analyze a circle, read its persistence diagram and inspect Mapper nodes.
- [Choosing a workflow](docs/src/workflows.md): select methods by question and
  understand optional dependencies and training-only fitting.
- [Reading topological results](docs/src/concepts.md): distinguish clouds,
  complexes, diagrams, Mapper graphs, density modes and two-parameter invariants.
- [Worked examples](docs/src/index.md): tables and Mapper, PH for learning,
  ToMATo, inference, Euler/image/time-series workflows and changing complexes.
- [Troubleshooting and reproducibility](docs/src/troubleshooting.md): names,
  extensions, plotting backends, cost and interpretation pitfalls.

The hosted site is <https://JuliaTDA.github.io/JuliaTDA.jl/>; local source pages
can contain changes that have not yet been deployed. From this checkout, build locally with:

```sh
julia docs/setup.jl
julia --project=docs docs/make.jl
```

The [roadmap](ROADMAP.md) records current scope and deferred publication. The
[November maintenance report](docs/maintenance/2026-11-05.md) records the source
installation checks, dependency revisions, test results and issue reconciliation.

## License

MIT. See the individual packages for their respective licenses
(TDARipserer and TDAPersistenceDiagrams originate from
[mtsch](https://github.com/mtsch)'s upstream work).
