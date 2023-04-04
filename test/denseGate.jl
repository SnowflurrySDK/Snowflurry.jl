using Snowflake
using Test

include("testFunctions.jl")

test_operator_implementation(DenseOperator,dim=2,label="DenseOperator")

@testset "DenseOperator: single target" begin
  
    dense_op=DenseOperator([[1.,2.] [3.,4.]])

    # Base.:* specialization

    result=Matrix{ComplexF64}([[7.,10.] [15.,22.]])

    @test get_matrix(DenseOperator(dense_op)*dense_op)≈ result
    @test get_matrix(dense_op*DenseOperator(dense_op))≈ result

    # Exponentiation

    op=exp(-im*π/2*dense_op)
    
    result=Matrix{ComplexF64}(undef,2,2)

    result[1]=0.5027781028113743 + 0.22095792111145418im
    result[2]=-0.48249068261521855 - 0.48249068261521916im
    result[3]=-0.7237360239228279 - 0.7237360239228288im
    result[4]=-0.22095792111145363 - 0.5027781028113746im

    @test get_matrix(op) ≈ result

    # LinearAlgebra.eigen

    vals, vecs = eigen(dense_op)
    @test vals[1] ≈  -0.37228132326901453 + 0.0im
    @test vals[2] ≈   5.372281323269014 + 0.0im

end

@testset "DenseOperator: dual targets" begin

    ψ_0=Ket([1.,2.,3.,4.])
    ψ_1=Ket([1.,2.,3.,4.])  

    dense_op=DenseOperator(reshape([v for v in 1:16],4,4))

    Snowflake.apply_operator!(ψ_1,dense_op,[1,2])

    @test dense_op*ψ_0 ≈ ψ_1

end

@testset "DenseOperator: three targets" begin

    ψ_0=Ket([v for v in 1:8])
    ψ_1=Ket([v for v in 1:8])

    dense_op=DenseOperator(reshape([v for v in 1:64],8,8))

    Snowflake.apply_operator!(ψ_1,dense_op,[1,2,3])

    @test dense_op*ψ_0 ≈ ψ_1

end