# P3 implementation and validation — 3 October 2026

All five requested P3 features are implemented in the independent
TDARipserer and TDAPersistenceDiagrams packages. Registration remains deferred.

## Public APIs and supported scope

| Roadmap item | API | Supported scope |
|---|---|---|
| P3.1 Witness complexes | `Witness`, `LazyWitness` | Point clouds with selected landmark indices, or rectangular witness-to-landmark distance matrices. Weak witnesses enforce face closure; lazy witnesses use the implicit flag-complex PH engine and support zero-valued edges. |
| P3.2 Zigzag persistence | `ZigzagPersistence`, `ZigzagEvent`, `zigzag_persistence`, `zigzag_diagrams` | Online simplex additions/removals, exact F₂ homology in arbitrary requested dimensions. Insertions follow faces; removals are maximal. Initial complexes expand to face closure. Open bars are explicitly right-censored. |
| P3.3 Diagram averaging | `frechet_mean`, `diagram_mean`, `frechet_variance`, `FrechetMeanResult` | Weighted squared Euclidean Wasserstein objective, diagonal-aware assignments and updates, cardinality growth, deterministic multiple starts and convergence diagnostics. Essential intervals require equal cardinality. No global-optimum certificate for three or more inputs. |
| P3.4 Vineyards | `Vineyard`, `update_vineyard!`, `vineyard_diagrams`, `VinePoint` | Fixed simplicial complex over F₂. Affine filtration updates reuse `R = D*V`, process adjacent crossings and retain vine identities through the diagonal. Simultaneous continuation uses a deterministic tie policy. Cubical cells and changes to the complex are excluded. |
| P3.5 Diagram kernels | `PersistenceScaleSpaceKernel`, `PersistenceWeightedGaussianKernel` | Paper formulas for finite intervals, linear weighted Gaussian embeddings and optional outer Gaussian kernel. Essential intervals are ignored. Custom weights do not inherit the paper's stability guarantees. |

The existing JuliaTDA re-export chain exposes these APIs. Each feature has
docstrings, reference tests, a runnable example and a changelog entry.

## Correctness checks

- The complete TDARipserer and TDAPersistenceDiagrams suites passed on Julia
  1.12.5, including both Aqua suites. TDARipserer's existing Rips tests retain
  two expected broken tests. Legacy doctests are gated to older Julia versions;
  they were skipped, not reported as passing.
- Final P3 checks passed on Julia 1.12.5 and the oldest supported core-package
  version, Julia 1.6.7: 100 kernel assertions, 47 averaging assertions, 66 witness
  assertions, 3,325 zigzag assertions, and vineyard factorization/continuity
  checks (945 assertions on 1.12; 937 on 1.6).
- Zigzag is checked against an independent dense F₂ oracle. Four seeded
  insertion/deletion streams compare every subinterval's limit-to-colimit rank
  in H₀, H₁ and H₂, including an initial triangulated sphere. Analytical H₀,
  circle and sphere bars are also checked. A 2,000-event regression confirms
  that chain coordinates are recycled and stay bounded by the peak active
  complex; stored output intervals still grow with stream length.
- Vineyard updates are compared with fresh `ripserer(Custom(...))` diagrams
  at every frame. Independent boundary multiplication checks `D*V == R`,
  upper-triangular invertibility and unique reduction pivots. Tests include
  ordinary crossings, mixed cell dimensions, simultaneous lower-star ties,
  a collapsed filtration, continuity at crossing knots and order-preserving
  changes requiring no column additions.
- Witness tests cover analytical edge values, closure, zero-valued edges,
  circle and octahedral-sphere topology, and representative/algorithm variants.
- Means have analytical weighted, diagonal, empty-initialization, essential,
  increased-cardinality and three-diagram reference cases. This work also fixes
  the pre-existing asymmetric empty-diagram bug in Bottleneck/Wasserstein.
- Kernels are checked against analytical paper formulas, diagonal/empty
  behavior, symmetry and positive semidefinite Gram matrices.
- Both standalone P3 examples ran successfully. Documenter built the new
  averaging, kernel and dynamic-persistence pages and executed their examples.
  The isolated build emitted only temporary-site repository/version warnings.
- All seven P3 integration assertions passed through `using JuliaTDA` on Julia
  1.12.5, with local MultiparameterPersistence and PersistenceInference paths
  resolved in the development manifest. No registration was needed.

## Reproducible measurements

Run from the ecosystem root after resolving the local package checkouts:

```bash
julia --project=TDARipserer.jl TDARipserer.jl/benchmark/p3.jl
julia --project=TDARipserer.jl TDARipserer.jl/examples/p3_algorithms.jl
julia --project=TDAPersistenceDiagrams.jl TDAPersistenceDiagrams.jl/examples/p3_diagrams.jl
julia --project=JuliaTDA.jl -e 'include("JuliaTDA.jl/test/p3.jl")'
```

Exploratory local run: Julia 1.12.5, Linux x86-64, Intel i9-13980HX, one
Julia worker thread. Workloads are deterministic; each is compiled/warmed
before measuring. The script reports the best elapsed time and minimum
allocated bytes over three repetitions (two for the 20,000-point case).
Other work was running on the machine, so these are local observations rather
than release performance guarantees. Allocation totals are not peak memory.

| Workload | Best elapsed | Allocated bytes |
|---|---:|---:|
| 1,200 circle points, lazy witness with 48 landmarks | 1.86 ms | 2,811,288 |
| 1,200 circle points, full Rips | 297.22 ms | 44,234,760 |
| 20,000 witnesses, 64 landmarks | 60.58 ms | 55,544,224 |
| 10,000 zigzag triangle additions/deletions | 43.91 ms | 21,731,576 |
| 30 vineyard frames, 120 cells | 150.66 ms | 110,086,744 |
| 30 fresh reductions of the same 120-cell complex | 10.71 ms | 9,465,808 |

Both circle constructions detect H₁, but witness and Rips generally compute
different barcodes. For 20,000 points, the witness distance matrix contains
10.24 MB of Float64 entries; a dense full-cloud matrix would contain 3.2 GB.
The latter large Rips computation was not run.

The zigzag stream uses 5,008 binary column additions and at most seven active
simplices. The vineyard workload uses 845 adjacent transpositions and 155
column additions. Its crossing scans, sparse permutations and vine bookkeeping
cost more than fresh reduction on this small example. Use incremental updates
for retained tracks or sufficiently small order changes; do not assume a speedup
for large permutations. The benchmark publishes that unfavorable comparison.

## Implementation locations

- [Dynamic algorithms and witness guide](../TDARipserer.jl/docs/src/dynamic.md)
- [Diagram averaging guide](../TDAPersistenceDiagrams.jl/docs/src/means.md)
- [Kernel guide](../TDAPersistenceDiagrams.jl/docs/src/kernels.md)
- [Runnable dynamic example](../TDARipserer.jl/examples/p3_algorithms.jl)
- [Runnable averaging/kernel example](../TDAPersistenceDiagrams.jl/examples/p3_diagrams.jl)
- [Benchmark script](../TDARipserer.jl/benchmark/p3.jl)
- [Umbrella integration test](../JuliaTDA.jl/test/p3.jl)
