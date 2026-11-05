# Run in an environment with JuliaTDA and the optional CairoMakie backend.
using JuliaTDA, CairoMakie, Test
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners

@testset "Ecosystem smoke pipelines" begin
    points = EuclideanSpace([[cos(t), sin(t)] for t in range(0, 2π; length=49)[1:48]])
    model = classical_mapper(points, R1Cover(first.(points), Uniform(length=6)), DBscan(radius=0.3))
    @test !isempty(model.C)
    diagrams = ripserer(points)
    @test maximum(persistence, diagrams[2]) > 1
    @test length(Landscape(2, 0.0, 2.0; length=10)(diagrams[2])) == 10
    @test max_persistence_significance(diagrams[2], fill(0.1, 99)).pvalue == 0.01
    density = JuliaTDA.ToMATo.knn_density(points; k=5)
    labels, _ = tomato(points, proximity_graph(points, 0.3), density, 0.1)
    @test length(labels) == length(points)
    mktempdir() do dir
        for (name, figure) in (("mapper", mapper_plot(model)),
                               ("persistence", persistence_plot(diagrams)))
            path = joinpath(dir, name * ".png")
            save(path, figure)
            @test filesize(path) > 1000
        end
    end
end
