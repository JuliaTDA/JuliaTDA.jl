# Reading topological results

Topology describes connectivity and holes. A finite sample does not arrive
with a unique topology: we choose a distance, neighborhood construction and
scale convention first. These choices express the scientific question.

## Four objects that should stay distinct

| Object | What it records | Typical JuliaTDA representation |
|---|---|---|
| Point cloud | Original observations and geometry | `EuclideanSpace`, vector of points |
| Simplicial or cubical complex | Cells and how their boundaries attach | Rips, cubical or custom filtration |
| Persistence diagram | Birth/death intervals of homology classes | `PersistenceDiagram` |
| Mapper graph | Overlap between clusters in a chosen cover | `M.g` together with `M.C` and `M.X` |

The same point cloud can produce all four. A loop in a Mapper graph and an
`H₁` persistence interval are outcomes of different constructions and need
not agree. A graph also has its own cycles: they should not be confused with
cycles of the cloud's Rips complex.

## A square explains a filtration

Take the four vertices of a unit square. At Rips distance `0`, they are four
components. At distance `1`, its side edges appear and form a loop. At distance
`√2`, the diagonals and triangles appear, filling that loop. Its ideal `H₁`
interval is `(1, √2)`.

```@example square_concepts
using JuliaTDA
square = [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]]
square_diagrams = ripserer(square; dim_max = 1)
[(birth(interval), death(interval)) for interval in square_diagrams[2]]
```

In a Rips filtration, a simplex enters when all its edges do; the scale is the
largest pairwise distance. It is not the radius of a drawn disk. Other
filtrations use other axes: intensity in a grayscale image, directional height
for an Euler transform, or a scalar measurement on vertices. Always label the
axis with the actual quantity and units.

An `H₀` class often survives forever because the final complex stays connected.
With a finite computation threshold, a class with infinite death can also be
**right-censored**: its death may occur beyond the observed range. Check the
filtration and threshold before calling it a permanent hole. Vectorizations
and distances have their own policies for essential intervals; use compatible
policies across all samples.

## Why persistence is useful, and what it does not guarantee

Persistence organizes features by lifetime. Under appropriate assumptions,
small perturbations of a filtration lead to small changes in its diagram.
This motivates sensitivity checks. It does not select a correct distance,
guarantee recovery from sparse sampling, or calibrate a statistical test.

A long interval may reflect a real cycle, a geometric outlier, anisotropic
units, or preprocessing choices. Compare multiple samples or plausible null
models, not only one attractive plot. Diagram distances also differ: a
bottleneck distance emphasizes the worst matched discrepancy, while a
Wasserstein distance aggregates discrepancies with its chosen exponent.

## Mapper: cover, cluster, connect

A Mapper construction has three stages:

1. Cover the range of a filter with overlapping sets and pull them back to
   observations. A filter can be a coordinate, density, eccentricity, or a
   learned measurement.
2. Split each pulled-back set into clusters using distances in the original
   space. Two separated arcs of a circle at the same x-coordinate should be
   distinct clusters when the radius permits it.
3. Connect resulting clusters that share observations, or use the explicitly
   chosen alternative nerve rule.

Filter values guide the cover; they need not be the metric used for clustering.
More cover intervals resolve finer filter changes but can make the result
fragmented. More overlap can add connections. A larger clustering radius can
merge separated structures. Vary these settings together, keeping the data
representation and metric fixed when comparing outcomes.

Ball Mapper instead covers the original metric space with balls around
landmarks. Its parameters have distance units. With an insufficient radius,
some observations may have no membership. With too much overlap, a dense
graph can obscure structure. Inspect membership and coverage explicitly.

## Density modes are another kind of topology

ToMATo follows density peaks on a proximity graph and merges shallow peaks
into deeper ones. Its merge threshold is in **density units**, not geometric
distance units. Replacing the density estimator or changing its bandwidth
changes that scale, so the same numerical threshold cannot be assumed to
mean the same thing.

The graph determines which modes can meet. Disconnected graph components
cannot merge, regardless of a large threshold. Essential surviving peaks use
the package's `death = Inf` sentinel; it does not mean an infinitely large
density drop. See the ToMATo package's interpretation guide for the exact
merge inequality and handling of tied densities.

## Two parameters do not produce one barcode

A function-Rips bifiltration asks for both a distance scale and a vertex
measurement cutoff. An inclusion is possible when **both coordinates
increase**. Such a partially ordered family generally has no ordinary barcode
that contains all its information.

The bundled MultiparameterPersistence package supplies useful summaries for
small complexes: a Hilbert function counts homology at each grade; grid Koszul
Betti numbers record generators, relations and syzygies of the sampled module;
an Euler surface is an alternating cell or homology count. These quantities
are related but are not interchangeable. A signed Euler measure can cancel
contributions, so a zero measure need not describe an empty complex.

A finite grid is part of the model. Missing critical grades loses information.
Stability statements for smooth signed-measure features require their stated
matching and fixed-combinatorics assumptions; they do not make raw grid Betti
numbers universally stable.

## What counts as an observation in inference?

A point cloud has observations *within* a shape. A collection of diagrams has
one observation *per* sampled shape. Resampling points from one cloud,
constructing a mean landscape band across independent diagrams, and permuting
paired diagram labels address different sampling models.

Overlapping time windows, repeated measurements of the same subject, and
multiple nodes containing the same point introduce dependence. A function
accepting these arrays does not make an independence assumption true. Define
the experimental unit and exchangeability scheme before selecting a method.
