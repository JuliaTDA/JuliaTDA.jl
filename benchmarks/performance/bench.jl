using LinearAlgebra, Statistics
using TDARipserer
const PH = TDARipserer
LinearAlgebra.BLAS.set_num_threads(1)

read_points(file, n) = read_points(file, n, Val(length(split(open(readline, file)))))

function read_points(file, n, ::Val{N}) where {N}
    rows = Iterators.take(eachline(file), n)
    return NTuple{N,Float64}[Tuple(parse.(Float64, split(row))) for row in rows]
end

function prepare(workload, input, output, n)
    if workload == "rips"
        points = read_points(input, n)
        length(points) == n || error("requested more points than the fixture contains")
        write(output, Float32.(PH.distances(points)))
    elseif workload == "image"
        image = open(input) do io
            header = read!(io, Vector{Int64}(undef, 6))
            return read!(io, Matrix{Float64}(undef, header[5], header[6]))
        end
        write(output, image[1:n, 1:n])
    elseif workload == "volume"
        # Repeated integer grades, cavities and through-going tunnels.
        volume = Array{Float64}(undef, n, n, n)
        for z in 1:n, y in 1:n, x in 1:n
            u, v, w = (x, y, z) .* (6π / n)
            volume[x, y, z] = round(8 * (cos(u) + cos(v) + cos(w) -
                0.8cos(u) * cos(v) - 0.8cos(v) * cos(w) - 0.8cos(u) * cos(w)))
        end
        write(output, volume)
    else
        error("unknown workload: $workload")
    end
end

function read_array(path, ::Type{T}, dims...) where {T}
    return open(io -> read!(io, Array{T}(undef, dims...)), path)
end

function measure(f, repeats, name; check=nothing)
    GC.gc()
    cold = @timed f()
    cold_time = cold.time
    signature = isnothing(check) ? nothing : check(cold.value)
    cold = nothing
    times, bytes = Float64[], Int[]
    result = nothing
    for _ in 1:repeats
        result = nothing
        GC.gc()
        sample = @timed f()
        push!(times, sample.time)
        push!(bytes, sample.bytes)
        result = sample.value
        if !isnothing(check)
            check(result) == signature || error("barcode changed between timing samples")
        end
    end
    println("timing\t", name, '\t', cold_time, '\t', median(times), '\t', median(bytes),
        '\t', join(times, ','))
    return result
end

barcode_signature(diagrams) = [sort!([(birth(x), death(x)) for x in d]) for d in diagrams]

function save_barcodes(path, diagrams)
    open(path, "w") do io
        for (d, diagram) in enumerate(diagrams)
            for (a, b) in sort!([(birth(x), death(x)) for x in diagram])
                println(io, d - 1, '\t', a, '\t', b)
            end
        end
    end
end

function stages(f, maxdim, parallel, repeats)
    timings = Dict{String,Vector{Float64}}()
    counts = Dict{String,Int}()
    record(stage, seconds) = push!(get!(Vector{Float64}, timings, stage), seconds)
    field = PH.Mod{2}
    for _ in 1:(repeats + 1)
        GC.gc()
        h0 = @timed PH.zeroth_intervals(f, 0, false, field, false)
        record("H0", h0.time)
        m = PH.CoboundaryMatrix{true}(field, f, h0.value[2], h0.value[3])
        for d in 1:maxdim
            counts["H$(d)_columns"] = length(m.columns_to_reduce)
            if parallel && d >= 2
                preclear = @elapsed PH._preclear_apparent_pairs!(m)
                counts["H$(d)_apparent_pairs"] = length(m.reduced)
                record("H$(d)_preclear", preclear)
            end
            record("H$(d)_reduce", @elapsed PH.compute_intervals!(m, 0, false, false))
            if d < maxdim
                assembly = @timed PH.next_matrix(m, false)
                m = assembly.value
                record("H$(d+1)_assemble", assembly.time)
            end
        end
    end
    for (stage, times) in sort!(collect(timings); by=first)
        println("timing\t", stage, '\t', first(times), '\t', median(times[2:end]),
            "\t\t", join(times[2:end], ','))
    end
    for (name, count) in sort!(collect(counts); by=first)
        println("count\t", name, '\t', count)
    end
end

function run_benchmark(workload, method, input, points_file, output, n, maxdim, radius, repeats)
    println("version\tJulia\t", VERSION)
    println("version\tTDARipserer\t", pkgversion(TDARipserer))
    println("count\tblas_threads\t", BLAS.get_num_threads())
    println("count\tthreads\t", Threads.nthreads())
    if workload == "rips"
        D = read_array(input, Float32, n, n)
        thresh = Float32(radius)
        diagrams = if method in ("indexed", "pointwise-pairwise")
            points = read_points(points_file, n)
            indexed = method == "indexed"
            measure(() -> ripserer(points; dim_max=maxdim, threshold=radius, sparse=true,
                radius_graph=indexed), repeats, "end_to_end"; check=barcode_signature)
        elseif method in ("stages", "parallel-stages")
            stages(Rips(D; threshold=thresh), maxdim, method == "parallel-stages", repeats)
            return
        else
            operation = if method == "collapse"
                () -> ripserer(EdgeCollapsedRips, D; dim_max=maxdim, threshold=thresh)
            else
                alg = method == "parallel" ? :parallel_cohomology :
                    method == "redzed" ? :redzed : :cohomology
                sparse = method == "sparse"
                () -> ripserer(D; dim_max=maxdim, threshold=thresh, alg, sparse)
            end
            measure(operation, repeats, "end_to_end"; check=barcode_signature)
        end
    else
        N = workload == "image" ? 2 : 3
        image = read_array(input, Float64, ntuple(_ -> n, N)...)
        alg = method == "cubical-union-find" ? :cubical_union_find : :cohomology
        diagrams = measure(() -> ripserer(Cubical, image; dim_max=maxdim,
            threshold=radius, alg), repeats, "end_to_end"; check=barcode_signature)
        filtration = measure(() -> Cubical(image; threshold=radius), repeats, "grid")
        if method == "cubical-union-find"
            if N == 3
                stages(filtration, 1, false, repeats)
            else
                measure(() -> PH._cubical_h0(filtration, 0), repeats, "H0")
            end
            measure(() -> PH._cubical_dual(filtration, 0), repeats, "H$(N - 1)_dual")
        else
            stages(filtration, maxdim, false, repeats)
        end
    end
    println("count\tbirth_locations\t", sum(d -> count(b -> !isnothing(birth_simplex(b)), d), diagrams))
    println("count\tdeath_locations\t", sum(d -> count(b -> !isnothing(death_simplex(b)), d), diagrams))
    save_barcodes(output, diagrams)
end

if ARGS[1] == "prepare"
    prepare(ARGS[2], ARGS[3], ARGS[4], parse(Int, ARGS[5]))
else
    run_benchmark(ARGS[1:5]..., parse(Int, ARGS[6]), parse(Int, ARGS[7]),
        parse(Float64, ARGS[8]), parse(Int, ARGS[9]))
end
