# Changelog

Notable changes to JuliaTDA are recorded here.

## Unreleased

- Consolidate the P1–P3 umbrella integrations, runnable examples, numerical
  reproduction assets, documentation and bundled MultiparameterPersistence.
- Re-export PersistenceInference, finite-grid confidence bands, multiplier
  bootstrap, maximum-persistence significance and HSIC tests.
- Expose witness complexes, zigzag persistence, vineyards, diagram means and
  scale-space/weighted Gaussian kernels through the umbrella package.
- Add the nested-CV MLJ tuning example, P2 workflows and integration tests.
- Centralize setup for the package, docs and examples. Public Git sources are
  the default; `--local` explicitly selects sibling checkouts.
- Add cross-package smoke pipelines including rendered Mapper and PH figures
  to CI, alongside Julia 1.10 and current stable checks.
- Link to the standalone MapperStudio application. The original integrated
  copy under `apps/MapperStudio` is retained as a historical snapshot.
- Keep registration, release tags and publication deferred.

## Independent JuliaTDA forks — 3 October 2026

- Switch persistence dependencies and imports to TDARipserer and
  TDAPersistenceDiagrams, with independent UUIDs and version series.
