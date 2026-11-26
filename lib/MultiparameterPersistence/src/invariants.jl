"""
    GridInvariant(scales, levels, values)

A rectangular invariant with `values[scale_index, level_index]`. Both axes must
be finite, nonempty and strictly increasing; the finite real-valued matrix must
match their lengths. Axes are stored as `Vector{Float64}` and values as a matrix
of the supplied real element type.

Implements Tables.jl's column interface with columns `scale`, `level`, and
`value`. Flattened table order varies scale first, following `vec(values)`.
See [`signed_measure`](@ref) for mixed-difference encoding and reconstruction.
"""
struct GridInvariant{T}
    scales::Vector{Float64}
    levels::Vector{Float64}
    values::Matrix{T}
    function GridInvariant(scales,levels,values::AbstractMatrix{T}) where {T<:Real}
        x,y=_grid(scales,levels;max_grid=typemax(Int))
        size(values)==(length(x),length(y)) || throw(ArgumentError("values must match grid shape"))
        all(isfinite,values) || throw(ArgumentError("finite grid values required"))
        new{T}(x,y,Matrix(values))
    end
end

function _computation_limits(F,grid_size,max_chain,max_workspace;retain_grid=false)
    counts=[count(s -> length(s)==d,F.simplices) for d in unique(length.(F.simplices))]
    largest=isempty(counts) ? 0 : maximum(counts)
    max_chain>0 && max_workspace>0 || throw(ArgumentError("positive computation limits required"))
    largest<=max_chain || throw(ArgumentError("max_chain exceeded; truncate or reduce the complex"))
    big(largest)^2*(retain_grid ? grid_size : 1)<=max_workspace ||
        throw(ArgumentError("max_workspace exceeded; reduce grid or complex"))
end

function _grid(scales, levels; max_grid=4096)
    x, y = collect(Float64, scales), collect(Float64, levels)
    for a in (x, y)
        !isempty(a) && all(isfinite, a) && issorted(a) && allunique(a) ||
            throw(ArgumentError("grid axes must be finite, nonempty and strictly increasing"))
    end
    length(x) * length(y) <= max_grid || throw(ArgumentError("max_grid exceeded"))
    return x, y
end

function _scale_order(F, simplex_size)
    indices = findall(s -> length(s) == simplex_size, F.simplices)
    return sort!(indices; by=i -> F.grades[i][1])
end

function _component_root!(parents, i)
    while parents[i] != i
        parents[i] = parents[parents[i]]
        i = parents[i]
    end
    return i
end

function _component_grid(F, scales, levels)
    vertex_ids = _scale_order(F, 1)
    edge_ids = _scale_order(F, 2)
    labels = Dict(only(F.simplices[id]) => i for (i, id) in enumerate(vertex_ids))
    endpoints = [NTuple{2,Int}(map(v -> labels[v], F.simplices[id])) for id in edge_ids]
    values = zeros(Int, length(scales), length(levels))
    parents = collect(eachindex(vertex_ids))
    sizes = similar(parents)

    for (j, level) in enumerate(levels)
        parents .= eachindex(parents)
        fill!(sizes, 1)
        vertex = edge = 1
        components = 0
        for (i, scale) in enumerate(scales)
            while vertex <= length(vertex_ids) && F.grades[vertex_ids[vertex]][1] <= scale
                components += F.grades[vertex_ids[vertex]][2] <= level
                vertex += 1
            end
            while edge <= length(edge_ids) && F.grades[edge_ids[edge]][1] <= scale
                u, v = endpoints[edge]
                grade = F.grades[edge_ids[edge]]
                edge += 1
                grade[2] <= level || continue
                a, b = _component_root!(parents, u), _component_root!(parents, v)
                a == b && continue
                if sizes[a] < sizes[b]
                    a, b = b, a
                end
                parents[b] = a
                sizes[a] += sizes[b]
                components -= 1
            end
            values[i, j] = components
        end
    end
    return values
end

function _boundary_supports(F, rows, columns)
    row = Dict(F.simplices[id] => i for (i, id) in enumerate(rows))
    return [BitSet(row[face] for face in _faces(F.simplices[id])) for id in columns]
end

function _raise_rank!(basis, support)
    column = copy(support)
    while !isempty(column)
        p = last(column)
        current = basis[p]
        if isnothing(current)
            basis[p] = column
            return 1
        end
        symdiff!(column, current)
    end
    return 0
end

function _boundary_rank_grid(F, scales, levels, dim)
    lower = _scale_order(F, dim)
    cells = _scale_order(F, dim + 1)
    higher = _scale_order(F, dim + 2)
    down = _boundary_supports(F, lower, cells)
    up = _boundary_supports(F, cells, higher)
    down_basis = Vector{Union{Nothing,BitSet}}(nothing, length(lower))
    up_basis = Vector{Union{Nothing,BitSet}}(nothing, length(cells))
    values = zeros(Int, length(scales), length(levels))
    for (j, level) in enumerate(levels)
        fill!(down_basis, nothing)
        fill!(up_basis, nothing)
        c = h = 1
        active = rank_down = rank_up = 0
        for (i, scale) in enumerate(scales)
            while c <= length(cells) && F.grades[cells[c]][1] <= scale
                if F.grades[cells[c]][2] <= level
                    active += 1
                    rank_down += _raise_rank!(down_basis, down[c])
                end
                c += 1
            end
            while h <= length(higher) && F.grades[higher[h]][1] <= scale
                if F.grades[higher[h]][2] <= level
                    rank_up += _raise_rank!(up_basis, up[h])
                end
                h += 1
            end
            values[i, j] = active - rank_down - rank_up
        end
    end
    return values
end

"""
    hilbert_function(F; scales, levels, dim=0, max_grid=4096,
                     max_chain=2048, max_workspace=100_000_000)

Exact dimensions of H`dim` at each grid grade over F₂. The complex must include
dimension `dim+1` if deaths in that dimension are to be represented.
For each function level, the computation sweeps the scale axis using union-find
in H₀ and incrementally reduced F₂ boundary columns in higher degrees.

Returns a [`GridInvariant`](@ref) whose entries are pointwise topological Betti
counts, not free-resolution Betti numbers. Both axes must be finite, nonempty
and strictly increasing. `max_grid` bounds their product; `max_chain` bounds
the largest chain dimension; `max_workspace` guards its squared size. These
limits are conservative dimension estimates, not measured byte allocations or
runtime guarantees. See [`bigraded_betti`](@ref) for invariants using module maps.
"""
function hilbert_function(F::Bifiltration; scales, levels, dim::Integer=0, max_grid=4096,
        max_chain=2048,max_workspace=100_000_000)
    dim >= 0 || throw(ArgumentError("dim must be nonnegative"))
    x, y = _grid(scales, levels; max_grid=max_grid)
    _computation_limits(F,length(x)*length(y),max_chain,max_workspace)
    values = dim == 0 ? _component_grid(F, x, y) : _boundary_rank_grid(F, x, y, dim)
    return GridInvariant(x, y, values)
end

"""
    euler_surface(F; scales, levels, max_grid=4096)

Return the Euler characteristic at each supplied grade as a [`GridInvariant`](@ref),
using alternating counts of **all active simplices in the constructed complex**.
Axes must be finite, nonempty and strictly increasing. The grid-size product is
bounded by `max_grid`; no homology chain matrices are assembled.

The Euler characteristic equals the alternating sum of homology dimensions over
every dimension of this complex. It need not equal H₀−H₁ if higher homology
exists, including homology created by dimension truncation.
"""
function euler_surface(F::Bifiltration; scales, levels, max_grid=4096)
    x, y = _grid(scales, levels; max_grid=max_grid)
    values = zeros(Int, length(x), length(y))
    for (simplex, (scale, level)) in zip(F.simplices, F.grades)
        i = searchsortedfirst(x, scale; lt=(<))
        j = searchsortedfirst(y, level; lt=(<))
        if i <= length(x) && j <= length(y)
            values[i, j] += isodd(length(simplex)) ? 1 : -1
        end
    end
    for j in axes(values, 2), i in 2:size(values, 1)
        values[i, j] += values[i - 1, j]
    end
    for j in 2:size(values, 2), i in axes(values, 1)
        values[i, j] += values[i, j - 1]
    end
    return GridInvariant(x, y, values)
end

"""
    bigraded_betti(F; scales, levels, dim=0, max_grid=4096,
                   max_chain=2048, max_workspace=100_000_000)

Compute β₀, β₁, β₂ of the grid-discretized H`dim` module via Koszul homology:
M(i-1,j-1) → M(i-1,j) ⊕ M(i,j-1) → M(i,j).
Returns `(beta0, beta1, beta2)` as `GridInvariant`s. Values outside the lower
grid boundary are zero; choose axes containing all critical grades to recover
the original finite presentation's graded Betti numbers. These are module
generators/relations/syzygies, not pointwise topological Betti numbers.

The three named outputs `beta0`, `beta1`, and `beta2` describe generators,
relations, and relations among relations of the **H`dim` module**. In particular,
`beta2` is not H₂. Inclusion-map ranks are computed over F₂ by Boolean/XOR
elimination. The cumulative sum in both directions of `beta0.values -
beta1.values + beta2.values` reconstructs the sampled Hilbert function.

Grid/chain guards are those of [`hilbert_function`](@ref), with the workspace
estimate multiplied by the number of grid positions because homology spaces are
retained. Above the upper grid boundary the sampled module extends constantly;
no artificial death is inserted. Changing/coarsening the axes changes the
sampled module and may omit intermediate features.
"""
function bigraded_betti(F::Bifiltration; scales, levels, dim::Integer=0, max_grid=4096,
        max_chain=2048,max_workspace=100_000_000)
    dim >= 0 || throw(ArgumentError("dim must be nonnegative"))
    x, y = _grid(scales, levels; max_grid=max_grid)
    _computation_limits(F,length(x)*length(y),max_chain,max_workspace;retain_grid=true)
    H = [_homology(F, dim, (a, b)) for a in x, b in y]
    emptyH = HomologySpace(falses(size(H[1].representatives, 1), 0),
                           falses(size(H[1].representatives, 1), 0))
    getH(i, j) = i < 1 || j < 1 ? emptyH : H[i, j]
    b0, b1, b2 = (zeros(Int, length(x), length(y)) for _ in 1:3)
    for i in eachindex(x), j in eachindex(y)
        center, left, below, corner = H[i, j], getH(i-1, j), getH(i, j-1), getH(i-1, j-1)
        D1 = hcat(_inclusion(left, center), _inclusion(below, center))
        D2 = vcat(_inclusion(corner, left), _inclusion(corner, below))
        r1, r2 = _rank(D1), _rank(D2)
        b0[i,j] = _dimension(center) - r1
        b1[i,j] = _dimension(left) + _dimension(below) - r1 - r2
        b2[i,j] = _dimension(corner) - r2
    end
    return (beta0=GridInvariant(x,y,b0), beta1=GridInvariant(x,y,b1), beta2=GridInvariant(x,y,b2))
end

Tables.istable(::Type{<:GridInvariant}) = true
Tables.columnaccess(::Type{<:GridInvariant}) = true
Tables.columns(G::GridInvariant) = (scale=repeat(G.scales; outer=length(G.levels)),
    level=repeat(G.levels; inner=length(G.scales)), value=vec(G.values))
