# Limits and reproducibility

```@meta
CurrentModule = MultiparameterPersistence
```

## Exact arithmetic within a finite problem

The package computes homology and inclusion-map ranks over F₂ using Boolean
elimination and XOR. “Exact” refers to that algebra: it does not use approximate
floating-point ranks. Coordinates and simplex grades are `Float64`, however,
and Euclidean distances use floating-point arithmetic. Near-equal grades are
compared with the ordinary `≤` relation, without a tolerance. Record the
coordinates, transformation of the function values, and chosen axes if boundary
comparisons matter.

No orientation signs are needed over F₂. Other coefficient fields, arbitrary
numbers of parameters, minimal presentations, matching distances, MMA, and
multiparameter landscapes are outside the implemented scope.

## Dense computation and guards

A Rips construction enumerates combinations of vertices through dimension
`dim_max+1`. For `n` vertices with no scale truncation, that can include
`sum(binomial(n,k) for k in 1:min(n,dim_max+2))` simplices. Homology calculations
assemble dense chain matrices; bigraded Betti calculations also retain homology
spaces on the whole grid. Use tiny examples first.

| Keyword | Default | Applies to | Meaning |
| --- | --- | --- | --- |
| `dim_max` | `1` | `bifiltration` | Maximum intended homology degree; construct one more chain degree |
| `max_scale` | `Inf` | `bifiltration` | Omit simplices whose largest edge exceeds this scale |
| `max_simplices` | `20_000` | `bifiltration` | Stop after this many enumerated simplices |
| `max_grid` | `4096` | Grid computations | Maximum product of axis lengths |
| `max_chain` | `2048` | Hilbert and bigraded Betti computations | Maximum number of simplices in any one chain dimension |
| `max_workspace` | `100_000_000` | Hilbert and bigraded Betti computations | Conservative dimension-based workspace guard |

The workspace guard checks `largest_chain^2`, multiplied by the grid size when
homology spaces must be retained. Its value is a guard estimate, **not a byte
budget or measured peak allocation**. All guards are ceilings, not promises
that a computation close to the ceiling will be fast. Lower `max_scale`, grid
resolution, cloud size, or `dim_max` before raising guard values. A direct
`Bifiltration` constructor validates a supplied complex but does not apply
`bifiltration`'s enumeration guard; invariant calculations still use their own
limits. Euler surfaces do not assemble chain matrices.

## Truncation changes the object

A `max_scale` cutoff changes the simplicial complex available beyond that scale.
To study H₁ deaths, triangles must be present; to study H₂ deaths, tetrahedra
must be present. Conversely, Euler surfaces concern **all constructed simplices**,
so extra chain dimensions affect them even when your target was only H₁.
A coarsely sampled Hilbert grid can miss intermediate features even if the
complex includes them. These are separate truncation choices and should be
reported separately.

A grid invariant stores `values[scale_index, level_index]`. A signed grid measure
uses zero values below the first axes and constant extension above the last
axes. Bigraded Betti numbers are calculated for the sampled grid module with
those boundary conventions. Include all relevant critical grades when you
want that grid to faithfully represent the original finite module. A rectangular
product of all critical coordinates may itself be too large for the reference
implementation; the package does not solve that scaling problem automatically.

## Common problems

- **“Missing face” or “face born after simplex”:** include every face and use
  componentwise nondecreasing grades.
- **Unexpected row/column counts:** coordinate-matrix points are columns;
  grid-invariant rows are scales and columns are levels.
- **An apparently immortal hole:** inspect both the maximum sampled scale and
  the available higher-dimensional simplices.
- **Euler differs from H₀−H₁:** include every homology dimension of the actual
  truncated complex in the alternating sum.
- **`beta2` differs from H₂:** it describes dependencies among H`dim` module
  relations, not an H₂ dimension.
- **No method for `measure_vectorizer_model`:** install and load
  `MLJModelInterface` to activate the extension.
- **Guard exceeded:** reduce the problem before raising a ceiling; dense
  matrices can grow quickly.
- **Features change after grid refinement:** a Hilbert signed measure encodes
  the sampled grid; refinement changes its atoms. Exact Euler measures avoid
  grid snapping, but summarize a different invariant.

## Reproduce the examples and checks

From the ecosystem workspace containing `JuliaTDA.jl`:

```sh
julia --project=JuliaTDA.jl/lib/MultiparameterPersistence/docs -e 'using Pkg; Pkg.develop(path="JuliaTDA.jl/lib/MultiparameterPersistence"); Pkg.instantiate()'
julia --project=JuliaTDA.jl/lib/MultiparameterPersistence/docs JuliaTDA.jl/lib/MultiparameterPersistence/docs/make.jl
julia --project=JuliaTDA.jl/lib/MultiparameterPersistence -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

Open the package's `docs/build/index.html`. The build executes all tutorial
examples and never deploys. To use a prepared environment elsewhere, invoke the
same `docs/make.jl` under that environment; it must provide the local package,
Documenter, Tables, and MLJModelInterface.

The existing tests cover the two-point module, a square's H₁ birth/death, genuine
Koszul syzygies, Euler/homology agreement, cumulative reconstruction, the
matched-atom Gaussian perturbation bound, invalid inputs, computation guards,
and reuse of MLJ training centers. These checks substantiate the documented
small-problem behavior, not scalability to large clouds or unconditional
statistical/ML stability.

## Background reading

[Lesnick's multiparameter persistence notes](https://mlesnick.github.io/840_2022/Math840_Notes_22.pdf)
explain modules, presentations, and Koszul homology.
[Oudot and Scoccola (2024)](https://doi.org/10.1137/22M1489150) explain stability
of multigraded Betti numbers and Hilbert functions with specified notions of
comparison. Their results should not be read as stability of arbitrary raw arrays
under any chosen norm.
