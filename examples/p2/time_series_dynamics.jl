using JuliaTDA
using DelayEmbeddings, DynamicalSystemsBase
using JuliaTDA.ImageCovers, JuliaTDA.IntervalCovers, JuliaTDA.Refiners, JuliaTDA.Nerves

# Use the Julia dynamics stack to generate a Hénon trajectory; no custom integrator.
function henon!(du,u,p,n)
    du[1]=1-p[1]*u[1]^2+u[2]
    du[2]=p[2]*u[1]
    return nothing
end
ds=DeterministicIteratedMap(henon!,[0.,0.],[1.4,.3])
orbit,times=trajectory(ds,240;Ttr=100)
observations=first.(orbit)
states=delay_embedding(observations;dimension=3,delay=1)
windows=sliding_window_ph(states;window=40,step=40)
X=EuclideanSpace(collect(states))
M=classical_mapper(X,R1Cover(first.(X),Uniform(length=8,expansion=.3)),DBscan(radius=.3),SimpleNerve())
println("Hénon window H₁ counts: ",[length(w.diagrams[2]) for w in windows])
println("Hénon Mapper nodes: ",length(M.C))
@assert length(windows)>=5 && !isempty(M.C)
