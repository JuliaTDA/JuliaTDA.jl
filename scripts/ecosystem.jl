module EcosystemSetup
using Pkg

const ROOT = dirname(@__DIR__)
const SOURCES = [
    "MetricSpaces" => "MetricSpaces.jl",
    "TDAmapper" => "TDAmapper.jl",
    "TDAplots" => "TDAplots.jl",
    "ToMATo" => "ToMATo.jl",
    "TDARipserer" => "Ripserer.jl",
    "TDAPersistenceDiagrams" => "PersistenceDiagrams.jl",
    "PersistenceInference" => "PersistenceInference.jl",
]

"""Resolve one environment, using public sources or explicitly selected sibling checkouts."""
function setup(environment=ROOT; local_checkouts=false)
    specs = if local_checkouts
        paths = [joinpath(dirname(ROOT), name * ".jl") for (name, _) in SOURCES]
        missing_paths = filter(p -> !isfile(joinpath(p, "Project.toml")), paths)
        isempty(missing_paths) || error("Missing package checkouts: " * join(missing_paths, ", "))
        [PackageSpec(path=p) for p in paths]
    else
        [PackageSpec(url="https://github.com/JuliaTDA/" * repo) for (_, repo) in SOURCES]
    end
    push!(specs, PackageSpec(path=joinpath(ROOT, "lib", "MultiparameterPersistence")))
    # Include the umbrella in the same transaction for docs and fresh analysis envs.
    abspath(environment) == ROOT || push!(specs, PackageSpec(path=ROOT))
    Pkg.activate(environment)
    # Keep public clones in this environment's dev/ directory rather than
    # silently reusing unrelated, possibly modified ~/.julia/dev checkouts.
    Pkg.develop(specs; shared=false)
    Pkg.instantiate()
end

end
