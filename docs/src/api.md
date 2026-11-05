# Geometry, Mapper and visualization API

These docstrings belong to the constituent packages and are available through
`using JuliaTDA`. For diagrams, statistical inference, multiparameter invariants
and optional PH workflows, see [Homology and inference API](api_analysis.md).
Each owning package has a more extensive API reference.

## Metric spaces & filters (MetricSpaces.jl)

```@docs
MetricSpaces.EuclideanSpace
MetricSpaces.eccentricity
MetricSpaces.dtm_density
MetricSpaces.kde
```

## Mapper & Tables.jl (TDAmapper.jl)

```@docs
TDAmapper.euclidean_space
TDAmapper.node_statistics
```

## Plotting (TDAplots.jl)

```@docs
TDAplots.metricspace_plot
TDAplots.mapper_plot
TDAplots.MapperExplorer
TDAplots.node_colors
TDAplots.mapper_explorer
TDAplots.tomato_persistence_plot
TDAplots.tomato_graph_plot
```

## Clustering (ToMATo.jl)

```@docs
ToMATo.proximity_graph
ToMATo.tomato
```

## Euler descriptors and image filtrations

```@docs
MetricSpaces.cubical_ecc
MetricSpaces.ect
MetricSpaces.sect
MetricSpaces.sample_directions
MetricSpaces.euler_table
MetricSpaces.ImageFiltration
MetricSpaces.euclidean_distance_transform
MetricSpaces.height_filtration
MetricSpaces.radial_filtration
MetricSpaces.dilation_filtration
MetricSpaces.erosion_filtration
MetricSpaces.signed_distance_filtration
MetricSpaces.image_filtration_model
```

## Nonlinear Mapper filters

```@docs
TDAmapper.MLPFilter
TDAmapper.initial_parameters
TDAmapper.flux_filter
TDAmapper.lux_filter
TDAmapper.optimize_filter
TDAmapper.total_extended_persistence
TDAmapper.total_persistence
```
