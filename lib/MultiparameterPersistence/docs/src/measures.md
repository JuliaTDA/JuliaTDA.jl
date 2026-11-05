# Signed measures and machine-learning features

```@meta
CurrentModule = MultiparameterPersistence
```

## An invariant as weighted atoms

A signed measure is a collection of 2D locations and weights, which can be
negative. [`SignedMeasure`](@ref) stores its atoms as **columns** of a `2×n`
`locations` matrix and a length-`n` `weights` vector. Empty measures use a `2×0`
matrix and an empty weight vector.

For a grid invariant `G`, [`signed_measure`](@ref) takes mixed differences:

```math
w_{ij}=G_{ij}-G_{i-1,j}-G_{i,j-1}+G_{i-1,j-1},
```

with values below the lower boundary equal to zero. This is the grid's Möbius
inversion. A cumulative sum over the southwest quadrant recovers every grid
value, and the representation extends constantly above the upper boundary.

```@example measure_reconstruction
using MultiparameterPersistence
G = GridInvariant([0.,1.], [0.,2.], [1 2; 3 1])
m = signed_measure(G)
reconstructed = [sum(w for (p,w) in zip(eachcol(m.locations),m.weights)
                     if p[1] <= x && p[2] <= y; init=0.)
                 for x in G.scales, y in G.levels]
@assert reconstructed == G.values
(locations=m.locations, weights=m.weights, reconstruction=reconstructed)
```

Positive atoms record increases; negative atoms record decreases or mixed
changes. The weights are not probabilities and need not sum to one.

## Exact Euler atoms versus sampled homology atoms

There are two different overloads:

| Call | What its atoms encode |
| --- | --- |
| `signed_measure(F::Bifiltration)` | Euler signs at **actual simplex grades**, without grid snapping |
| `signed_measure(G::GridInvariant)` | Mixed differences of the **supplied sampled grid**, such as a Hilbert or Euler surface |

The exact Euler measure assigns each simplex weight `(-1)^dimension`.
Several simplex atoms can occupy the same location; they are not necessarily
merged. Its cumulative sum gives the Euler characteristic at every grade.
The homology Hilbert measure instead requires first choosing a homology dimension
and sampling grid. Do not use these overloads interchangeably.

```@example euler_measure
using MultiparameterPersistence
F = bifiltration([[0.], [1.]], [0.,1.]; dim_max=0)
grid = (scales=[0.,1.], levels=[0.,1.])
exact = signed_measure(F)
H = hilbert_function(F; grid..., dim=0)
homology_measure = signed_measure(H)
E = euler_surface(F; grid...)
quadrants = [sum(w for (p,w) in zip(eachcol(exact.locations),exact.weights)
                if p[1] <= x && p[2] <= y; init=0.)
            for x in E.scales, y in E.levels]
@assert quadrants == E.values
(exact_Euler_weights=exact.weights, Hilbert_weights=homology_measure.weights)
```

They reconstruct the same surface in this simple forest, since no higher
homology exists. That equality is not a general equivalence of Euler and a
single homology dimension.

## Give every measure the same feature coordinates

[`MeasureVectorizer`](@ref) evaluates Gaussian test functions at fixed centers:

```math
\Phi_c(\mu)=\sum_i w_i\exp\!\left(-\frac{\|p_i-c\|^2}{2\sigma^2}\right).
```

The `2×m` center matrix sets the output length `m`; `bandwidth=σ` must be finite
and positive. Every sample uses the same centers and bandwidth, so its feature
positions have a shared meaning. Different axes' units enter the Euclidean
Gaussian distance: choose or learn a scale normalization consistently before
forming grades, and fit learned transformations on training data only.

```@example measure_reconstruction
centers = [0. 1. 0. 1.; 0. 0. 2. 2.]
v = MeasureVectorizer(centers; bandwidth=0.7)
features = v(m)
@assert length(features) == 4
empty_measure = SignedMeasure(zeros(2,0), Float64[])
@assert v(empty_measure) == zeros(4)
features
```

Signed features can be negative. They do not need clipping or renormalization.
A narrower bandwidth resolves local atom locations but can increase sensitivity
to movement; a larger bandwidth smooths more. Select bandwidth through a valid
training/validation procedure.

## What stability is actually bounded?

If atom `i` moves by at most `δ` in Euclidean grade distance while its weight
stays fixed, each feature changes by at most

```math
\operatorname{TV}(\mu)\,\delta/(\sigma\sqrt{e}),
\qquad \operatorname{TV}(\mu)\leq\sum_i|w_i|.
```

This follows from the Gaussian test function's gradient bound. It assumes a
matched-atom comparison with fixed weights; arbitrary insertions/deletions or
weight changes are not included. For the exact Euler measure and **fixed simplex
combinatorics**, the stored absolute-weight sum is the number of simplices,
so that number gives a simple upper bound.

```@example measure_reconstruction
delta = 1e-4
shifted = SignedMeasure(m.locations .+ [delta,0.], m.weights)
bound = sum(abs,m.weights)*delta/(v.bandwidth*sqrt(exp(1)))
@assert maximum(abs.(v(m)-v(shifted))) <= bound + 1e-12
(observed_change=maximum(abs.(v(m)-v(shifted))), bound=bound)
```

Changing a Rips truncation cutoff can change which simplices exist and falls
outside that fixed-combinatorics bound. A grid-derived homology measure also
has different stability conditions: the above formula does not turn it into
an unconditionally interleaving-stable module representation. Raw Hilbert
atoms or Betti arrays are not automatically stable under an unweighted norm.
For the mathematical distinctions between signed summaries, module distances,
and stable comparisons, see [Oudot and Scoccola](https://arxiv.org/abs/2112.11901).

## Optional MLJ adapter: fit once, reuse centers

Load `MLJModelInterface` to activate the extension implementing
[`measure_vectorizer_model`](@ref). Its adapter accepts either a vector of
measures or a Tables.jl table with a `measure` column. `fit` learns a rectangular
center grid from **training atom ranges only**, unless you supply fixed centers.
The requested `resolution=(a,b)` yields `a*b` features when centers are learned.
Constant coordinate ranges are widened by ±0.5; all-empty training measures use
`[-1,1]` in each coordinate. Transformation always reuses the fitted vectorizer.

The following calls the standard model interface directly, so only the small
optional interface dependency is needed:

```@example mlj_adapter
using MultiparameterPersistence, Tables
import MLJModelInterface as MMI
F1 = bifiltration([[0.],[1.]], [0.,1.]; dim_max=0)
F2 = bifiltration([[0.],[1.2]], [0.,0.8]; dim_max=0)
training = [signed_measure(F1), signed_measure(F2)]
model = measure_vectorizer_model(resolution=(3,4), bandwidth=0.7)
fitted, cache, report = MMI.fit(model, 0, training)
training_features = MMI.transform(model, fitted, training)
@assert report.n_features == 12
@assert length(Tables.columnnames(training_features)) == 12
centers_before = copy(fitted.centers)
held_out = [SignedMeasure(training[1].locations .+ 10, training[1].weights)]
held_out_features = MMI.transform(model, fitted, (measure=held_out,))
@assert fitted.centers == centers_before
@assert length(first(values(held_out_features))) == 1
(report=report, column_names=Tables.columnnames(training_features))
```

The result is a Tables-compatible named tuple of columns `measure_1`,
`measure_2`, etc., with one row per input measure. In MLJBase, the same adapter
can be used through `machine`, `fit!`, and `transform`; the umbrella repository's
`examples/p2/multiparameter.jl` demonstrates that path. The optional dependency
has to be installed in your active environment (`Pkg.add("MLJModelInterface")`
or `Pkg.add("MLJBase")`) before loading it.

Keep center fitting **inside each cross-validation training fold**. Fitting
centers from all measures before the split leaks held-out atom ranges. The
transformer learns centers, not a classifier, and does not itself perform
cross-validation or statistical calibration. See the
[MLJModelInterface guide](https://juliaai.github.io/MLJModelInterface.jl/stable/quick_start_guide/)
for the general model-interface convention.
