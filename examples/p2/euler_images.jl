using JuliaTDA
import MLJBase, Tables

mask=trues(5,5);mask[2:4,2:4].=false
E=ect(mask;directions=sample_directions(2;n=16),n_thresholds=64)
S=sect(E)
@assert all(E.values[end,:].==0) # annulus Euler characteristic
@assert maximum(abs,S.values[[1,end],:])<1e-12
println("ECT table rows: ",length(euler_table(E).value))

results=Dict{Symbol,Any}()
for kind in (:height,:radial,:dilation,:erosion,:signed_distance)
    transform=ImageFiltration(kind)
    diagrams=image_persistence(mask;transform=transform)
    results[kind]=diagrams
    println(kind," H₁ intervals: ",length(diagrams[2]))
end
println("Cubical ECC: ",cubical_ecc(zeros(size(mask));mask=mask).values)

# Native MLJ composition: binary masks → height images → cubical PH features.
preprocessing=MLJBase.machine(image_filtration_model(:height),[mask])
MLJBase.fit!(preprocessing;verbosity=0)
images=MLJBase.transform(preprocessing,[mask])
finite_threshold=maximum(filter(isfinite,vec(only(images))))
ph=MLJBase.machine(CubicalPersistentHomology(threshold=finite_threshold),images)
MLJBase.fit!(ph;verbosity=0)
features=MLJBase.transform(ph,images)
@assert length(Tables.columnnames(features))>0
