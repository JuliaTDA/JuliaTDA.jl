# julia scripts/setup.jl [--local] [environment_directory]
include("ecosystem.jl")
args = filter(!=("--local"), ARGS)
length(args) <= 1 || error("Usage: julia scripts/setup.jl [--local] [environment_directory]")
any(startswith(arg, "--") for arg in args) && error("Unknown setup option")
environment = isempty(args) ? EcosystemSetup.ROOT : abspath(only(args))
EcosystemSetup.setup(environment; local_checkouts="--local" in ARGS)
