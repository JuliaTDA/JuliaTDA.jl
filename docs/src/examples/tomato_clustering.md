# ToMATo clustering

[ToMATo](https://github.com/JuliaTDA/ToMATo.jl) (Topological Mode Analysis Tool)
is a density-based clustering algorithm with a topological twist: it seeds one
cluster per density peak and then *merges* peaks whose topological prominence
falls below a threshold `τ`. This makes the number of clusters a consequence of
the data's persistence rather than a hyperparameter you guess up front.

The pipeline is: estimate a **density** at each point → build a **proximity
graph** → run **`tomato`** → colour the points by their assigned cluster.

```@example tomato
using JuliaTDA
using CairoMakie
using Random
CairoMakie.activate!(type = "png")
Random.seed!(17)
const DS = JuliaTDA.MetricSpaces.Datasets
nothing # hide
```

## A noisy multi-blob dataset

```@example tomato
X = DS.three_clusters(240)
mat = JuliaTDA.MetricSpaces.as_matrix(X)   # 2 x n matrix of coordinates
fig = Figure()
ax = Axis(fig[1, 1]; title = "raw data", aspect = DataAspect())
scatter!(ax, mat[1, :], mat[2, :]; markersize = 6, color = (:black, 0.5))
fig
```

## Density estimation

ToMATo ships its own clustering-oriented density estimator. Because
`MetricSpaces` also exports a `knn_density`, the **ToMATo** one is reached
fully qualified as `JuliaTDA.ToMATo.knn_density` (the unqualified `knn_density`
is MetricSpaces' version):

```@example tomato
dens = JuliaTDA.ToMATo.knn_density(X; k = 15)
extrema(dens)
```

!!! tip "Using MetricSpaces' density instead"
    You could equally drive ToMATo with MetricSpaces' filters — e.g.
    `dens = knn_density(X)` (the unqualified, MetricSpaces version) or
    `dens = dtm_density(X; k = 15)`. Any per-point density vector works.

## Proximity graph

[`proximity_graph`](@ref) connects each point to its near neighbours within
radius `ϵ`, falling back to nearest neighbours where the ball is too sparse.
Its default neighbor cap limits each local search result before an undirected
union of edges; it is not an uncapped radius graph, and final degree can exceed
the cap because other vertices may link back to a point.

```@example tomato
g = proximity_graph(X, 0.5)
g
```

## Running ToMATo

[`tomato`](@ref) takes the metric space, the proximity graph, the densities, and
the merging threshold `τ`. It returns the cluster label of every point and a
dictionary of the birth/death of each density peak (useful for choosing `τ`).

```@example tomato
clusters, births_deaths = tomato(X, g, dens, 1.0; max_cluster_height = 0)
n_clusters = length(unique(clusters))
```

## The result

```@example tomato
fig = Figure()
ax = Axis(fig[1, 1]; title = "ToMATo clusters", aspect = DataAspect())
scatter!(ax, mat[1, :], mat[2, :]; markersize = 6, color = clusters, colormap = :tab10)
fig
```

The dictionary is indexed by original peak-point ids, while `clusters` contains
renumbered labels. Deaths are recorded only for merges performed at the supplied
`τ`; remaining peaks have the `Inf` sentinel. To inspect more of the merge
structure, run an exploratory pass with `τ = Inf`:

```@example tomato
_, full_merges = tomato(X, g, dens, Inf)
finite_prominences = sort([bd[1] - bd[2] for bd in values(full_merges) if isfinite(bd[2])])
(merged_peaks = length(finite_prominences), surviving_peaks =
 count(bd -> !isfinite(bd[2]), values(full_merges)))
```

A large gap between finite prominence values can suggest candidate thresholds.
This is a diagnostic, not automatic evidence of true population clusters.
`Inf` entries mean that this run recorded no merge for those peaks; they do not
represent infinite density drops. Inspect graph connectivity, density ties and
the implementation's merge behavior before interpreting survivor counts. The threshold has density units
and should be reconsidered after changing the density estimator or its `k`.
TDAplots provides [`tomato_persistence_plot`](@ref) and
[`tomato_graph_plot`](@ref) for inspecting these outputs. Read the owning
package's guide before interpreting the capped graph, ties or the strict merge
inequality.
