# Fast persistence and adaptive Mapper

## Point clouds

Set `radius_graph=true` with an explicit threshold to build the Euclidean
radius graph directly. This is most useful when the threshold leaves relatively
few edges. Set `radius_graph=:auto` to sample neighbour counts before
choosing a construction. The graph contains all pairs that pass the threshold under pointwise
distance evaluation. Floating-point rounding can differ from the pairwise matrix
path at the threshold.

```@example fast_persistence
using JuliaTDA

points = [(cos(t), sin(t)) for t in range(0, 2π; length=61)[1:60]]
diagrams = ripserer(points; threshold=0.2, radius_graph=true)
selected = ripserer(points; threshold=0.2, radius_graph=:auto)
@assert length(diagrams[2]) == length(selected[2])
diagrams[2]
```

Use `alg=:redzed` for dense, finite, unweighted Float32 or Float64 Rips distances
over F₂. RedZeD returns birth and death simplex metadata. Use the default
cohomology engine for cocycles or other coefficient fields.

```@example fast_persistence
redzed = ripserer(points; alg=:redzed)
only(redzed[2])
```

Launch Julia with multiple threads to try `alg=:parallel_cohomology` for
implicit Rips H₂ or H₃. This experimental backend finds apparent pairs in
parallel and performs pivot reduction serially. Its speed depends on how
many pairs can be cleared before reduction.

```@example fast_persistence
parallel = ripserer(points; dim_max=2, threshold=0.8, alg=:parallel_cohomology)
@assert parallel == ripserer(points; dim_max=2, threshold=0.8)
```

## Cubical images and volumes

`alg=:cubical_union_find` uses the vertex lower-star convention. A 2D image
uses primal union-find for connected components and dual union-find for holes.
For 3D volumes, dual union-find handles cavities, and the existing cohomology
engine computes tunnels when requested. The exterior of the grid is part of the
dual graph. A feature whose death is past the filtration threshold reports
infinite death.

```@example fast_persistence
volume = zeros(Int, 3, 3, 3)
volume[2, 2, 2] = 1
ripserer(Cubical, volume; dim_max=2, alg=:cubical_union_find)[3]
```

## Compatible zigzag cycles

Set `reps=true` when creating a zigzag stream or passing an event sequence.
The representative attached to each interval can be indexed by an observed
state. Its simplices are the nonzero terms of an F₂ cycle. Neighboring cycles
along the bar represent the same homology class under the corresponding inclusion.

```@example fast_persistence
initial = [(1, 2), (2, 3), (1, 3)]
stream = ZigzagPersistence(; initial, reps=true)
push!(stream, :add => (1, 2, 3))
cycle = representative(only(zigzag_diagrams(stream)[2]))
cycle[0]
```

## Persistence-guided Mapper covers

AdaMapper uses finite Rips H₁ bars to select regions where the lens cover needs
more resolution. Load both TDAmapper and TDARipserer when using their standalone
packages. The JuliaTDA umbrella loads the extension automatically.

```@example fast_persistence
X = EuclideanSpace(collect.(points))
adaptive = ada_mapper(X; return_details=true)
(adaptive.critical_ranges, adaptive.mapper)
```
