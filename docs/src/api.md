# API reference

This page collects the docstrings of the symbols used throughout the examples.
They originate in the constituent packages but are all re-exported by
`using JuliaTDA`. See each package's own documentation for the complete API.

## Metric spaces & filters (MetricSpaces.jl)

```@docs
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
TDAplots.mapper_explorer
TDAplots.tomato_persistence_plot
TDAplots.tomato_graph_plot
```

## Diagram vectorizations (TDAPersistenceDiagrams.jl)

```@docs
TDAPersistenceDiagrams.Landscape
TDAPersistenceDiagrams.BettiCurve
TDAPersistenceDiagrams.PersistenceImage
```

## Clustering (ToMATo.jl)

```@docs
ToMATo.proximity_graph
ToMATo.tomato
```
