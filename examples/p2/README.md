# P2 worked examples

From the workspace root, resolve the public ecosystem sources once:

```sh
julia JuliaTDA.jl/examples/p2/setup.jl
julia --project=JuliaTDA.jl/examples/p2 JuliaTDA.jl/examples/p2/euler_images.jl
```

Run each other `.jl` example with the same `--project` option.

| Example | Workflow |
|---|---|
| `euler_images.jl` | Cubical ECC, directional ECT, exact SECT, five image filtrations, PH and native MLJ composition |
| `multiparameter.jl` | Function-Rips, H₁ Hilbert, Koszul Betti numbers, signed-measure MLJ features |
| `optimal_cycles.jl` | Weighted explanatory loop and minimum filling with certified F₂ ILPs |
| `time_series_periodic.jl` | Seeded noisy periodic signal → DelayEmbeddings → window PH and Mapper |
| `time_series_dynamics.jl` | DynamicalSystemsBase Hénon trajectory → embedding → window PH and Mapper |
| `nonlinear_mapper.jl` | Seeded MLP radial-filter fit, graph regularization, linear MSE comparison |

For time series, a delay is in sample counts. Select it on training data using
`suggest_delay(series; method="mi_min", lags=1:100)` or known physical periodicity.
Compare several delays and embedding dimensions: no estimator guarantees an optimum.
Choose windows long enough to contain the phenomenon (48 samples is two periods
in the periodic example); shorter windows need not contain a loop. A larger delay
reduces the number of available states. Subsample large windows to control Rips cost.
Resample irregular observations first, and split time chronologically before tuning.
Overlapping windows are dependent: use disjoint windows or blocked validation when
making statistical comparisons. PH alone is not a test for deterministic chaos.

The nonlinear example minimizes radial-filter squared error with a small extended
graph-persistence penalty. It compares against a linear model **with an intercept**,
so the improvement is due to nonlinear radial structure. It demonstrates filter
training, not an out-of-sample prediction claim. Model structure and parameters are
explicit; Flux Dense/Chain and fixed-state Lux models can replace the native MLP.

Add `--local` to the setup command to use sibling checkouts instead. The umbrella
and bundled multiparameter package use this checkout in both modes. Setup does
not publish or register packages.
