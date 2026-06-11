using Documenter
using JuliaTDA

# The constituent packages own the docstrings we surface on the API page; we
# reach them through JuliaTDA's re-exports.
using JuliaTDA: MetricSpaces, TDAmapper, TDAplots, PersistenceDiagrams, ToMATo

# CairoMakie is loaded so the @example blocks in the example pages can render
# static figures into the build.
using CairoMakie

DocMeta.setdocmeta!(JuliaTDA, :DocTestSetup, :(using JuliaTDA); recursive = true)

makedocs(;
    # Include the constituent modules so Documenter accepts the docstrings that
    # the API page surfaces from them (they are re-exported by JuliaTDA).
    modules = [JuliaTDA, MetricSpaces, TDAmapper, TDAplots,
               PersistenceDiagrams, ToMATo],
    sitename = "JuliaTDA.jl",
    authors = "G. Vituri and contributors",
    # The constituent packages are `develop`ed from local checkouts / forks, so
    # Documenter cannot infer their `Remotes`. `remotes = nothing` disables the
    # source-URL machinery (we are not generating @docs/@autodocs for them) and
    # keeps the build green; `checkdocs = :none` likewise avoids cross-package
    # docstring-coverage failures for re-exported symbols.
    remotes = nothing,
    checkdocs = :none,
    # We surface docstrings from the constituent packages on the API page, but
    # we do not own their embedded jldoctests (they rely on their own
    # DocTestSetup). Skip doctesting here; the example pages use executed
    # `@example` blocks instead.
    doctest = false,
    # The surfaced docstrings contain `@ref`s to *other* symbols of their home
    # packages that we do not republish here (e.g. `PersistenceCurve`,
    # `EuclideanSpace`). Those would otherwise abort the build; demote the
    # unresolved-reference and docs-block diagnostics to warnings so the site
    # still renders. (The full per-package API lives in each package's own
    # docs.)
    warnonly = [:cross_references, :docs_block],
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://JuliaTDA.github.io/JuliaTDA.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Examples" => [
            "Mapper exploration" => "examples/mapper_exploration.md",
            "Persistent homology for ML" => "examples/ph_for_ml.md",
            "ToMATo clustering" => "examples/tomato_clustering.md",
        ],
        "API reference" => "api.md",
    ],
)

deploydocs(;
    repo = "github.com/JuliaTDA/JuliaTDA.jl",
    devbranch = "main",
)
