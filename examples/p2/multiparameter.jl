using JuliaTDA
using Tables
import MLJBase

# A square plus a remote point removed by the function coordinate at level 0.
points=[[0.,0.],[1.,0.],[1.,1.],[0.,1.],[4.,4.]]
F=bifiltration(points,[0.,0.,0.,0.,2.];dim_max=1)
grid=(scales=[0.,1.,sqrt(2),6.],levels=[0.,2.])
H=hilbert_function(F;grid...,dim=1)
B=bigraded_betti(F;grid...,dim=1)
@assert H.values[2,1]==1 && H.values[3,1]==0
@assert cumsum(cumsum(B.beta0.values-B.beta1.values+B.beta2.values;dims=1);dims=2)==H.values
println("H₁ Hilbert surface: ",H.values)
println("Hilbert table: ",Tables.columntable(H))

# Exact Euler measures avoid threshold snapping. Fit shared feature centers once.
measures=[signed_measure(F),signed_measure(bifiltration(points,[0.,0.,0.,0.,1.]))]
model=measure_vectorizer_model(resolution=(4,4),bandwidth=.5)
mach=MLJBase.machine(model,measures)
MLJBase.fit!(mach;verbosity=0)
features=MLJBase.transform(mach,measures)
println("Gaussian signed-measure feature count: ",length(Tables.columnnames(features)))
@assert length(Tables.columnnames(features))==16
