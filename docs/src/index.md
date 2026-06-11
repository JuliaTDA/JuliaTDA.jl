# JuliaTDA.jl

*The umbrella package for Topological Data Analysis in Julia.*

```@meta
CurrentModule = JuliaTDA
```

## What is Topological Data Analysis?

**Topological Data Analysis (TDA)** is a family of techniques that study the
*shape* of data. Instead of asking only "where are the points?", TDA asks "how
are the points connected?" — does the data form loops, branches, clusters, or
voids? These questions are answered with tools from algebraic topology, adapted
to noisy, finite point clouds. The two flagship techniques are **persistent
homology**, which tracks topological features (connected components, loops,
voids) across every scale and records how long each one persists, and
**Mapper**, which builds a compressed graph (or simplicial complex) summarising
the data's structure by covering the range of a chosen *filter* function and
gluing together the clusters found in each piece.

TDA shines when the interesting signal in the data is *geometric* or
*relational* rather than purely statistical: detecting a cyclic process in a
time series, finding rare "flares" of anomalous behaviour branching off a dense
core, comparing the shape of two datasets, or turning the shape of a point
cloud into a fixed-length feature vector for downstream machine learning. The
JuliaTDA ecosystem provides a composable, pure-Julia implementation of this
whole pipeline.

## The ecosystem

A single `using JuliaTDA` brings the entire stack into scope:

| Package | Role |
|:--------|:-----|
| [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl) | Geometry foundation: `EuclideanSpace`, distances, samplers, filters, transformations, and the `Datasets` submodule |
| [TDAmapper.jl](https://github.com/JuliaTDA/TDAmapper.jl) | The Mapper algorithm: `mapper`, `classical_mapper`, `ball_mapper`, plus Tables.jl helpers |
| [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) | Makie-based plotting, including the interactive `mapper_explorer` |
| [Ripserer.jl](https://github.com/JuliaTDA/Ripserer.jl) | Persistent homology: `ripserer` and several filtrations |
| [PersistenceDiagrams.jl](https://github.com/JuliaTDA/PersistenceDiagrams.jl) | Persistence diagrams, distances, and vectorizations for ML |
| [ToMATo.jl](https://github.com/JuliaTDA/ToMATo.jl) | Topological mode-seeking clustering: `tomato`, `proximity_graph` |

### How the packages compose

```
MetricSpaces  ──►  TDAmapper  ──►  TDAplots
                                      │
Ripserer  ──►  PersistenceDiagrams ◄──┘   (Ripserer re-exports the basics)

ToMATo  (density-based clustering, built on MetricSpaces)
```

* **MetricSpaces → TDAmapper → TDAplots** is the Mapper pipeline. You start from
  a metric space, run the Mapper algorithm to get a graph, and plot it.
* **Ripserer → PersistenceDiagrams** is the persistent-homology pipeline.
  Ripserer computes diagrams; PersistenceDiagrams analyses and vectorizes them.
  Ripserer already re-exports the *basics* of PersistenceDiagrams (`birth`,
  `death`, `persistence`, `barcode`, …) as the very same bindings, so there is
  no name clash.
* **ToMATo** is an independent clustering algorithm that also builds on
  MetricSpaces.

### Name resolution

Both `MetricSpaces` and `ToMATo` export a `knn_density`. Under `using JuliaTDA`
the unqualified name resolves to **MetricSpaces'** density filter; ToMATo's
clustering variant stays reachable as `JuliaTDA.ToMATo.knn_density`. Similarly,
`eccentricity` and `center` (also exported by `Graphs`) are pinned to their
MetricSpaces meaning.

## Tables.jl, built in

Because JuliaTDA depends on `Tables` directly, TDAmapper's Tables.jl extension
is always active. You can build a metric space straight from a `NamedTuple`, a
`DataFrame`, or any Tables.jl source with [`euclidean_space`](@ref), and
summarise a Mapper's nodes against the original table with
[`node_statistics`](@ref).

## Installation

### Development install (now)

The pure-Julia packages are not yet registered in the General registry, so
`develop` the sibling repositories from their GitHub URLs:

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

### Registry install (later)

Once the ecosystem is registered this becomes a single line:

```julia
using Pkg; Pkg.add("JuliaTDA")
```

## Worked examples

* [Mapper exploration](@ref) — load a table, choose a filter, run Mapper, colour
  by the filter, and use `node_statistics` to find what makes a flare special;
  plus the interactive `mapper_explorer`.
* [Persistent homology for ML](@ref) — point clouds → `ripserer` → diagram plots
  → `Landscape`/`PersistenceImage` feature matrix ready for a classifier.
* [ToMATo clustering](@ref) — a noisy multi-blob dataset → density →
  `proximity_graph` → `tomato` → a scatter coloured by cluster.

## Project links

* GitHub organisation: <https://github.com/JuliaTDA>
* This package: <https://github.com/JuliaTDA/JuliaTDA.jl>
