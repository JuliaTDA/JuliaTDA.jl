# Troubleshooting and reproducibility

## Installation and names

| Symptom | What to check |
|---|---|
| `Package ... not found` after starting a new REPL | Activate the analysis environment used at installation; check `Base.active_project()` and `Pkg.status()` |
| An unregistered dependency cannot resolve | Develop all required local siblings in one call, including the bundled MultiparameterPersistence package for the umbrella |
| `sphere` or `torus` is undefined | Use `JuliaTDA.MetricSpaces.Datasets.sphere(...)` or explicitly import the dataset name from the submodule |
| `R1Cover`, `Uniform` or `DBscan` is undefined | Load `JuliaTDA.ImageCovers`, `JuliaTDA.IntervalCovers`, `JuliaTDA.Refiners` as in the first tutorial |
| `knn_density`, `center` or `eccentricity` is ambiguous | Qualify the owning module; the umbrella pins geometry names to MetricSpaces |
| A diagram from another package does not dispatch | Use the ecosystem's TDAPersistenceDiagrams types consistently rather than an upstream package with a different UUID |
| A helper has no method although it is exported | Load its optional extension dependencies in the same environment |
| A docs build cannot locate sibling source | Check local paths or rerun `julia docs/setup.jl`; do not reuse another machine's local-path Manifest blindly |

For name resolution, `JuliaTDA.knn_density` is the MetricSpaces filter.
`JuliaTDA.ToMATo.knn_density` is ToMATo's clustering estimator. They have
different definitions; the fully qualified name documents which one you used.

## Tables and point matrices

`euclidean_space` accepts purely numeric selected columns and rejects explicitly
selected columns whose element type allows `missing`. Removing values from one
column without updating other columns breaks row correspondence. Clean the
table as a whole. Categorical labels belong in metadata unless you have chosen
an encoding and justified its induced distance.

`EuclideanSpace(matrix)` treats columns as points. A `100 × 3` table-like matrix
therefore becomes three points in 100 dimensions. Use `permutedims(matrix)`
when its rows are observations. If a result seems surprisingly cheap, inspect
`length(X)` and the length of `first(X)` before trusting it.

## Mapper looks fragmented or overly dense

Inspect the number of nodes, their membership sizes and uncovered observations.
Increase clustering radius cautiously when within-cover neighbors should
connect; reduce it when distinct structures have merged. Compare nearby cover
resolutions and overlaps. Changing all settings at once makes it difficult to
understand which choice caused a branch or cycle.

Nodes overlap, so summing node sizes counts some observations multiple times.
Do not use those sums as independent group sample sizes. Metadata summaries
are descriptive; selecting the most extreme node and treating its z-score as a
preplanned significance test gives a misleading conclusion.

An empty Mapper has no node coordinates to plot. Check the cover and input
before calling plotting or layout functions. DBSCAN noise handling is defined
by the refiner: in this implementation noise is reassigned to an outlier
cluster, rather than automatically discarded.

## Plots and interaction

Load a Makie backend before plotting. CairoMakie renders static figures;
click/hover callbacks need an interactive backend. If more than one backend
is loaded, activate the intended one explicitly.

`node_values` passed directly to `mapper_plot` must align with the nodes. For a
per-observation vector `v`, aggregate with `node_colors(M, v)` or compute
`[mean(v[ids]) for ids in M.C]`. The explorer accepts numeric node colors;
categorical plots use `mapper_plot` instead.

Check that a selected node exists before setting `explorer.selected_node[]`.
Use `nothing` to clear selection. Coordinates produced by a spring layout are
display coordinates, not a metric embedding of the original observations.

## PH is expensive or has unexpected infinite intervals

Start with tens of points and `dim_max=1`. PH cost depends strongly on the
filtration, dimension, number of observations and distance threshold. Higher
dimensional simplices can grow combinatorially; a low-dimensional ambient
space alone does not make a Rips complex small.

Subsampling/landmarks and a finite threshold can reduce cost but also change
the question. Record their indices and coverage, compare resolutions, and
distinguish essential intervals from threshold-censored ones. A witness
barcode is not promised to equal the original cloud's Rips barcode.

Bootstrap and permutation procedures repeat the expensive calculation. First
time one PH evaluation, then estimate the resampling workload. A small
resample count is useful for an API check; it does not support precise tail
probability estimates.

Multiparameter reference algorithms use dense exact algebra. Their size guards
are safety ceilings, not efficient target sizes. Reduce the complex and grid
before raising limits. If a grid comparison disagrees, check that both grids
include the relevant critical grades.

## Statistical results appear implausibly certain

Write down the experimental unit, null model and dependence structure. A
point-label permutation tests exchangeability of pooled point observations.
A curve band across diagrams targets a population mean on the supplied finite
grid. Maximum-persistence significance requires supplied null maxima with
the appropriate exchangeability interpretation. These are separate methods.

Use independent validation simulations resembling the study design. Stability
of diagrams does not by itself calibrate a bootstrap. Inspect the inference
package's existing calibration report, including its observed undercoverage,
before relying on nominal coverage. Infinite intervals and custom distances
need their stated interpretation; a helper returning a feature is not a
universal scientific discovery rule.

## A reproducible analysis record

Record the package versions or checkout commits (including any local changes),
Julia version, active environment, seed, selected columns and units, missing
data treatment, normalization, metric, filtration and cutoff, homology
dimensions, Mapper cover/refiner/nerve settings, and any resampling design.
For a fitted pipeline, also record training splits and fitted descriptor grids.

```julia
using Pkg, Random
versioninfo()
Pkg.status()
rng = Xoshiro(42) # pass this to APIs that accept rng
```

Some generators/layouts use Julia's default RNG; seed it explicitly when their
output is part of a comparison. Examples in the docs use small workloads and
controlled seeds; they illustrate behavior rather than benchmark scientific
performance on arbitrary data.
