using LinearAlgebra, Random, SparseArrays, Statistics
using MetricSpaces: EuclideanSpace
import MultiparameterPersistence as MP
using PersistenceInference: permutation_test
using TDAPersistenceDiagrams
using TDARipserer: Rips
using TDAmapper.Nerves
using ToMATo: tomato
using ToMATo.Graphs: SimpleGraph, add_edge!, ne, neighbors

BLAS.set_num_threads(1)

function timing(operation; repeats=5)
    operation()
    times, bytes = Float64[], Int[]
    for _ in 1:repeats
        GC.gc()
        sample = @timed operation()
        push!(times, sample.time)
        push!(bytes, sample.bytes)
    end
    return (1000median(times), median(bytes) / 2^20)
end

function radius_sweep()
    rng = MersenneTwister(88)
    println("points,dimension,radius,density,automatic_sparse,dense_ms,sparse_ms,indexed_ms,auto_ms,dense_mib,sparse_mib,indexed_mib,auto_mib")
    for n in (256, 1024, 4096), d in (2, 4, 8, 16)
        points = [ntuple(_ -> rand(rng), d) for _ in 1:n]
        for radius in sqrt(d) .* (0.07, 0.18, 0.32, 0.65)
            indexed = Rips(points; threshold=radius, radius_graph=true)
            pairwise = Rips(points; threshold=radius, sparse=true)
            selected = Rips(points; threshold=radius, radius_graph=:auto)
            @assert findnz(indexed.adj)[1:2] == findnz(pairwise.adj)[1:2]
            @assert isapprox(indexed.adj, pairwise.adj; atol=1e-10, rtol=0)
            if issparse(selected.adj)
                @assert selected.adj == indexed.adj
            else
                @assert sparse(selected.adj .* (selected.adj .<= radius)) == pairwise.adj
            end
            modes = ((false, false), (false, true), (true, false), (:auto, false))
            stats = [timing(() -> Rips(points; threshold=radius, radius_graph, sparse);
                repeats=3) for (radius_graph, sparse) in modes]
            density = nnz(indexed.adj) / (n * (n - 1))
            println(join((n, d, radius, density, issparse(selected.adj), first.(stats)..., last.(stats)...), ','))
            flush(stdout)
        end
    end
end

function nerve_sweep()
    X = EuclideanSpace([[Float64(i)] for i in 1:513])
    cover = [[i, i + 1] for i in 1:512]
    function serial_pairs()
        graph = SimpleGraph(length(cover))
        for i in eachindex(cover), j in (i + 1):length(cover)
            isempty(intersect(cover[i], cover[j])) || add_edge!(graph, i, j)
        end
        return graph
    end
    actual = () -> make_graph(X, cover, SimpleNerve())
    @assert actual() == serial_pairs() && ne(actual()) == 511
    println("cover_sets,method,ms,mib")
    for (label, f) in (("pairwise", serial_pairs), ("memberships", actual))
        println(join((length(cover), label, timing(f)...), ','))
    end
end

function kernel_sweep(output)
    mkpath(output)
    println("diagrams,max_intervals,threads,serial_ms,threaded_ms,serial_mib,threaded_mib")
    k = PersistenceScaleSpaceKernel(; sigma=0.7)
    for n in (8, 16, 32, 48, 96), m in (16, 80, 160)
        rng = MersenneTwister(524 + n + m)
        diagrams = PersistenceDiagram[]
        for i in 1:n
            bars = [(b, b + rand(rng)) for b in rand(rng, i % 7 == 1 ? 0 : rand(rng, m ÷ 2:m))]
            i % 3 == 0 && push!(bars, (0.0, Inf))
            push!(diagrams, PersistenceDiagram(bars))
        end
        serial = () -> kernel_matrix(k, diagrams)
        parallel = () -> kernel_matrix(k, diagrams; threaded=true)
        reference = serial()
        @assert reference == parallel()
        cpu = timing(serial)
        threaded = timing(parallel)
        println(join((n, m, Threads.nthreads(), cpu[1], threaded[1], cpu[2], threaded[2]), ','))
        prefix = joinpath(output, "gram-$(n)-$(m)")
        open(prefix * ".tsv", "w") do io
            for (i, d) in enumerate(diagrams), bar in d
                println(io, i - 1, '\t', birth(bar), '\t', death(bar))
            end
        end
        write(prefix * ".f64", Matrix(reference))
    end
end

function permutation_sweep(n, workers)
    r = MersenneTwister(619)
    X = [(cos(t)+0.03randn(r), sin(t)+0.03randn(r)) for t in range(0, 6.2; length=n)]
    Y = [(cos(t)+0.05randn(r), 0.8sin(t)+0.05randn(r)) for t in range(0, 6.2; length=n)]
    run(k) = permutation_test(X, Y; n_perm=48, rng=MersenneTwister(57),
        workers=k, threshold=1.8, dim=1)
    ref, selected = run(1), run(workers)
    @assert ref.null_distribution == selected.null_distribution && ref.pvalue == selected.pvalue
    println(join((n, workers, selected.pvalue, timing(() -> run(workers); repeats=3)...), ','))
end

# Independent relabel-every-point reference with the same live elder policy.
function relabel(X, g, ds)
    labels = zeros(Int, length(X))
    modes = Dict{Int,Vector{Float64}}()
    for i in sortperm(ds; rev=true)
        higher = filter(j -> ds[j] > ds[i], neighbors(g, i))
        if isempty(higher)
            labels[i] = i
            modes[i] = [ds[i], Inf]
        else
            anchor = argmax(j -> ds[j], higher)
            labels[i] = labels[anchor]
            for j in higher
                a, b = labels[anchor], labels[j]
                a == b && continue
                survivor, absorbed = ds[a] > ds[b] ? (a, b) : (b, a)
                modes[absorbed][2] = ds[i]
                replace!(labels, absorbed => survivor)
            end
        end
    end
    return labels, modes
end

function tomato_sweep()
    println("points,merges,union_find_ms,relabel_ms,union_find_mib,relabel_mib")
    for n in (512, 2048, 8192, 32768)
        X = EuclideanSpace([[Float64(i)] for i in 1:n])
        g = SimpleGraph(n)
        for i in 1:(n - 1)
            add_edge!(g, i, i + 1)
        end
        ds = [Float64(isodd(i) ? n + i : i) for i in 1:n]
        reference = relabel(X, g, ds)
        f = () -> tomato(X, g, ds)
        labels, modes = f()
        @assert all(==(n - 1), reference[1]) && all(==(1), labels) && modes == reference[2]
        a, b = timing(f), timing(() -> relabel(X, g, ds))
        println(join((n, count(x -> isfinite(x[2]), values(modes)), a[1], b[1], a[2], b[2]), ','))
    end
end

function multiparameter_sweep()
    rng = MersenneTwister(822)
    x = [Tuple(rand(rng, 2)) for _ in 1:16]
    levels = [rand(rng) for _ in x]
    F = MP.bifiltration(x, levels; max_scale=0.45, dim_max=3)
    println("axis_length,quantity,incremental_ms,reference_ms,incremental_mib,reference_mib")
    for n in (12, 24)
        scales = range(0, 0.45; length=n)
        levels = range(0, 1; length=n)
        for dim in (-1, 0, 1, 2)
            if dim == -1
                current = () -> MP.euler_surface(F; scales, levels).values
                reference = () -> [sum((isodd(length(simplex)) ? 1 : -1)
                    for (simplex, grade) in zip(F.simplices, F.grades)
                    if grade[1] <= scale && grade[2] <= level; init=0)
                    for scale in scales, level in levels]
            else
                current = () -> MP.hilbert_function(F; scales, levels, dim).values
                reference = () -> [MP._dimension(MP._homology(F, dim, (scale, level)))
                    for scale in scales, level in levels]
            end
            @assert current() == reference()
            a, b = timing(current; repeats=3), timing(reference; repeats=3)
            println(join((n, dim == -1 ? "Euler" : "H$dim", a[1], b[1], a[2], b[2]), ','))
        end
    end
end

mode = ARGS[1]
mode == "radius" ? radius_sweep() :
mode == "nerves" ? nerve_sweep() :
mode == "kernel" ? kernel_sweep(ARGS[2]) :
mode == "permutation" ? permutation_sweep(parse(Int, ARGS[2]), parse(Int, ARGS[3])) :
mode == "tomato" ? tomato_sweep() :
mode == "multiparameter" ? multiparameter_sweep() : error("unknown sweep: $mode")
