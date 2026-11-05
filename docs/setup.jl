# julia docs/setup.jl [--local]
include(joinpath(@__DIR__, "..", "scripts", "ecosystem.jl"))
all(==("--local"), ARGS) || error("Usage: julia docs/setup.jl [--local]")
EcosystemSetup.setup(@__DIR__; local_checkouts="--local" in ARGS)
