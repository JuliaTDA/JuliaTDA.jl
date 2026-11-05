using JuliaTDA
using Test

@testset "P3 algorithms through JuliaTDA" begin
    ds = [PersistenceDiagram([(0.0, 2.0)]), PersistenceDiagram([(0.0, 4.0)])]
    @test frechet_mean(ds).converged
    @test frechet_variance(ds) ≈ 1
    @test size(kernel_matrix(PersistenceScaleSpaceKernel(), ds)) == (2, 2)
    @test PersistenceWeightedGaussianKernel(; bandwidth=1)(ds[1], ds[1]) ≈ 1
    @test length(zigzag_persistence([:add => (1,), :remove => (1,)]; dim_max=0)[1]) == 1
    v = Vineyard([(1, 2) => 1.0])
    update_vineyard!(v, Dict((1, 2) => 2.0))
    @test death(first(filter(isfinite, vineyard_diagrams(v)[1]))) == 2
    points = [[cos(t), sin(t)] for t in range(0, 2π; length=65)[1:64]]
    @test !isempty(ripserer(LazyWitness(points, [1, 17, 33, 49]))[2])
end
