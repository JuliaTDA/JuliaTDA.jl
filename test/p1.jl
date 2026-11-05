@testset "P1 umbrella workflows" begin
    for name in (:confidence_band,:multiplier_bootstrap,:max_persistence_significance,
            :independence_test,:differentiable_persistence,:topological_loss,
            :recommended_ranges,:tuning_ranges,:EulerCharacteristicCurve,
            :PersistenceBlock,:TropicalCoordinates,:TentTemplate,
            :ComplexPolynomial,:TopologicalVector,:Atol,:PersistenceDescriptorVectorizer)
        @test isdefined(JuliaTDA,name)
    end
    diagrams = [PersistenceDiagram([(0.0,1.0)];dim=1),
        PersistenceDiagram([(0.0,2.0)];dim=1)]
    band = confidence_band(diagrams;grid=[0.0,0.5,1.0,2.0],n_boot=9)
    @test band.estimate==[0.0,0.5,0.5,0.0]
    @test max_persistence_significance(last(diagrams),fill(0.5,99)).pvalue==0.01
    @test recommended_ranges(PersistenceImageVectorizer()).sigma.scale==:log
    X = [0.0 1.0 1.23 0.11;0.0 0.07 1.1 1.02]
    @test size(differentiable_persistence(X),2)==2
    @test topological_loss(X)>0
end
