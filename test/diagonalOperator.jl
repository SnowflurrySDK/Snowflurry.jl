using Snowflake
using Test
using StaticArrays

include("testFunctions.jl")

test_operator_implementation(DiagonalOperator,dim=1,label="DiagonalOperator")


@testset "DiagonalOperator: single target" begin
  
    diag_op=DiagonalOperator([1.,2.])

    # Base.:* specialization

    result=Matrix{ComplexF64}([[1.,0.] [0.,4.]])

    @test get_matrix(Operator(diag_op)*diag_op)≈ result
    @test get_matrix(diag_op*Operator(diag_op))≈ result

    # Exponentiation

    op=exp(-im*π/2*diag_op)
    
    @test op[2,2] ≈ ComplexF64(-1.)
    @test op[1,1] ≈ -im

    # LinearAlgebra.eigen

    vals, vecs = eigen(diag_op)
    @test vals[1] ≈ 1.0
    @test vals[2] ≈ 2.0 

end

@testset "DiagonalOperator: 2 targets" begin

    N_targets=2

    diag_op=DiagonalOperator(ComplexF64[exp(im*n*pi/4.0) for n in 1:2^N_targets])

    ψ= Ket([1., 10., 100., 1000.])

    target_qubit_1=1
    target_qubit_2=2

    Snowflake.apply_operator!(ψ, diag_op,[target_qubit_1,target_qubit_2])

    ψ_result=Ket([
        0.7071067811865476 + 0.7071067811865475im
        0.0 + 10.0im
        -70.71067811865474 + 70.71067811865476im
        -1000.0 + 0.0im
    ])

    @test ψ≈ψ_result

end

@testset "DiagonalOperator: 3 targets" begin

    N_targets=3

    diag_op=DiagonalOperator(ComplexF64[exp(im*n*pi/4.0) for n in 1:2^N_targets])

    qubit_count=3

    ψ= Ket([10^v for v in 1:2^qubit_count])

    target_qubit_1=1
    target_qubit_2=2
    target_qubit_3=3

    connected_qubits=[
        target_qubit_1,
        target_qubit_2,
        target_qubit_3
        ]

    Snowflake.apply_operator!(ψ,diag_op,connected_qubits)

    ψ_result=Ket([
        7.0710678118654755 + 7.071067811865475im
        0.0 + 100.0im
        -707.1067811865474 + 707.1067811865476im
        -10000.0 + 0.0im
        -70710.67811865477 - 70710.67811865475im
        0.0 - 1.0e6im
        7.071067811865473e6 - 7.071067811865477e6im
        1.0e8 - 0.0im  
    ])

    @test ψ≈ψ_result

    ##################

    target_qubit_1=1
    target_qubit_2=2
    target_qubit_3=10 # erroneous

    connected_qubits=[
        target_qubit_1,
        target_qubit_2,
        target_qubit_3
        ]

    @test_throws InexactError Snowflake.apply_operator!(ψ,diag_op,connected_qubits)

end
