# Run once from any working directory: julia --startup-file=no scripts/setup.jl
using Pkg
project = dirname(@__DIR__)
workspace = abspath(project, "../../..")
lockfile = joinpath(project,"environment.lock.toml")
manifest = joinpath(project,"Manifest.toml")
if !isfile(manifest) && isfile(lockfile)
    cp(lockfile,manifest)
end
Pkg.activate(project)
packages = ("MetricSpaces", "TDAmapper", "TDAPersistenceDiagrams", "TDARipserer",
            "TDAplots", "ToMATo", "JuliaTDA")
specs = [PackageSpec(path=joinpath(workspace, name * ".jl")) for name in packages]
all(isdir(spec.path) for spec in specs) || error("Expected the JuliaTDA sibling checkouts in $workspace")
Pkg.develop(specs; preserve=Pkg.PRESERVE_ALL)
Pkg.instantiate()
