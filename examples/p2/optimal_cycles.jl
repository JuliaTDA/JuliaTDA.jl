using JuliaTDA
using JuMP, HiGHS

points=[[0.,0.],[1.,0.],[1.,1.],[0.,1.]]
filtration=Rips(points)
interval=only(ripserer(filtration;reps=true)[2])
cycle=optimal_cycle(filtration,interval;weights=s -> begin
    a,b=collect(JuliaTDA.TDARipserer.vertices(s))
    sqrt(sum(abs2,points[a].-points[b]))
end)
volume=optimal_volume(filtration,interval)
println("Optimal loop length: ",cycle.objective)
println("Explanatory edges: ",[collect(JuliaTDA.TDARipserer.vertices(s)) for s in cycle.chain])
println("Minimum filling triangle count: ",volume.objective)
@assert cycle.objective≈4 && volume.objective==2
