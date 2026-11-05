module MultiparameterPersistenceMLJExt
using MultiparameterPersistence
using Tables
import MLJModelInterface as MMI

mutable struct SignedMeasureModel <: MMI.Unsupervised
    bandwidth::Float64
    resolution::Tuple{Int,Int}
    centers::Union{Nothing,Matrix{Float64}}
end
function MultiparameterPersistence.measure_vectorizer_model(;bandwidth=1.0,resolution=(10,10),centers=nothing)
    isfinite(bandwidth) && bandwidth>0 || throw(ArgumentError("positive bandwidth required"))
    length(resolution)==2 && all(x -> x isa Integer && x>0,resolution) || throw(ArgumentError("positive 2D resolution required"))
    c = isnothing(centers) ? nothing : MeasureVectorizer(centers;bandwidth=bandwidth).centers
    return SignedMeasureModel(bandwidth,Tuple(Int.(resolution)),c)
end
_measures(X::AbstractVector) = X
_measures(X) = Tables.getcolumn(Tables.columns(X),:measure)
function MMI.fit(model::SignedMeasureModel,::Int,X)
    measures=_measures(X)
    !isempty(measures) || throw(ArgumentError("training data must be nonempty"))
    centers=model.centers
    if isnothing(centers)
        atoms=reduce(hcat,(m.locations for m in measures); init=zeros(2,0))
        bounds = size(atoms,2)==0 ? ((-1.0,1.0),(-1.0,1.0)) :
            (extrema(atoms[1,:]),extrema(atoms[2,:]))
        axes=map(bounds,model.resolution) do (lo,hi),n
            lo==hi && ((lo,hi)=(lo-0.5,hi+0.5))
            collect(range(lo,hi;length=n))
        end
        centers=reduce(hcat,([x,y] for x in axes[1],y in axes[2]))
    end
    fit=MeasureVectorizer(centers;bandwidth=model.bandwidth)
    return fit,nothing,(n_features=size(fit.centers,2),)
end
function MMI.transform(::SignedMeasureModel,fit::MeasureVectorizer,X)
    ms=_measures(X)
    A=isempty(ms) ? zeros(0,size(fit.centers,2)) : permutedims(reduce(hcat,fit.(ms)))
    names=Tuple(Symbol("measure_",i) for i in axes(A,2))
    return NamedTuple{names}(Tuple(copy(A[:,i]) for i in axes(A,2)))
end
MMI.input_scitype(::Type{SignedMeasureModel}) = Union{AbstractVector,MMI.Table}
MMI.output_scitype(::Type{SignedMeasureModel}) = MMI.Table(MMI.Continuous)
MMI.is_pure_julia(::Type{SignedMeasureModel}) = true
MMI.metadata_pkg(SignedMeasureModel;name="MultiparameterPersistence",uuid="7549c581-73e9-4ea7-bfa2-841382f003ce",
    url="https://github.com/JuliaTDA/JuliaTDA.jl/tree/main/lib/MultiparameterPersistence",license="MIT",julia=true,is_wrapper=false)
end
