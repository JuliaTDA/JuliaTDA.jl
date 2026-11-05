# Homology and inference API

This page collects the diagram, inference, multiparameter and optional PH APIs
used in the umbrella examples. The statistical target and geometric convention
remain those of the owning package; choose a method with
[Choosing a workflow](workflows.md). For point geometry and Mapper, see
[Geometry, Mapper and visualization API](api.md).

## Diagram vectorizations (TDAPersistenceDiagrams.jl)

```@docs
TDAPersistenceDiagrams.PersistenceCurve
TDAPersistenceDiagrams.Landscapes
TDAPersistenceDiagrams.Silhuette
TDAPersistenceDiagrams.Life
TDAPersistenceDiagrams.Midlife
TDAPersistenceDiagrams.LifeEntropy
TDAPersistenceDiagrams.MidlifeEntropy
TDAPersistenceDiagrams.PDThresholding
TDAPersistenceDiagrams.Landscape
TDAPersistenceDiagrams.BettiCurve
TDAPersistenceDiagrams.PersistenceImage
```

## Statistical inference (PersistenceInference.jl)

Choose a method by its experimental unit and null assumptions, as explained in
[Choosing a workflow](workflows.md). A bootstrap radius, a mean-curve band and
a permutation p-value answer different questions.

```@docs
PersistenceInference.bootstrap_diagram
PersistenceInference.BootstrapResult
PersistenceInference.significant
PersistenceInference.permutation_test
PersistenceInference.PermutationTestResult
PersistenceInference.confidence_band
PersistenceInference.multiplier_bootstrap
PersistenceInference.ConfidenceBand
PersistenceInference.max_persistence_significance
PersistenceInference.MaxPersistenceResult
PersistenceInference.independence_test
PersistenceInference.IndependenceTestResult
```

## Multiparameter invariants

This bundled package uses exact F₂ algebra on finite grids for small complexes.
See the [P2 expansion workflows](@ref) for the sampling and stability scope.

```@docs
MultiparameterPersistence.Bifiltration
MultiparameterPersistence.bifiltration
MultiparameterPersistence.GridInvariant
MultiparameterPersistence.hilbert_function
MultiparameterPersistence.bigraded_betti
MultiparameterPersistence.euler_surface
MultiparameterPersistence.SignedMeasure
MultiparameterPersistence.signed_measure
MultiparameterPersistence.MeasureVectorizer
MultiparameterPersistence.measure_vectorizer_model
```

## Optimal chains, time series and cubical PH

```@docs
TDARipserer.OptimalChainResult
TDARipserer.optimal_cycle
TDARipserer.optimal_volume
TDARipserer.delay_embedding
TDARipserer.suggest_delay
TDARipserer.sliding_window_ph
TDARipserer.image_persistence
```
