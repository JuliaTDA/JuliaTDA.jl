# Understanding the invariants

```@meta
CurrentModule = MultiparameterPersistence
```

## A homology count is a Hilbert function

For a bifiltration `F`, fix a homology degree `d`. Its persistence module assigns
an F₂ vector space ``H_d(F_{r,a})`` to each grade and a linear inclusion map to
each comparable pair of grades. [`hilbert_function`](@ref) records only the
vector-space dimensions, sampled at the supplied grid.

```@example two_points
using MultiparameterPersistence
F = bifiltration([[0.], [1.]], [0.,1.]; dim_max=0)
grid = (scales=[0.,1.], levels=[0.,1.])
H = hilbert_function(F; grid..., dim=0)
@assert H.values == [1 2; 1 1]
H.values
```

The first row has one component at level 0 and two at level 1. The second row
has one component at either level because the edge joins the vertices when
both are admitted. These are ordinary **topological Betti counts** at individual
grades. The Hilbert function is a useful summary, but two modules can have the
same dimensions and different maps; it is not a complete multiparameter invariant.

## Bigraded Betti numbers describe the module

The word “Betti” also names the ranks in a minimal free resolution of the
sampled persistence module. For two parameters the package computes three arrays:

| Array | Role | Question it answers |
| --- | --- | --- |
| `beta0` | Generators | How many module classes are newly needed at this grade? |
| `beta1` | Relations | How many independent relations among generators are needed? |
| `beta2` | Syzygies | How many dependencies among relations are needed? |

The `dim` keyword selects the **homology degree of the module**. In
`bigraded_betti(F; dim=1)`, all three arrays describe the H₁ module. `beta2`
is not an H₂ count, and `beta0` is not the number of connected components.

```@example two_points
B = bigraded_betti(F; grid..., dim=0)
@assert B.beta0.values == [1 1; 0 0]
@assert B.beta1.values == [0 0; 0 1]
@assert all(iszero, B.beta2.values)
(generators=B.beta0.values, relations=B.beta1.values, syzygies=B.beta2.values)
```

There is one generator at `(0,0)` and another at `(0,1)`. At `(1,1)` the edge
identifies their components, giving a relation. One component remains forever
in the representation; no artificial relation is inserted above the final scale.

### The computation uses maps, not just differences

At a grid position `(i,j)`, the Koszul complex is

```math
M_{i-1,j-1} \longrightarrow M_{i-1,j}\oplus M_{i,j-1}
\longrightarrow M_{i,j}.
```

The arrows are induced homology inclusion maps. Their kernels and images give
`beta2`, `beta1`, and `beta0`, respectively. Outside the lower grid boundary,
`M=0`. Calculations use exact Boolean elimination/XOR over F₂, not floating-point
SVD or rank tolerances. This is the Koszul-homology viewpoint covered in
[Lesnick's multiparameter notes](https://mlesnick.github.io/840_2022/Math840_Notes_22.pdf).

The alternating Betti array has a cumulative identity:

```@example two_points
alternating = B.beta0.values - B.beta1.values + B.beta2.values
reconstructed = cumsum(cumsum(alternating; dims=1); dims=2)
@assert reconstructed == H.values
reconstructed
```

That identity does not determine each Betti array separately: generators and
relations can cancel in the alternating sum. Taking mixed finite differences
of `H.values` therefore cannot replace the inclusion-map calculation.

## A genuine relation between relations

Here two groups of triangles fill the same boundary through different parameter
directions. All edges are present at `(0,0)`. One group of triangles enters at
`(1,0)`, the other at `(0,1)`. At `(1,1)` one dependency among their relations
appears. This small example is also checked in the package's existing tests.

```@example two_disks
using MultiparameterPersistence
simplices = Tuple{Vararg{Int}}[(i,) for i in 1:5]
append!(simplices, [(1,2),(2,3),(1,3),
                   (1,4),(2,4),(3,4),(1,5),(2,5),(3,5)])
grades = fill((0.,0.), length(simplices))
append!(simplices, [(1,2,4),(2,3,4),(1,3,4),
                   (1,2,5),(2,3,5),(1,3,5)])
append!(grades, [(1.,0.),(1.,0.),(1.,0.),(0.,1.),(0.,1.),(0.,1.)])
F = Bifiltration(simplices, grades)
grid = (scales=[0.,1.], levels=[0.,1.])
H = hilbert_function(F; grid..., dim=1)
B = bigraded_betti(F; grid..., dim=1)
@assert H.values == [5 2; 2 0]
@assert B.beta0.values == [5 0; 0 0]
@assert B.beta1.values == [0 3; 3 0]
@assert B.beta2.values == [0 0; 0 1]
@assert cumsum(cumsum(B.beta0.values-B.beta1.values+B.beta2.values;
                     dims=1); dims=2) == H.values
(H1=H.values, beta2=B.beta2.values)
```

The five initial graph cycles acquire three relations along each axis. Together
those six relations have one dependency. Here the fully assembled complex also
has an H₂ class, but `B.beta2` was computed from the H₁ **module maps**, not by
calling H₂ homology; that distinction remains essential in other examples.

## Euler surfaces describe the constructed complex

[`euler_surface`](@ref) sums `+1` for vertices, `-1` for edges, `+1` for triangles,
and so on at each grade. For a finite complex it equals the alternating sum of
homology dimensions **over all dimensions of that complex**.

```@example two_disks
H0 = hilbert_function(F; grid..., dim=0)
H2 = hilbert_function(F; grid..., dim=2)
E = euler_surface(F; grid...)
@assert E.values == H0.values - H.values + H2.values
E.values
```

Do not compare an Euler surface to `H0-H1` if the constructed complex can have
higher-dimensional homology. Rips dimension truncation may introduce such
classes; the [function-Rips tutorial](tutorial.md) shows the square/tetrahedron
example. The Euler surface counts the actual simplices and does not require
homology reduction.

## Your axes define the sampled module

All grid APIs require finite, nonempty, strictly increasing axes. The same
rectangular grid should be used for comparisons. Values below the first grid
coordinate are treated as zero in the discretized module; above the upper
boundary the representation extends constantly. Features born before the first
sample can therefore be assigned generators at that lower boundary, and features
that die after the last sample remain unresolved in the grid representation.

For a faithful representation of this finite graded complex, include all
relevant unique simplex scale and level grades:

```@example two_points
critical_grid = (scales=sort(unique(first.(F.grades))),
                 levels=sort(unique(last.(F.grades))))
critical_grid
```

For the two-point complex, these are the vertex-birth and connection grades.
A coarse grid is still a valid **sampled** module,
but it can miss a loop that appears and dies between adjacent scales. Refining
a grid changes the module being measured; raw arrays from different axes should
not be compared entrywise.
