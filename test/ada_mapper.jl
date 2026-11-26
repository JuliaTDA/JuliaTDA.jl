@testset "Persistence-guided Mapper through the umbrella" begin
    G = JuliaTDA.TDAmapper.Graphs
    cycle_rank(g) = G.ne(g) - G.nv(g) + length(G.connected_components(g))
    circle = EuclideanSpace([[cos(t), sin(t)] for t in range(0, 2π; length=61)[1:60]])
    refiner = DBscan(radius=0.17)
    adaptive = ada_mapper(circle; refiner, return_details=true)
    coarse = classical_mapper(circle, R1Cover(adaptive.lens, Uniform(length=2, expansion=0.2)),
        refiner)
    @test length(adaptive.critical_ranges) == 1
    @test any(isfinite, adaptive.diagram)
    @test cycle_rank(adaptive.mapper.g) == 1
    @test cycle_rank(coarse.g) == 0
    @test all(x -> any(i -> x in i, adaptive.intervals), adaptive.lens)
    @test ada_mapper(circle; refiner).C == adaptive.mapper.C

    branches = EuclideanSpace(vcat(
        [[x, 0.0] for x in -1:0.05:0],
        [[x, x] for x in 0.05:0.05:1],
        [[x, -x] for x in 0.05:0.05:1],
    ))
    lens = first.(branches)
    result = ada_mapper(branches; lens, refiner, return_details=true)
    fixed = classical_mapper(branches, R1Cover(lens, Uniform(length=10, expansion=0.2)), refiner)
    @test isempty(result.critical_ranges)
    @test result.mapper.C == fixed.C
    @test cycle_rank(result.mapper.g) == cycle_rank(fixed.g)
    @test isempty(ada_mapper(circle; min_relative_persistence=1, return_details=true).critical_ranges)
    @test length(ada_mapper(circle; lens=ones(length(circle)), return_details=true).intervals) == 1
    @test_throws ArgumentError ada_mapper(circle; lens=[1.0])
    @test_throws ArgumentError ada_mapper(circle; k=length(circle))
end
