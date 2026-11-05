# API reference

```@meta
CurrentModule = MultiparameterPersistence
```

Grid invariant values use `values[scale_index, level_index]`. `dim` always selects
the topological homology degree; the three outputs of `bigraded_betti` then
refer to free-resolution degrees of that module. Atom and center locations use
columns of a two-row matrix. See the tutorials for executable examples and
[Limits and reproducibility](practical.md) for computation guards.

```@index
```

```@autodocs
Modules = [MultiparameterPersistence]
```
