"""
# JuliaTDA.jl

The umbrella package for the **JuliaTDA** ecosystem: a single `using JuliaTDA`
brings the whole Topological Data Analysis (TDA) stack into scope.

## What it re-exports

| Layer | Package | Brings |
|:------|:--------|:-------|
| Geometry foundation | [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl) | `EuclideanSpace`, distances, samplers, filters (`eccentricity`, `kde`, `dtm_density`, `knn_density`), transformations, `Datasets` submodule |
| Mapper | [TDAmapper.jl](https://github.com/JuliaTDA/TDAmapper.jl) | `mapper`, `classical_mapper`, `ball_mapper`, covers/refiners/nerves, `euclidean_space`/`node_statistics` (Tables.jl) |
| Plotting | [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl) | `mapper_plot`, `metricspace_plot`, `mapper_explorer`, persistence/barcode plots, graph layouts |
| Persistent homology | [Ripserer.jl](https://github.com/JuliaTDA/Ripserer.jl) | `ripserer`, `Rips`, `Alpha`, `Cubical`, `EdgeCollapsedRips`, … |
| Diagrams & ML | [PersistenceDiagrams.jl](https://github.com/JuliaTDA/PersistenceDiagrams.jl) | `PersistenceDiagram`, `Bottleneck`, `Wasserstein`, `Landscape`, `PersistenceImage`, `BettiCurve`, … |
| Clustering | [ToMATo.jl](https://github.com/JuliaTDA/ToMATo.jl) | `tomato`, `proximity_graph` |

## How the packages compose

```
MetricSpaces  ──►  TDAmapper  ──►  TDAplots
                                       │
Ripserer  ──►  PersistenceDiagrams ◄───┘   (Ripserer re-exports the basics)

ToMATo  (builds on MetricSpaces; density-based clustering)
```

## Tables.jl integration

JuliaTDA depends on `Tables` directly, so TDAmapper's `TDAmapperTablesExt`
extension loads automatically. `euclidean_space(table; cols, standardize)` and
`node_statistics(M, table; stats)` work on any Tables.jl source (NamedTuple,
`DataFrame`, CSV rows, …) out of the box.

## Name-collision note

Both `MetricSpaces` and `ToMATo` export a `knn_density`. The unqualified
`knn_density` you get from `using JuliaTDA` is **MetricSpaces'** version (it
arrives through the TDAplots re-export chain). ToMATo's variant is still
reachable, fully qualified, as `JuliaTDA.ToMATo.knn_density`.

## Quick start

```julia
using JuliaTDA

X = JuliaTDA.MetricSpaces.Datasets.sphere(500)   # 500 points on a circle
f = eccentricity(X)                              # per-point filter
M = classical_mapper(X, R1Cover(f, Uniform(length = 10, expansion = 0.3)),
                     DBscan(), SimpleNerve())
mapper_plot(M; node_values = [mean(f[c]) for c in M.C])
```
"""
module JuliaTDA

using Reexport

# TDAplots re-exports TDAmapper, which re-exports MetricSpaces.
# This single line brings the geometry foundation, the Mapper algorithm, and
# all of the Makie-based plotting into scope (including MetricSpaces.knn_density).
@reexport using TDAplots

# --- Disambiguate MetricSpaces names that collide with Graphs --------------
# `MetricSpaces` does `using Graphs` *and* exports `center` and `eccentricity`;
# `Graphs` also exports those two names. Inside MetricSpaces the local
# definitions win, but once they travel up the re-export chain
# (MetricSpaces → TDAmapper → TDAplots) they become re-exported names sitting
# alongside Graphs' `using`-imported versions, so the unqualified name is
# *ambiguous* and `JuliaTDA.center` / `JuliaTDA.eccentricity` would otherwise
# be unresolvable. (These are the ONLY two such names in the whole ecosystem,
# detected empirically.) Importing them explicitly from MetricSpaces and
# re-exporting them pins both to the MetricSpaces (TDA) meaning, which is what
# umbrella users want: per-point `eccentricity` as a Mapper filter and `center`
# as the metric-space transformation.
import MetricSpaces
using MetricSpaces: center, eccentricity
export center, eccentricity

# Persistent homology. Ripserer re-exports the *basics* of PersistenceDiagrams
# (birth, death, persistence, dim, threshold, barcode, …) as the SAME bindings
# it imports from PersistenceDiagrams, so re-exporting both packages introduces
# no ambiguity warning — the overlapping names resolve to one binding.
@reexport using Ripserer

# The full diagram / vectorization API (Bottleneck, Wasserstein, Landscape,
# PersistenceImage, BettiCurve, the MLJ vectorizers, …). The names it shares
# with Ripserer are the identical PersistenceDiagrams bindings.
@reexport using PersistenceDiagrams

# ToMATo clustering. We must NOT do `using ToMATo` (plain), because that would
# pull ALL of ToMATo's exports — including its own `knn_density` — into this
# module's scope. Together with MetricSpaces' `knn_density` (already here via
# the TDAplots chain) that makes the unqualified `JuliaTDA.knn_density`
# *ambiguous*: the two are DISTINCT bindings (verified empirically), so Julia
# refuses to resolve it.
#
# Instead we import only the names unique to ToMATo. This leaves the
# unqualified `knn_density` resolving cleanly to MetricSpaces' version, while
# ToMATo's clustering density estimator stays reachable, fully qualified, as
# `JuliaTDA.ToMATo.knn_density`.
using ToMATo: ToMATo, tomato, proximity_graph
export tomato, proximity_graph

end # module JuliaTDA
