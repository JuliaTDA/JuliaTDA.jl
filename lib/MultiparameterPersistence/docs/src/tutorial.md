# A function-Rips tutorial

```@meta
CurrentModule = MultiparameterPersistence
```

## One square and one questionable observation

Imagine four reliable observations at a square's corners and a fifth observation
far away. Give the square vertices function value 0 and the remote point value
2. At level 0, the remote point is excluded regardless of the Rips scale; at
level 2 it is admitted. The values could represent an externally supplied
outlier score. This package receives them; it does not estimate that score.

```@example function_rips
using MultiparameterPersistence, Tables
points = [[0.,0.], [1.,0.], [1.,1.], [0.,1.], [4.,4.]]
values = [0.,0.,0.,0.,2.]
F = bifiltration(points, values; dim_max=1)
grid = (scales=[0.,1.,sqrt(2),6.], levels=[0.,2.])
H0 = hilbert_function(F; grid..., dim=0)
H1 = hilbert_function(F; grid..., dim=1)
@assert H1.values[:,1] == [0,1,0,0]
@assert H0.values[1,:] == [4,5]
(H0=H0.values, H1=H1.values)
```

Rows correspond to **scales** and columns to **levels**. At `(0,0)` there are
four isolated vertices; at `(0,2)` there are five. At `(1,0)` the square is
connected with one loop. At `(√2,0)` the triangles fill the loop. At scale 6
all five points are connected when level 2 admits them.

`bifiltration` accepts a vector of equally sized coordinate vectors or a matrix
with **points in columns**. Distances are Euclidean and the scale is the actual
edge-length threshold, with no factor of two. Negative function levels are
valid; they may express any increasing sublevel filtration. To express high
values entering first, supply a transformed value such as `-score` and label
that axis accordingly.

## Inspect the constructed complex

```@example function_rips
@assert length(F.simplices) == length(F.grades)
length(F.simplices), collect(zip(F.simplices, F.grades))[1:5]
```

Vertex labels are one-based positive integers. A vertex has scale grade 0 and
its supplied function value. An edge's grade uses its length and the larger
endpoint value; higher simplices use their maximum pairwise distance and maximum
vertex value. The constructor includes simplices through dimension
`dim_max+1`: H₁ needs triangles for loop deaths, so `dim_max=1` constructs
vertices, edges, and triangles.

This last detail matters for Euler surfaces. They describe the complex **actually
constructed**, including the extra chain dimension, rather than a hypothetical
full simplex at large scale. At level 0 and scale √2 the four-vertex triangle
complex is the boundary of a tetrahedron. Its H₁ is zero but its H₂ is one.
If you need that cavity's death, request `dim_max=2` so the tetrahedron is included.

```@example function_rips
E = euler_surface(F; grid...)
@assert E.values[3,1] == 2
fuller = bifiltration(points, values; dim_max=2)
@assert euler_surface(fuller; grid...).values[3,1] == 1
(Euler_of_triangle_complex=E.values[3,1],
 Euler_with_tetrahedra=euler_surface(fuller; grid...).values[3,1])
```

## Read or export a grid as a table

All grid invariants implement the Tables.jl column interface. Exporting a table
preserves the coordinates attached to every value, so it avoids accidentally
transposing a heatmap or flattening rows in the wrong order.

```@example function_rips
table = Tables.columntable(H1)
@assert length(table.value) == length(grid.scales)*length(grid.levels)
table
```

The columns are `scale`, `level`, and `value`. Within the flattened output,
scale varies first, following Julia's column-major `vec(H1.values)` order.
A plotting library can use `H1.scales`, `H1.levels`, and the explicitly oriented
`H1.values`; confirm its heatmap orientation rather than inferring it from shape.

## A custom bifiltration

You can supply a graded simplicial complex directly. Every simplex needs all
of its faces, with componentwise earlier or equal grades. Vertex labels are
sorted by the constructor; duplicate simplices and repeated vertices are rejected.

```@example custom_complex
using MultiparameterPersistence
F = Bifiltration([(1,), (2,), (1,2)], [(0.,0.), (0.,1.), (1.,1.)])
H = hilbert_function(F; scales=[0.,1.], levels=[0.,1.], dim=0)
@assert H.values == [1 2; 1 1]
H.values
```

The second vertex needs level 1, while the connecting edge needs both scale 1
and level 1. This two-point example will make [generators and relations](invariants.md)
concrete.
