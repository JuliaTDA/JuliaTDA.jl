# MultiparameterPersistence.jl

Exact two-parameter persistence over F₂ for small simplicial complexes, bundled
in `JuliaTDA.jl/lib`. Use it to understand a function-Rips bifiltration, check
small mathematical examples, and turn signed measures into shared numerical
features. It is a dense reference implementation with explicit computation guards.

## Install

Use Julia ≥1.10. From an ecosystem workspace with a `JuliaTDA.jl` checkout:

```julia
using Pkg
Pkg.activate("multiparameter-example")
Pkg.develop(path="JuliaTDA.jl/lib/MultiparameterPersistence")
```

Without a checkout, the package can be installed from the repository subdirectory:

```julia
Pkg.add(url="https://github.com/JuliaTDA/JuliaTDA.jl",
        subdir="lib/MultiparameterPersistence")
```

The standalone package needs only `Tables` and `LinearAlgebra`. The umbrella
`JuliaTDA` package also reexports this API. Do not assume a registry installation
for a package currently bundled in `lib`.

## Watch a loop appear and fill

```julia
using MultiparameterPersistence
points = [[0.,0.], [1.,0.], [1.,1.], [0.,1.]]
F = bifiltration(points, zeros(4); dim_max=1)
grid = (scales=[0., 1., sqrt(2)], levels=[0.])
H = hilbert_function(F; grid..., dim=1)
@assert H.values[:,1] == [0,1,0]
B = bigraded_betti(F; grid..., dim=1)
@assert cumsum(cumsum(B.beta0.values - B.beta1.values + B.beta2.values;
                     dims=1); dims=2) == H.values
```

At scale 0 there are only vertices; at scale 1 the square has a loop; at √2
triangles fill it. The second coordinate sets a maximum allowed vertex function
value. Raising either parameter adds simplices. `dim_max` is the maximum intended
**homology** dimension; the constructor includes one extra chain dimension so
features in that dimension can die.

## Read the documentation

- [Start here](docs/src/index.md): two parameters, package scope, and installation.
- [Function-Rips tutorial](docs/src/tutorial.md): filter a remote point, inspect
  scales and levels, and read the returned tables.
- [Invariants](docs/src/invariants.md): Hilbert dimensions, Euler surfaces,
  generators/relations/syzygies, and a genuine β₂ example.
- [Signed measures and MLJ](docs/src/measures.md): cumulative reconstruction,
  Gaussian vectorization, shared centers, and training-fold fitting.
- [Limits and reproducibility](docs/src/practical.md): critical grades, dense
  computation guards, truncation, exact arithmetic, and stability conditions.
- [API reference](docs/src/api.md): every public function and data type.

`values[scale_index, level_index]` is the common orientation for grid invariants.
Bigraded Betti numbers are properties of the **sampled grid module**, not the
pointwise topological Betti counts. Include all relevant critical grades to
represent the finite module faithfully.

`signed_measure(F)` is the exact Euler measure at actual simplex grades;
`signed_measure(hilbert_function(...))` is a grid-derived homology measure.
`MeasureVectorizer(centers; bandwidth)` gives a fixed output size. Its matched-atom
Lipschitz bound assumes bounded total variation and fixed weights; it is not an
unconditional interleaving-stability claim for any homology summary. Raw Betti
arrays are not automatically stable ML features.

## Build the docs and run the tests

From the ecosystem workspace:

```sh
julia --project=JuliaTDA.jl/lib/MultiparameterPersistence/docs -e 'using Pkg; Pkg.develop(path="JuliaTDA.jl/lib/MultiparameterPersistence"); Pkg.instantiate()'
julia --project=JuliaTDA.jl/lib/MultiparameterPersistence/docs JuliaTDA.jl/lib/MultiparameterPersistence/docs/make.jl
julia --project=JuliaTDA.jl/lib/MultiparameterPersistence -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

The build executes tutorial examples and creates `docs/build/index.html`; it does
not deploy. `MLJModelInterface` is included in the documentation environment to
execute the optional adapter tutorial, while it remains optional at runtime.
A full MLJBase example also lives in
[`../../examples/p2/multiparameter.jl`](../../examples/p2/multiparameter.jl).

For mathematical background see [Lesnick's multiparameter notes](https://mlesnick.github.io/840_2022/Math840_Notes_22.pdf)
and [Oudot and Scoccola on stability](https://arxiv.org/abs/2112.11901).
Minimal presentations, MMA, matching distances, and multiparameter landscapes
are not implemented.
