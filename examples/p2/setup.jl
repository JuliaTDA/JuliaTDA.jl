# julia examples/p2/setup.jl [--local]
include(joinpath(@__DIR__, "..", "..", "scripts", "ecosystem.jl"))
all(==("--local"), ARGS) || error("Usage: julia examples/p2/setup.jl [--local]")
EcosystemSetup.setup(@__DIR__; local_checkouts="--local" in ARGS)
