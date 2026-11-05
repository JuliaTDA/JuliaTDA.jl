using Pkg
const APP_ROOT = realpath(joinpath(@__DIR__, ".."))
const UMBRELLA_ROOT = realpath(joinpath(APP_ROOT, "..", ".."))
const ECOSYSTEM_ROOT = dirname(UMBRELLA_ROOT)
Pkg.activate(APP_ROOT)
paths = [joinpath(ECOSYSTEM_ROOT, p) for p in
    ("MetricSpaces.jl", "TDAmapper.jl", "TDAPersistenceDiagrams.jl", "TDARipserer.jl", "ToMATo.jl")]
push!(paths, joinpath(UMBRELLA_ROOT, "lib", "MultiparameterPersistence"))
Pkg.develop([PackageSpec(path=p) for p in paths])
Pkg.instantiate()
Pkg.precompile(; strict=true)
println("\nReady: julia --project=$(APP_ROOT) --threads=auto $(joinpath(APP_ROOT, "scripts", "serve.jl"))")
