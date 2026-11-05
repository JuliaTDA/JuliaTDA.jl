@testset "P2 umbrella integration" begin
    mask=trues(3,3);mask[2,2]=false
    @test cubical_ecc(zeros(3,3);mask=mask).values==[0]
    @test ect(mask).values[end,1]==0
    @test length(image_persistence(mask;transform=ImageFiltration(:height))[2])==1
    F=bifiltration([[0.,0.],[1.,0.],[1.,1.],[0.,1.]],zeros(4))
    G=hilbert_function(F;scales=[0.,1.,sqrt(2)],levels=[0.],dim=1)
    @test G.values[:,1]==[0,1,0]
    @test length(MeasureVectorizer(reshape([0.,0.],2,1))(signed_measure(F)))==1
    @test isdefined(JuliaTDA,:optimal_cycle)
    @test isdefined(JuliaTDA,:delay_embedding)
    @test isdefined(JuliaTDA,:MLPFilter)
end
