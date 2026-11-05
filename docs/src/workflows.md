# Choosing a workflow

Start from the question you want to answer. Several packages can analyze the
same data while producing different objects.

| Question | Workflow | First place to read |
|---|---|---|
| Which observations form branches or recurring groups? | Table → metric space → filter → Mapper → node metadata | [Mapper exploration](examples/mapper_exploration.md) |
| Are there loops or voids across distance scales? | Point cloud → filtration → persistent homology | [Your first shape analysis](getting_started.md) |
| Can shape help predict a label? | Independent clouds → PH → fitted vectorizer → classifier | [Persistent homology for ML](examples/ph_for_ml.md), [Tuning a PH pipeline](examples/tuned_ph_pipeline.md) |
| Which density peaks form clusters? | Cloud → density + proximity graph → ToMATo | [ToMATo clustering](examples/tomato_clustering.md) |
| How variable are topological summaries across samples? | Independent diagrams → curve representation → mean confidence band | [Inference workflows](examples/p1.md), PersistenceInference tutorials |
| Does shape differ between two populations? | Explicit experimental units → appropriate permutation/null design | PersistenceInference's point-cloud and independence guides |
| How do distance and a vertex measurement interact? | Function-Rips → two-parameter grid invariants or signed measures | [P2 workflows](examples/p2.md), bundled MultiparameterPersistence manual |
| Can I describe a binary image across directions? | Vertex mask → Euler transforms or scalar image filtrations → cubical PH | [P2 workflows](examples/p2.md) |
| Is a time series geometrically periodic? | Training-only embedding choices → windows → PH/Mapper | [P2 workflows](examples/p2.md) |
| How does topology change when cells or values change? | Zigzag for cell edits, vineyard for values on a fixed complex | [Changing shapes and comparing diagrams](examples/p3.md) |

## Choose a package, not necessarily the entire umbrella

`using JuliaTDA` is convenient for combining methods. To keep an application
focused, import just the owning package:

| Package | Owns | Important conventions |
|---|---|---|
| MetricSpaces | Point representations, distances, neighborhoods, samplers, densities, transformations, Euler/image descriptors | Matrix columns are points; samplers have point and index variants; datasets are a submodule |
| TDAmapper | Covers, refiners, nerves, Mapper results and filter optimization | `M.C` contains original point indices; strategies live in submodules |
| TDAplots | Makie figures, layouts, linked explorer and diagram/ToMATo visuals | Load a backend; distinguish point-level and node-level values |
| ToMATo | Density-mode clustering on a graph | Graph radius and density merge threshold have different units |
| PersistenceInference | Resampling tests and curve bands | Each method needs its own sampling/null assumptions |
| MultiparameterPersistence | Exact F₂ reference computations on small two-parameter complexes | Finite-grid module, computational guards, bounded stability claims |
| JuliaTDA | Composition and re-exports | Optional extensions still require loading their trigger packages |

TDARipserer and TDAPersistenceDiagrams are independent experimental forks used
as dependencies for PH and diagram tooling. Their package names and UUIDs
differ from the original upstream packages. Mixing their diagram types with
upstream PersistenceDiagrams types is not a supported substitution.

## Keep geometry, metadata and targets separate

Choose geometric columns explicitly. A patient identifier, timestamp or class
label can be numeric without being a meaningful coordinate. Keep those
columns as metadata for interpretation. Impute or remove missing geometric
values before constructing a cloud, preserving the correspondence with rows.

Standardizing coordinates can be useful when units differ; it also changes
the geometry. For a learning task, estimate centering/scaling on training data
and apply the same transform to validation data. `euclidean_space(...;
standardize=true)` standardizes the table it receives; it does not store a
fitted transform for another table.

Inspect duplicate points, finite coordinates and sample sizes before running
PH. Duplicate observations affect density estimators and sampling weights,
even if a geometric construction collapses some zero-distance relationships.

## Learning requires a fitted pipeline

A landscape range, persistence-image grid, ATOL codebook or Gaussian-measure
center set inferred from data is a learned parameter. Fit it inside every
training fold, then reuse it unchanged on validation observations. Choosing
features or Mapper filters after seeing test labels also leaks information.

The [nested-CV example](examples/tuned_ph_pipeline.md) illustrates this
discipline. For time series, use chronological or blocked splits; overlapping
windows are dependent. For subjects with repeated observations, split at the
subject level when that matches the intended prediction setting.

## Optional integrations

| Task | Load in addition to the owning package |
|---|---|
| Static figures | `CairoMakie` |
| Interactive explorer | `GLMakie` or `WGLMakie` |
| Standalone TDAmapper tables | `Tables` (a DataFrames import also triggers it) |
| Image or multiparameter MLJ transformer | `MLJModelInterface` or a stack that loads it, such as `MLJBase` |
| Differentiable PH | `ChainRulesCore` and an appropriate AD tool such as `Zygote`, or the Enzyme extension |
| Optimized Mapper filters | `Zygote`, `Optimisers`; optionally the Flux/Lux adapter dependencies |
| Optimal cycles/fillings | `JuMP` and `HiGHS` |
| Delay embedding wrappers | `DelayEmbeddings` |

Install optional dependencies in the active environment before loading them.
The extension section of each package's `Project.toml` gives exact triggers.
See [Troubleshooting and reproducibility](troubleshooting.md) for missing-method
diagnostics and cost-control strategies.
