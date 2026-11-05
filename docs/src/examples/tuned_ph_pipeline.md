# Tuning a persistence-image pipeline

PH models and vectorizers now expose `recommended_ranges(model)` and
`tuning_ranges(model)`. The latter returns native MLJ range objects, including
the paths of supported TDA models nested in a `Pipeline`. Import MLJ or MLJBase
before using it; the core packages do not depend on the full MLJ stack.

```julia
using JuliaTDA, MLJ, MLJDecisionTreeInterface
ph = RipsPersistentHomology(vectorizer=PersistenceImageVectorizer())
pipeline = Pipeline(ph=ph,classifier=DecisionTreeClassifier())
tuned = TunedModel(model=pipeline,range=tuning_ranges(pipeline),
    tuning=RandomSearch(),resampling=StratifiedCV(nfolds=3),
    measure=misclassification_rate,n=8)
```

Fit `machine(tuned, X, y)` where **each row of X is an independent point cloud**.
Every inner training fold computes its own diagrams and fits its own image grids
and data-derived bandwidths. This also applies to learned ATOL codebooks.
Do not fit a vectorizer on all diagrams before cross-validation. PH can be
precomputed per independent cloud if all PH settings are fixed, but data-derived
feature fitting must remain inside each fold.

The executable example at `examples/tuned_ph_pipeline.jl` generates independent
noisy circles and uses an outer stratified CV around `TunedModel`, so hyperparameter
selection and performance estimation have separate folds. It then refits on all
training clouds. Run it from an environment containing the local ecosystem, MLJ,
and MLJDecisionTreeInterface. The example uses package-provided ranges without
custom model adapters. Outer performance is an estimate for this toy distribution,
not an application benchmark.

From the ecosystem workspace, set up and execute the supplied example:

```sh
julia --project=JuliaTDA.jl/examples -e 'using Pkg; Pkg.develop([PackageSpec(path=p) for p in ["MetricSpaces.jl","TDAmapper.jl","TDAplots.jl","TDAPersistenceDiagrams.jl","TDARipserer.jl","PersistenceInference.jl","ToMATo.jl","JuliaTDA.jl/lib/MultiparameterPersistence","JuliaTDA.jl"]]); Pkg.instantiate()'
julia --project=JuliaTDA.jl/examples JuliaTDA.jl/examples/tuned_ph_pipeline.jl
```

Recommended bandwidth/cutoff bounds assume coordinates on a scale near one;
adapt ranges to training data units and the computation budget. Maximum homology
dimension can dominate runtime. Thresholds have deliberately no universal range.
Categorical coefficient choices are primes. Training folds with no finite bars
use a fixed fallback image grid and never consult held-out diagrams.

Reference: [MLJ tuning and nested resampling documentation](https://juliaai.github.io/MLJ.jl/stable/tuning_models/).
