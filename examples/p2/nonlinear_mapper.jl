using JuliaTDA
using Random, LinearAlgebra, Zygote, Optimisers
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners, JuliaTDA.Nerves

rng=Random.Xoshiro(20261003)
points=[2rand(rng,2).-1 for _ in 1:80]
X=EuclideanSpace(points)
target=[sum(abs2,x) for x in X]
# Compare against a linear filter with an intercept, fitted by least squares.
design=hcat(permutedims(reduce(hcat,points)),ones(length(X)))
linear_prediction=design*(design\target)
linear_mse=sum(abs2,linear_prediction.-target)/length(X)

neural_filter=MLPFilter([2,12,1])
parameters=initial_parameters(neural_filter;rng=Random.Xoshiro(7))
# Objective: approximate a radial shape filter, with a small graph-topology penalty.
radial_mse=p -> sum(abs2,neural_filter(X,p).-target)/length(X)
result=optimize_filter(X,parameters;filter=neural_filter,
    loss=(g,v)->.001total_extended_persistence(g,v),regularizer=radial_mse,
    optimizer=Optimisers.Adam(.02),n_epochs=400)
neural_mse=radial_mse(result.θ)
println("Linear radial-filter MSE: ",linear_mse)
println("Nonlinear radial-filter MSE: ",neural_mse)
@assert neural_mse<linear_mse/4
M=classical_mapper(X,R1Cover(neural_filter(X,result.θ),Uniform(length=8,expansion=.3)),Trivial(),SimpleNerve())
println("Learned radial Mapper nodes: ",length(M.C))
