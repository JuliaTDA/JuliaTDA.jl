# JuliaTDA ecosystem roadmap

**Canonical roadmap — reviewed 5 November 2026. Publication and registration remain deferred.**

This is the single source of truth for unfinished work across the JuliaTDA ecosystem. It supersedes the planning sections in `gap-analysis.md`, `2026 Roadmap.md`, `2026 Roadmap — Phase 5 Addendum.md`, and `2026 Roadmap — July 2026 Review.md`. Those files remain useful as historical reviews, but new status and priority decisions belong here.

## How to read the priorities

| Priority | Meaning | Decision rule |
|---|---|---|
| **P0 — release blocker** | Adoption, correctness, or maintenance work that blocks a dependable public ecosystem | Do before starting another major feature |
| **P1 — next differentiator** | High-value work that strengthens an existing advantage or closes an important workflow gap | Start after P0 is under control |
| **P2 — strategic expansion** | Valuable new audiences or research capabilities with meaningful implementation cost | Choose one track at a time after P1 foundations |
| **P3 — long-term** | Difficult, niche, or demand-dependent work | Keep scoped; promote only with a user/research driver |
| **Watch** | Interesting, but not currently justified | Reassess periodically; do not schedule yet |

Within a priority, tasks are listed in recommended execution order. “Importance” expresses ecosystem impact, while the priority also accounts for urgency, dependencies, and effort.

## Current baseline: already shipped

Do not reopen these as feature gaps unless a regression is found.

- Core PH: Rips, Alpha, Cubical, Custom, and EdgeCollapsedRips filtrations; representative cycles and circular coordinates.
- Persistence diagrams: bottleneck/Wasserstein/Sliced Wasserstein distances; landscapes, images, Betti curves, silhouettes, entropy summaries; Sliced Wasserstein and Persistence Fisher kernels; `kernel_matrix`.
- Mapper: classical and Ball Mapper, broad cover/refiner/nerve support, Tables integration, interactive exploration, `soft_mapper`, `optimize_filter`, and loop-aware extended persistence (`Ord0`, `Ext0`, `Ext1`).
- Statistical TDA: `bootstrap_diagram`, `permutation_test`, and `significant` in PersistenceInference.jl.
- Geometry/data: 27 datasets, seven distance wrappers, KDE/DTM/kNN densities, transformations, `geodesic_distance`, and `nerve_2d`.
- ToMATo clustering and its TDAplots integration.
- JuliaTDA.jl umbrella package and central worked-example documentation.
- P2 expansion APIs: cubical ECC, simplicial/cubical ECT and exact SECT; bounded F₂ multiparameter invariants and MLJ measure features; optional JuMP/HiGHS optimal chains; DelayEmbeddings/window PH workflows; five binary-image filtrations; explicit MLP/Flux/Lux Mapper filters. See the completed P2 tracks below for supported scopes.
- P3 algorithm APIs: weak/lazy witness filtrations, online F₂ zigzag persistence, fixed-complex vineyards, weighted Euclidean Wasserstein diagram means, and scale-space/weighted Gaussian kernels. All are exposed through JuliaTDA; see the completed P3 scopes and validation below.
- Test CI and documentation workflows now exist for all eight packages; PersistenceInference, TDAplots, and ToMATo now have Documenter sites and substantive READMEs.

## JuliaTDA Studio — visual workbench (3 October 2026)

The standalone [MapperStudio.jl](https://github.com/JuliaTDA/MapperStudio.jl)
application now connects the existing Julia algorithms to a local browser workbench:
Mapper/Ball Mapper, linked selections, named row populations, statistical
Explain, Rips diagrams/barcodes/Betti, cover sensitivity, ToMATo, temporal PH,
cubical image PH/Euler, and function-Rips Hilbert/Euler surfaces. JSON workspaces,
CSV/SVG/results and self-contained Julia scripts support reproducibility.
The [Ayasdi research](https://github.com/JuliaTDA/MapperStudio.jl/blob/main/docs/ayasdi-research.md) distinguishes
confirmed historical capabilities, implementation choices and remaining gaps.

This first release is bounded to 3,000 rows/80 geometry variables and sampled
expensive calculations. Industrial sparse/distributed scale, proprietary lenses,
automatic model selection, deeper scientific GUI coverage and multiuser workflows
remain expansion work; the workbench does not make those capabilities release
prerequisites for the underlying packages. Registration remains deferred.

## P0 — make the ecosystem releasable and easy to install

These tasks have the highest return. The local General registry snapshot (last updated 3 July 2026 and checked on 12 July) contains the original Ripserer and PersistenceDiagrams packages. JuliaTDA now maintains independent TDARipserer and TDAPersistenceDiagrams packages; the eight ecosystem packages and the bundled MultiparameterPersistence package need their own registrations. Publication and registration are deferred.

| ID | Task | Package(s) | Importance | Why it matters / definition of done |
|---|---|---|---|---|
| **P0.1** | ✅ **Complete (12 July 2026)** — Make every unregistered package registry-ready | All six unregistered packages | **Critical** | Complete compat bounds, Aqua, supported-Julia CI matrices, licenses, UUID/dependency validation, and release notes are in place. A dependency-ordered local registration passed RegistryCI 11's registry consistency suite (138/138). First registration of the existing 0.2.0 MetricSpaces/ToMATo releases and the intentionally branded JuliaTDA package may require General's normal manual policy review; no technical RegistryCI failures remain. |
| **P0.2** | ✅ **Complete — working-tree review** | TDAmapper | **Critical** | The former five-file working tree has been committed; the checkout is clean at `b4ebfdd`. The remaining consolidation work was in JuliaTDA, reviewed in the November maintenance pass. |
| **P0.3** | **Deferred by owner — publication and registration** | Ecosystem | **Critical when publication resumes** | Register TDAPersistenceDiagrams → TDARipserer; MetricSpaces → TDAmapper and ToMATo; then TDAplots, PersistenceInference and MultiparameterPersistence → JuliaTDA. Tag releases and validate registry-only `Pkg.add("JuliaTDA")` when explicitly authorized. No publication is part of the November maintenance pass. |
| **P0.4** | ✅ **Complete (3 October 2026)** — Add PersistenceInference to the umbrella | JuliaTDA, PersistenceInference | **Critical** | Dependency/compat, public API re-exports, a documented inference workflow and umbrella tests are in place. The full JuliaTDA suite and the P1 integration checks pass. Registration remains deferred. |
| **P0.5** | ✅ **Complete — independent TDARipserer identity** | TDARipserer, JuliaTDA, PersistenceInference | **Very high** | Independent name, UUID, version series, downstream imports and MLJ metadata are implemented. History, credits and the upstream remote remain intact. The historical GitHub slug `Ripserer.jl` is intentional. |
| **P0.6** | ✅ **Complete — independent TDAPersistenceDiagrams identity** | TDAPersistenceDiagrams, TDAplots | **Very high** | Independent name, UUID and version series are implemented; experimental APIs and shared diagram bindings are retained. Credits and the upstream remote remain intact. The historical GitHub slug `PersistenceDiagrams.jl` is intentional. |
| **P0.7** | ✅ **Complete — repository transfer** | JuliaTDA | **High** | GitHub resolves the old personal URL to `JuliaTDA/JuliaTDA.jl`; README, documentation and workflow links use the organization. Local origin is updated during the November maintenance pass. |
| **P0.8** | ✅ **Complete — source-mode integration check** | JuliaTDA | **High** | `scripts/setup.jl` resolves public siblings into an isolated project, while `--local` selects workspace checkouts. `scripts/smoke.jl` exercises Mapper, PH/vectorization, inference, ToMATo and rendered plots; CI runs it on the supported Julia matrix. Registry-only installation remains part of deferred publication. See the November maintenance report for executed results. |

### Current maintenance order

1. Consolidate the already implemented umbrella features, examples, tests and documentation in local commits.
2. Validate Julia 1.10 and the installed Julia 1.12 toolchain, public-source installation in an isolated environment, rendered smoke pipelines and documentation builds.
3. Audit legacy GitHub issues against implemented features; retain explicit scope gaps rather than treating all old issues as missing implementations.
4. Validate the DataStructures 0.19 compatibility update for TDARipserer.
5. Keep release tags, registration and deployment deferred. A registry-only install is a later publication acceptance check.

The original release sprint described unregistered installation as a blocker. With publication deliberately deferred, source installation and local integration are the current acceptance criteria.

## P1 — consolidate the ecosystem's strongest advantages

| ID | Feature/task | Natural home | Importance | Effort | Why now / definition of done |
|---|---|---|---|---|---|
| **P1.1** | ✅ **Complete** — Statistical inference round 2 | PersistenceInference | **Very high** | Medium | Landscape/Betti mean confidence bands, Gaussian multiplier/ordinary curve bootstrap, explicit-null maximum-persistence significance and HSIC permutation independence tests. Seeded 1000-run coverage/type-I calibration, independent NumPy/SciPy checks, references and worked examples; finite-grid/asymptotic limits and observed undercoverage documented. |
| **P1.2** | ✅ **Complete** — Differentiable persistence layer | TDARipserer extensions | **Very high** | High | Finite Rips H0/H1 over F₂; birth/death gradients to Euclidean coordinates or dense symmetric distance/filtration values. Optional ChainRulesCore and Enzyme extensions, `topological_loss`, independently checked endpoint gradients, executed seeded Flux/Lux examples and dedicated CI. Ties/pairing changes and unsupported filtrations are documented. |
| **P1.3** | ✅ **Complete** — Tunable MLJ pipelines | TDAPersistenceDiagrams, TDARipserer, JuliaTDA docs | **High** | Medium | Recommended hyperparameter metadata and recursive `tuning_ranges(pipeline)` produce native MLJ ranges. Executed persistence-image `TunedModel` example uses nested stratified CV with vectorizer fitting inside each fold. Empty training folds use a fixed grid without consulting validation data. |
| **P1.4** | ✅ **Complete** — High-value vectorization set | TDAPersistenceDiagrams | **High** | Medium | Euler characteristic curve, integrated persistence blocks, tropical coordinates, tent templates, ComplexPolynomial, TopologicalVector and seeded weighted ATOL codebooks. Training-only MLJ fitting, fixed output shapes, analytic/permutation/diagonal/stability tests and descriptor-specific evaluation/caveats. Changes live in the independent experimental fork. |
| **P1.5** | ✅ **Complete** — Benchmarks and numerical validation | TDAPersistenceDiagrams, PersistenceInference, TDAmapper | **High** | Medium | Seeded SW/kernel and differentiable-Mapper benchmarks with median/allocation baselines and environment metadata; GUDHI 3.11 fixtures and independent published-formula inference checks with explicit tolerances. Validation corrected an extra 1/π SW normalization; migration is documented. |

All five P1 items were implemented locally on **3 October 2026**; registration remains deferred. The [P1 workflow guide](docs/src/examples/p1.md), [nested-CV example](examples/tuned_ph_pipeline.jl), [AD examples](TDARipserer.jl/examples/differentiable/), [inference validation](PersistenceInference.jl/validation/README.md), [diagram validation](TDAPersistenceDiagrams.jl/docs/src/validation.md) and [Mapper benchmark guide](TDAmapper.jl/benchmarks/README.md) provide reproducible entry points. Core/full ecosystem suites and Aqua pass on Julia 1.12.5; diagram tests also pass on Julia 1.6.7, and AD/Flux/Lux examples on Julia 1.10.10. Optional AD supports Julia ≥1.9; training examples require ≥1.10. Legacy version-gated doctests remain skipped; the new examples, numerical fixtures and documented workflows were executed separately.

## P2 — strategic expansion tracks

**All six tracks implemented on 3 October 2026 at the owner's request; registration remains deferred.** The first releases use the bounded scopes below. MultiparameterPersistence is a separate package bundled under `lib`, and heavy integrations use package extensions. The [six runnable examples](examples/p2/README.md) resolve local checkouts without registration.

| ID | Feature/task | Natural home | Importance | Effort | Value and scope gate |
|---|---|---|---|---|---|
| **P2.1** | ✅ **Complete** — Euler Characteristic Transform (ECC/ECT/SECT) | MetricSpaces | **High** | Medium | `cubical_ecc`, simplicial/cubical `ect`, exact centered-step `sect`, sampled unit directions and `euler_table`. Vertex lower-star cubical convention; shared thresholds and table ordering documented. Reference cell counts and analytical integrals tested. Differentiability is a later extension. |
| **P2.2** | ✅ **Complete, stages 1–3** — Multiparameter persistence | Bundled MultiparameterPersistence | **High** | Very high | Function-Rips `bifiltration`; exact F₂ Hilbert functions, Koszul β₀/β₁/β₂ and Euler surfaces on finite grids; Möbius signed measures and Gaussian MLJ features with training-only centers. Tests include a genuine β₂ syzygy and reconstruction identities. Dense reference algorithm for small complexes, with size guards. The documented stability bound applies to matched atomic perturbations, including Euler grades with fixed combinatorics; arbitrary raw Hilbert measures have no unconditional stability claim. Landscapes, MMA and minimal presentations remain outside this release. |
| **P2.3** | ✅ **Complete** — Optimal representative cycles/volumes | TDARipserer JuMP/HiGHS extension | **High** | Medium–high | Certified minimum-weight F₂ homologous cycles and fillings on Rips/Custom, independent boundary certificates, brute-force optimality tests and an explicit lexicographic tie policy. H₁ cocycle conversion; higher dimensions require homology cycle representatives. Enumeration and per-solve limits documented. |
| **P2.4** | ✅ **Complete** — Time-series TDA bridge | TDARipserer DelayEmbeddings extension / JuliaTDA examples | **Medium–high** | Medium | Native delay embeddings/estimation, sliding-window PH with embedded indices, MetricSpaces/Mapper composition and parameter-selection/blocked-validation guidance. Seeded periodic-signal and DynamicalSystemsBase Hénon examples both run. |
| **P2.5** | ✅ **Complete** — Image/cubical preprocessing pipeline | MetricSpaces / TDARipserer | **Medium–high** | Medium | Height, radial, dilation, erosion and signed-distance filtrations, exact anisotropic Euclidean distances, callable `ImageFiltration`, optional MLJ transformer and finite-threshold `image_persistence`. Tests cover brute-force distances, masks and MLJ→Cubical composition. Inputs are binary vertex masks; grayscale thresholding is explicit. |
| **P2.6** | ✅ **Complete** — Nonlinear trainable Mapper filters | TDAmapper extensions | **Medium** | Medium | Native `MLPFilter`, explicit parameter trees, seeded initialization, generic `optimize_filter`, deterministic Flux Dense/Chain and fixed-state Lux adapters. Parameter gradients and optimization tested. The seeded radial-filter example improves MSE from 0.21553 (linear model with intercept) to 0.00336 with a small extended-persistence penalty. Mapper combinatorics remain fixed within each gradient step. |

Validation and follow-up:

- Each track includes public docstrings, tests, a changelog entry and a runnable umbrella example. Cross-package examples and real MLJ machines are validated in a local environment; no packages have been registered or published.
- The complete suites for MetricSpaces, MultiparameterPersistence, TDAmapper, TDARipserer and JuliaTDA pass on Julia 1.12. P2 reference tests also pass on Julia 1.10; minimum-version checks cover Euler/images on 1.8, neural filters/adapters on 1.9 and base PH workflows on 1.6. Optional extensions require Julia 1.9+. The new documentation pages render with Documenter.
- Multiparameter calculations use exact Boolean algebra on finite grids. Include all critical grades when comparing grid-module Betti numbers to an unsampled module. Benchmark real workloads before raising the reference algorithm's limits.
- Optimal-chain optimization is a potentially expensive integer program; choose `tie_break=:solver` when one optimal answer is sufficient. Flux/Lux integrations retain explicit parameters and prohibit hidden training-state updates.
- Future expansion should be driven by users of these six workflows: larger multiparameter algorithms, additional coefficient/filtration support, or descriptor differentiation are separate work items.

## P3 — long-term algorithmic work

**All five items implemented on 3 October 2026 at the owner's request; registration remains deferred.** See [P3 implementation and validation](docs/maintenance/p3-verification.md) for reference tests, reproducible measurements, examples and supported scopes.

| ID | Feature/task | Importance | Implemented API and scope |
|---|---|---|---|
| **P3.1** | ✅ **Complete** — Witness complexes | Medium | TDARipserer `Witness` and `LazyWitness`, landmark provenance, rectangular distance inputs, face closure and zero-valued lazy edges. The lazy construction uses the implicit flag PH engine. Circle/sphere references and a 20,000-witness benchmark are included. Witness barcodes need not equal full-cloud Rips barcodes. |
| **P3.2** | ✅ **Complete** — Fast zigzag persistence | Medium | `ZigzagPersistence`, `ZigzagEvent`, `zigzag_persistence` and `zigzag_diagrams`: retained sparse cycle/boundary/filling bases over F₂, arbitrary requested homology dimensions and recycled chain coordinates. Every subinterval rank is checked against an independent dense oracle. Valid simplex additions/deletions only; open intervals are right-censored. |
| **P3.3** | ✅ **Complete** — Fréchet means / diagram averaging | Medium | TDAPersistenceDiagrams `frechet_mean`, `diagram_mean`, `frechet_variance` and `FrechetMeanResult`: normalized weights, squared Euclidean Wasserstein assignments, diagonal-aware updates, cardinality growth, multiple starts and convergence diagnostics. Analytical references include essential intervals with equal cardinality. Three-or-more-input optimization has no global-optimum certificate. |
| **P3.4** | ✅ **Complete** — Vineyards / incremental persistence | Medium | `Vineyard`, `update_vineyard!` and `vineyard_diagrams`: fixed simplicial complex over F₂, retained `R = D*V`, chronological adjacent transpositions and continuous vine identities through diagonal crossings. Fresh-PH/factorization checks cover ties and mixed dimensions. Large permutations can be slower than fresh reduction; the benchmark records this limitation. |
| **P3.5** | ✅ **Complete** — Remaining diagram kernels | Low–medium | `PersistenceScaleSpaceKernel` and `PersistenceWeightedGaussianKernel`, including linear weighted embeddings and optional outer Gaussian kernels. Analytical paper formulas, Gram PSD, diagonal/empty behavior and parameter validation are tested. Essential intervals are ignored, with the custom-weight stability scope documented. |

Validation: complete affected-package suites and Aqua passed on Julia 1.12.5; final P3 tests passed on Julia 1.6.7 and 1.12.5. The JuliaTDA integration checks, runnable examples and Documenter P3 page build also passed. Legacy doctests skipped by their existing version gates are recorded separately in the validation report.

## Maintenance review — 5 November 2026

- Consolidated the umbrella's P1–P3 code, bundled library, examples, docs and existing reproduction assets in local commit `77eb787`.
- Full JuliaTDA suites passed on Julia 1.12.5 and the supported minimum 1.10.10; MultiparameterPersistence, ToMATo and TDARipserer suites passed. Umbrella and ToMATo documentation builds passed without deployment.
- Public-source installation uses environment-local clones rather than globally cached development checkouts. Cross-package smoke checks include actual PNG rendering.
- TDARipserer's DataStructures 0.19 PR passed its full suite with 0.19.6 and was fast-forwarded locally to `c9d6ae1`. The remote PR remains open with validation recorded; source pushes are deferred together with publication.
- TDAmapper's complete suite passed after allowing five minutes for Aqua's isolated cold-precompile shutdown check. The check remains enabled.
- Legacy Mapper issues #2, #3, #5 and #6 and ToMATo documentation issues #1 and #2 are closed with implementation evidence. Mapper #7 now tracks only arbitrary n-dimensional generalization; its two-dimensional portion is implemented.
- See [the maintenance verification report](docs/maintenance/2026-11-05.md) for exact commands, source revisions, failed attempts and validation limits.

## Watch list and explicit non-goals

- Watch: GPU/distributed PH, persistent Laplacians, Reeb graphs, magnitude, and new stable upstream libraries that JuliaTDA could wrap instead of reimplement.
- Do not build a general topological-deep-learning framework. Integrate persistence/Mapper descriptors with Flux, Lux, and GraphNeuralNetworks instead.
- Do not build a new plotting backend; keep TDAplots on Makie.
- Do not port a full C++ PH engine merely for language purity. Extend or contribute upstream when possible.
- Do not begin MMA/minimal-presentation work before the cheap multiparameter invariants have users and benchmarks.

## Ecosystem-wide recurring work

These are not separate feature projects; apply them to every roadmap item.

- Every public feature needs unit tests, a mathematical/reference test where applicable, a docstring, one runnable example, and a changelog entry.
- Keep compatibility bounds current and test the oldest and newest supported Julia versions.
- Test cross-package behavior in JuliaTDA before tagging downstream packages.
- Prefer package extensions/weak dependencies for heavy optional stacks such as Makie, MLJ, Zygote, Flux, Lux, JuMP, and image tooling.
- Maintain explicit independent experimental forks in TDARipserer and TDAPersistenceDiagrams, preserving credits and selectively incorporating fixes from the original Ripserer and PersistenceDiagrams projects.
- Rebuild the 2026 workshop and umbrella examples before ecosystem releases. Freeze old workshops to tagged environments rather than silently tracking `main`.
- Review this file monthly: move shipped work into the baseline, record blockers, and promote at most one P2 track at a time.

## Decision summary

All P1, P2 and P3 initial scopes are implemented. The November maintenance pass
consolidates the umbrella checkout, installs public source dependencies without
sibling checkouts, checks cross-package behavior and reconciles legacy issues.
Publication, registration and release tags remain explicitly deferred.

Larger multiparameter algorithms, enterprise Studio scale and research-paper
reproductions beyond the existing partial Mapper 2007 reproduction are separate
expansion projects, not missing acceptance criteria for this maintenance pass.
