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
vectorizations, and ToMATo clustering.

## The ecosystem

| Package | Role | What it brings |
|:--------|:-----|:---------------|
| [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl) | Geometry foundation | `EuclideanSpace`, distances, samplers, filters (`eccentricity`, `kde`, `dtm_density`, `knn_density`), transformations (`center`, `scale`, `standardize`, `embed`), `geodesic_distance`, `nerve_1d`/`nerve_2d`, and the `Datasets` submodule (`sphere`, `torus`, `mammoth`, …) |
| [TDAmapper.jl](https://github.com/JuliaTDA/TDAmapper.jl) | Mapper | `mapper`, `classical_mapper`, `ball_mapper`; cover / refiner / nerve submodules; the Tables.jl helpers `euclidean_space` and `node_statistics` |
| [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) | Plotting (Makie) | `mapper_plot`, `metricspace_plot`, the interactive `mapper_explorer`, persistence / barcode plots, 21 graph layouts |
| [Ripserer.jl](https://github.com/JuliaTDA/Ripserer.jl) | Persistent homology | `ripserer`, `Rips`, `Alpha`, `Cubical`, `EdgeCollapsedRips`, … |
| [PersistenceDiagrams.jl](https://github.com/JuliaTDA/PersistenceDiagrams.jl) | Diagrams & ML | `PersistenceDiagram`, `Bottleneck`, `Wasserstein`, `Landscape`, `PersistenceImage`, `BettiCurve`, entropy curves, MLJ integration |
| [ToMATo.jl](https://github.com/JuliaTDA/ToMATo.jl) | Clustering | `tomato`, `proximity_graph` |

### How they compose

```
MetricSpaces  ──►  TDAmapper  ──►  TDAplots
                                      │
Ripserer  ──►  PersistenceDiagrams ◄──┘   (Ripserer re-exports the basics)

ToMATo  (density-based clustering, built on MetricSpaces)
```

## Quick start

```julia
using JuliaTDA
# The Mapper building blocks live in submodules; bring them into scope:
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners, JuliaTDA.Nerves
using Statistics: mean

# Datasets are a submodule of MetricSpaces — access them qualified:
X = JuliaTDA.MetricSpaces.Datasets.sphere(500)   # 500 points on a circle

# A per-point eccentricity filter (high for outliers, low near the centre):
f = eccentricity(X)

# Run the classical Mapper and plot it, coloured by the filter:
M = classical_mapper(X, R1Cover(f, Uniform(length = 10, expansion = 0.3)),
                     DBscan(), SimpleNerve())
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

Until the pure-Julia packages are registered in the General registry, build the
environment by `develop`-ing the sibling repositories from their GitHub URLs:

```julia
using Pkg
Pkg.develop([
    PackageSpec(url = "https://github.com/JuliaTDA/MetricSpaces.jl"),
    PackageSpec(url = "https://github.com/JuliaTDA/TDAmapper.jl"),
    PackageSpec(url = "https://github.com/JuliaTDA/TDAplots.jl"),
    PackageSpec(url = "https://github.com/JuliaTDA/Ripserer.jl"),
    PackageSpec(url = "https://github.com/JuliaTDA/PersistenceDiagrams.jl"),
    PackageSpec(url = "https://github.com/JuliaTDA/ToMATo.jl"),
])
Pkg.develop(PackageSpec(url = "https://github.com/JuliaTDA/JuliaTDA.jl"))
```

If you have the repositories checked out side by side locally, you can instead
`develop` them by path:

```julia
using Pkg
for p in ("MetricSpaces", "TDAmapper", "TDAplots", "Ripserer",
          "PersistenceDiagrams", "ToMATo")
    Pkg.develop(PackageSpec(path = "../$(p).jl"))
end
```

> The `Manifest.toml` is intentionally **not** committed, so each developer
> resolves against their own local checkouts / forks.

### Registry install (later)

Once the ecosystem is registered, the dev incantation above collapses to a
single line:

```julia
using Pkg; Pkg.add("JuliaTDA")
```

## Documentation

Full documentation, including three worked examples (Mapper exploration,
persistent homology for ML, and ToMATo clustering), lives at
<https://JuliaTDA.github.io/JuliaTDA.jl/>.

## License

MIT. See the individual packages for their respective licenses
(Ripserer and PersistenceDiagrams originate from
[mtsch](https://github.com/mtsch)'s upstream work).
