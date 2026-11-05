using Test
using Tables
using MultiparameterPersistence
import MLJModelInterface as MMI

@testset "Function-Rips and exact F₂ invariants" begin
    F=bifiltration([[0.0],[1.0]],[0.,1.])
    axes=(scales=[0.,1.],levels=[0.,1.])
    H=hilbert_function(F;axes...)
    @test H.values==[1 2;1 1]
    @test euler_surface(F;axes...).values==H.values
    @test length(Tables.columntable(H).value)==4
    B=bigraded_betti(F;axes...)
    @test B.beta0.values==[1 1;0 0]
    @test B.beta1.values==[0 0;0 1]
    @test all(iszero,B.beta2.values)
    @test cumsum(cumsum(B.beta0.values-B.beta1.values+B.beta2.values;dims=1);dims=2)==H.values

    # Two disks sharing their boundary: six relations on five graph loops,
    # with one relation between relations. A genuine β₂, not a finite difference.
    ss=Tuple{Vararg{Int}}[(i,) for i in 1:5]
    append!(ss,[(1,2),(2,3),(1,3),(1,4),(2,4),(3,4),(1,5),(2,5),(3,5)])
    gg=fill((0.,0.),length(ss))
    append!(ss,[(1,2,4),(2,3,4),(1,3,4),(1,2,5),(2,3,5),(1,3,5)])
    append!(gg,[(1.,0.),(1.,0.),(1.,0.),(0.,1.),(0.,1.),(0.,1.)])
    disk=Bifiltration(ss,gg)
    HD=hilbert_function(disk;axes...,dim=1)
    @test HD.values==[5 2;2 0]
    BD=bigraded_betti(disk;axes...,dim=1)
    @test BD.beta0.values==[5 0;0 0]
    @test BD.beta1.values==[0 3;3 0]
    @test BD.beta2.values==[0 0;0 1]
    @test cumsum(cumsum(BD.beta0.values-BD.beta1.values+BD.beta2.values;dims=1);dims=2)==HD.values
    H2=hilbert_function(disk;axes...,dim=2)
    @test H2.values==[0 0;0 1]
    @test euler_surface(disk;axes...).values==hilbert_function(disk;axes...).values-HD.values+H2.values

    square=bifiltration([[0.,0.],[1.,0.],[1.,1.],[0.,1.]],zeros(4))
    @test hilbert_function(square;scales=[0.,1.,sqrt(2)],levels=[0.],dim=1).values[:,1]==[0,1,0]
    @test_throws ArgumentError bifiltration([[0.],[1.]],zeros(2);max_simplices=2)
    @test_throws ArgumentError Bifiltration([(1,2)],[(0.,0.)])
    @test_throws ArgumentError Bifiltration([(1,),(2,),(1,2)],[(1.,0.),(0.,0.),(0.,0.)])
    @test_throws ArgumentError hilbert_function(F;scales=[1.,0.],levels=[0.])
    @test_throws ArgumentError hilbert_function(F;axes...,max_grid=3)
    @test_throws ArgumentError hilbert_function(F;axes...,max_chain=1)
    @test_throws ArgumentError bigraded_betti(F;axes...,max_workspace=1)
    @test_throws ArgumentError GridInvariant([0.],[0.],zeros(2,2))
end

@testset "Signed measure reconstruction and bounded-Lipschitz features" begin
    G=GridInvariant([0.,1.],[0.,2.],[1 2;3 1])
    m=signed_measure(G)
    reconstructed=[sum(w for (p,w) in zip(eachcol(m.locations),m.weights) if p[1]<=x && p[2]<=y;init=0.) for x in G.scales,y in G.levels]
    @test reconstructed==G.values
    v=MeasureVectorizer([0. 1.;0. 1.];bandwidth=.7)
    @test length(v(m))==2
    delta=1e-4
    shifted=SignedMeasure(m.locations .+ [delta,0.],m.weights)
    @test maximum(abs.(v(m)-v(shifted)))<=sum(abs,m.weights)*delta/(.7*sqrt(exp(1)))+1e-12
    @test v(SignedMeasure(zeros(2,0),Float64[]))==[0.,0.]
    @test_throws ArgumentError MeasureVectorizer(ones(3,2))
    @test_throws ArgumentError MeasureVectorizer(ones(2,2);bandwidth=0)
    model=measure_vectorizer_model(resolution=(3,4),bandwidth=.7)
    fit,_,report=MMI.fit(model,0,[m,shifted])
    @test report.n_features==12
    @test length(Tables.columnnames(MMI.transform(model,fit,[m])))==12
    fixed=copy(fit.centers)
    MMI.transform(model,fit,[SignedMeasure(m.locations.+100,m.weights)])
    @test fit.centers==fixed
    @test_throws ArgumentError measure_vectorizer_model(resolution=(0,3))
    F=bifiltration([[0.],[1.]],[0.,1.])
    perturbed=Bifiltration(F.simplices,[(g[1]+delta,g[2]) for g in F.grades])
    @test maximum(abs.(v(signed_measure(F))-v(signed_measure(perturbed))))<=
        length(F.simplices)*delta/(.7*sqrt(exp(1)))+1e-12
end
