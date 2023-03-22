using Snowflake
using Test
using StaticArrays

include("testFunctions.jl")

test_operator_implementation(DiagonalOperator,dim=1,label="DiagonalOperator")


@testset "DiagonalOperator" begin
  
    diag_op=DiagonalOperator([1.,2.])

    # Base.:* specialization

    @test (Operator(diag_op)*diag_op)≈ DiagonalOperator([v^2 for v in Vector(diag_op.data)])
    @test (diag_op*Operator(diag_op))≈ DiagonalOperator([v^2 for v in Vector(diag_op.data)])

    # Exponentiation
    θ=π
    @test (exp(-im*θ/2*diag_op)).data ≈ [-im,-1.]

    # LinearAlgebra.eigen

    vals, vecs = eigen(diag_op)
    @test vals[1] ≈ 1.0
    @test vals[2] ≈ 2.0 

end


