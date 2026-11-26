using LinearAlgebra, Profile, Statistics
using TDARipserer

function profile_collapse(filename, n, threshold)
    BLAS.set_num_threads(1)
    matrix = open(io -> read!(io, Matrix{Float32}(undef, n, n)), filename)
    filtration = Rips(matrix; threshold)
    EdgeCollapsedRips(filtration)
    runs = [@elapsed EdgeCollapsedRips(filtration) for _ in 1:5]
    Profile.clear()
    @profile for _ in 1:12
        EdgeCollapsedRips(filtration)
    end
    println("Collapse construction median seconds: ", median(runs))
    Profile.print(; format=:flat, sortedby=:count, mincount=3, C=false)
end

profile_collapse(ARGS[1], parse(Int, ARGS[2]), parse(Float32, ARGS[3]))
