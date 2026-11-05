using Documenter
using MultiparameterPersistence

DocMeta.setdocmeta!(MultiparameterPersistence, :DocTestSetup,
    :(using MultiparameterPersistence); recursive=true)

makedocs(;
    modules=[MultiparameterPersistence],
    sitename="MultiparameterPersistence.jl",
    authors="G. Vituri and contributors",
    remotes=nothing,
    format=Documenter.HTML(; prettyurls=get(ENV, "CI", "false") == "true",
        edit_link=nothing, repolink="https://github.com/JuliaTDA/JuliaTDA.jl"),
    pages=[
        "Home" => "index.md",
        "Function-Rips tutorial" => "tutorial.md",
        "Understanding the invariants" => "invariants.md",
        "Signed measures and MLJ" => "measures.md",
        "Limits and reproducibility" => "practical.md",
        "API reference" => "api.md",
    ],
)
