using Statistics
using TDARipserer
const PH = TDARipserer

function main(matrix_file, output, n, dim, radius, max_columns)
    mkpath(output)
    D = open(io -> read!(io, Matrix{Float32}(undef, n, n)), matrix_file)
    f = Rips(D; threshold=radius)
    field = PH.Mod{2}
    _, columns, skipped = PH.zeroth_intervals(f, 0, false, field, false)
    matrix = PH.CoboundaryMatrix{true}(field, f, columns, skipped)
    for _ in 1:(dim - 1)
        PH.compute_intervals!(matrix, 0, false, false)
        matrix = PH.next_matrix(matrix, false)
    end
    candidates = matrix.columns_to_reduce[1:min(max_columns, end)]
    inputs = Matrix{Int32}(undef, dim + 1, length(candidates))
    for (i, candidate) in enumerate(candidates)
        inputs[:, i] .= PH.vertices(candidate) .- 1
    end
    call() = PH._discover_apparent_pairs(f, candidates)
    matches = call()
    timings = [@elapsed(call()) for _ in 1:5]
    vertices = zeros(Int32, length(matches))
    for (i, match) in enumerate(matches)
        if !isnothing(match)
            vertices[i] = only(setdiff(PH.vertices(match), PH.vertices(candidates[i])))
        end
    end
    write(joinpath(output, "graph.f32"), D)
    write(joinpath(output, "columns.i32"), inputs)
    write(joinpath(output, "matches.i32"), vertices)
    write(joinpath(output, "shape.txt"), "$n $(dim + 1) $(length(matches))\n")
    println(join((n, dim, length(matches), count(!iszero, vertices), Threads.nthreads(),
        median(timings)), ','))
end

main(ARGS[1], ARGS[2], parse(Int, ARGS[3]), parse(Int, ARGS[4]),
    parse(Float32, ARGS[5]), parse(Int, ARGS[6]))
