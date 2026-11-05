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
| Persistent homology | [TDARipserer.jl](https://github.com/JuliaTDA/Ripserer.jl) | `ripserer`, `Rips`, `Alpha`, `Cubical`, `EdgeCollapsedRips`, … |
| Diagrams & ML | [TDAPersistenceDiagrams.jl](https://github.com/JuliaTDA/PersistenceDiagrams.jl) | `PersistenceDiagram`, `Bottleneck`, `Wasserstein`, `Landscape`, `PersistenceImage`, `BettiCurve`, … |
| Statistical inference | [PersistenceInference.jl](https://github.com/JuliaTDA/PersistenceInference.jl) | `confidence_band`, `multiplier_bootstrap`, `max_persistence_significance`, `independence_test`, … |
| Clustering | [ToMATo.jl](https://github.com/JuliaTDA/ToMATo.jl) | `tomato`, `proximity_graph` |
| Multiparameter | MultiparameterPersistence (bundled) | `bifiltration`, `hilbert_function`, `bigraded_betti`, `euler_surface`, signed measures and MLJ features |

## How the packages compose

```
MetricSpaces  ──►  TDAmapper  ──►  TDAplots
                                       │
TDARipserer  ──►  TDAPersistenceDiagrams ◄───┘   (TDARipserer re-exports the basics)

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
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners, JuliaTDA.Nerves
using Statistics: mean
using CairoMakie

X = JuliaTDA.MetricSpaces.Datasets.sphere(240)   # 240 points on a circle
f = first.(X)                                 # x-coordinate filter
M = classical_mapper(X, R1Cover(f, Uniform(length = 10, expansion = 0.3)),
                     DBscan(radius = 0.2), SimpleNerve())
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

# Persistent homology. TDARipserer re-exports the *basics* of TDAPersistenceDiagrams
# (birth, death, persistence, dim, threshold, barcode, …) as the SAME bindings
# it imports from TDAPersistenceDiagrams, so re-exporting both packages introduces
# no ambiguity warning — the overlapping names resolve to one binding.
@reexport using TDARipserer

# The full diagram / vectorization API (Bottleneck, Wasserstein, Landscape,
# PersistenceImage, BettiCurve, the MLJ vectorizers, …). The names it shares
# with TDARipserer are the identical TDAPersistenceDiagrams bindings.
@reexport using TDAPersistenceDiagrams

# Inference uses the same diagram and PH bindings as the two packages above.
@reexport using PersistenceInference

# Finite-grid multiparameter invariants; source is bundled under lib/.
@reexport using MultiparameterPersistence

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
