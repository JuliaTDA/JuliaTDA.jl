using JuliaTDA
using DelayEmbeddings, Random
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners, JuliaTDA.Nerves

rng=Random.Xoshiro(20261003)
series=[sin(2π*i/24)+.01randn(rng) for i in 1:240]
# Six samples is one quarter-period, giving an approximately circular embedding.
states=delay_embedding(series;dimension=2,delay=6)
windows=sliding_window_ph(states;window=48,step=48)
X=EuclideanSpace(collect(states))
M=classical_mapper(X,R1Cover(first.(X),Uniform(length=8,expansion=.3)),DBscan(radius=.4),SimpleNerve())
println("Periodic windows' H₁: ",[length(w.diagrams[2]) for w in windows])
println("Mapper nodes: ",length(M.C))
@assert all(w -> !isempty(w.diagrams[2]),windows)
