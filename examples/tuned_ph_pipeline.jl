# Prepare with `julia examples/setup.jl [--local]`, then run with --project=examples.
# No feature fitting happens outside CV.
using TDARipserer, TDAPersistenceDiagrams, MLJ, MLJDecisionTreeInterface, Random, Test

function tuned_ph_example(; n_clouds=24, n_points=12, candidates=4)
    rng = Xoshiro(20261003)
    labels = repeat(["small","large"],n_clouds÷2)
    X = [[((label=="small" ? 0.6 : 1.3)*cos(t)+0.015randn(rng),
           (label=="small" ? 0.6 : 1.3)*sin(t)+0.015randn(rng))
          for t in range(0,2π;length=n_points+1)[1:n_points]] for label in labels]
    y = categorical(labels)
    ph = RipsPersistentHomology(;dim_max=1,
        vectorizer=PersistenceImageVectorizer(;width=5,height=5,sigma=0.1))
    pipeline = Pipeline(ph=ph,classifier=DecisionTreeClassifier(;max_depth=3,
        min_samples_leaf=2,rng=Xoshiro(20261003)))
    # Tune the entire pipeline. These nested ranges are supplied by the packages.
    ranges = tuning_ranges(pipeline)
    tuned = TunedModel(;model=pipeline,tuning=RandomSearch(;rng=Xoshiro(17)),
        resampling=StratifiedCV(;nfolds=3,shuffle=true,rng=Xoshiro(18)),
        range=ranges,measure=misclassification_rate,n=candidates)
    machine_tuned = machine(tuned,X,y)
    # Outer folds estimate generalization; inner folds select hyperparameters.
    evaluation = evaluate!(machine_tuned;
        resampling=StratifiedCV(;nfolds=3,shuffle=true,rng=Xoshiro(19)),
        measure=misclassification_rate,verbosity=0)
    @test all(isfinite,evaluation.measurement)
    @test length(only(evaluation.per_fold))==3
    # Final fit on all available training data, after estimating performance.
    fit!(machine_tuned;verbosity=0)
    @test length(predict_mode(machine_tuned,X))==length(X)
    return (evaluation=evaluation,model=fitted_params(machine_tuned).best_model,
        ranges=ranges)
end

if abspath(PROGRAM_FILE)==@__FILE__
    result = tuned_ph_example()
    println("Nested-CV misclassification rate: ",result.evaluation.measurement)
    println("Selected model: ",result.model)
end
