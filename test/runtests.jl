using JuliaTDA
# Submodules carrying the Mapper building blocks (covers, refiners, nerves)
# travel up the re-export chain and are exported by JuliaTDA, but their
# *contents* (R1Cover, Uniform, DBscan, SimpleNerve, …) must be brought in
# explicitly, exactly as an umbrella user would.
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners, JuliaTDA.Nerves
using Statistics: mean, std
using Test

# Datasets live in a submodule of MetricSpaces. Access is via qualification;
# we alias it here for brevity. (Doing `using ...Datasets: name` is avoided on
# purpose: it would drag Graphs' exports into the test scope and re-introduce
# the `eccentricity`/`center` ambiguity that JuliaTDA disambiguates.)
const DS = JuliaTDA.MetricSpaces.Datasets

@testset "JuliaTDA.jl" begin

    @testset "package loads and re-exports resolve" begin
        # Every name JuliaTDA exports must actually resolve (no leftover
        # export-ambiguity from the re-export chain, e.g. eccentricity/center
        # vs Graphs).
        bad = Symbol[]
        for n in names(JuliaTDA)
            n === :JuliaTDA && continue
            try
                getproperty(JuliaTDA, n)
            catch
                push!(bad, n)
            end
        end
        @test isempty(bad)
    end

    @testset "MetricSpaces foundation + Datasets" begin
        X = DS.sphere(60)
        @test X isa EuclideanSpace
        @test length(X) == 60
        # `Datasets` itself is a submodule; we only require qualified access.
        @test isdefined(JuliaTDA.MetricSpaces, :Datasets)
        @test DS.torus isa Function
    end

    @testset "filters: per-point eccentricity, dtm_density, kde" begin
        X = DS.sphere(60)
        ecc = eccentricity(X)              # per-point (single-argument) form
        @test ecc isa AbstractVector
        @test length(ecc) == length(X)
        @test all(isfinite, ecc)
        @test length(dtm_density(X; k = 8)) == length(X)
        @test length(kde(X)) == length(X)
    end

    @testset "Mapper: classical_mapper, mapper, ball_mapper" begin
        X = DS.sphere(60)
        f = eccentricity(X)
        C = R1Cover(f, Uniform(length = 8, expansion = 0.3))
        M = classical_mapper(X, C, DBscan(), SimpleNerve())
        @test M isa Mapper
        @test length(M.C) ≥ 1
        @test mapper isa Function
        Mb = ball_mapper(X, collect(1:5:60), 0.5)
        @test Mb isa Mapper
    end

    @testset "Tables.jl extension loaded (euclidean_space + node_statistics)" begin
        n = 50
        # A NamedTuple is a Tables.jl-compatible source; if the extension did
        # not load, these calls would hit the un-implemented stub and error.
        tbl = (x = randn(n), y = randn(n), z = randn(n),
               label = rand(["a", "b"], n))
        X = euclidean_space(tbl; cols = (:x, :y, :z), standardize = true)
        @test X isa EuclideanSpace
        @test length(X) == n
        f = eccentricity(X)
        M = classical_mapper(X, R1Cover(f, Uniform(length = 6, expansion = 0.3)),
                             DBscan(), SimpleNerve())
        ns = node_statistics(M, tbl; stats = (mean, std))
        @test ns isa NamedTuple
        @test haskey(ns, :node)
        @test haskey(ns, :size)
        @test any(k -> occursin("x_", string(k)), keys(ns))
    end

    @testset "plot entry points exist (no rendering)" begin
        @test mapper_plot isa Function
        @test mapper_explorer isa Function
        @test metricspace_plot isa Function
    end

    @testset "persistent homology: ripserer on a circle finds H1" begin
        pts = [Float64[cos(t), sin(t)] for t in range(0, 2π, length = 21)[1:20]]
        result = ripserer(pts)
        @test length(result) ≥ 2          # H0 and H1
        h1 = result[2]
        @test length(h1) ≥ 1              # the loop is detected
        @test persistence(h1[1]) > 0
    end

    @testset "diagram tools & vectorizers exist and run" begin
        for s in (:Bottleneck, :Wasserstein, :Landscape, :PersistenceImage, :BettiCurve)
            @test isdefined(JuliaTDA, s)
        end
        pts = [Float64[cos(t), sin(t)] for t in range(0, 2π, length = 21)[1:20]]
        result = ripserer(pts)
        h1 = result[2]
        land = Landscape(2, 0.0, 2.0; length = 10)
        @test length(land(h1)) == 10
        @test Bottleneck()(result[1], result[1]) == 0.0
    end

    @testset "ToMATo clustering: tomato, proximity_graph" begin
        @test tomato isa Function
        @test proximity_graph isa Function
        X = DS.three_clusters(300)
        dens = JuliaTDA.ToMATo.knn_density(X; k = 10)   # qualified ToMATo version
        @test length(dens) == length(X)
        g = proximity_graph(X, 0.5)
        clusters, _ = tomato(X, g, dens, 0.5)
        @test length(clusters) == length(X)
    end

    @testset "knn_density collision resolution" begin
        # Unqualified `knn_density` resolves to MetricSpaces' version (via the
        # TDAplots chain); ToMATo's stays reachable, fully qualified.
        @test knn_density === JuliaTDA.MetricSpaces.knn_density
        @test isdefined(JuliaTDA.ToMATo, :knn_density)
        @test knn_density !== JuliaTDA.ToMATo.knn_density
        X = DS.sphere(40)
        @test length(knn_density(X)) == length(X)
    end

end
