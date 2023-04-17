using Snowflake
using Test

@testset "AbstractOperator: NotImplemented" begin

    struct NonExistentOperator{T<:ComplexF64} <: AbstractOperator
        data::Matrix{T}
    end

    non_square_op=NonExistentOperator(ComplexF64[[1.,2.,3.] [4.,5.,6.]])
    
    @test_throws NotImplementedError get_matrix(non_square_op)

    @test_throws ErrorException get_num_qubits(non_square_op)
    @test_throws ErrorException get_num_bodies(non_square_op)
end

@testset "AbstractOperator: math operations" begin

    # mixing AbstractOperator subtypes

    diag_op=DiagonalOperator([1.,2.])
    diag_op_dense=DenseOperator(get_matrix(diag_op))

    anti_diag_op=AntiDiagonalOperator([3.,4.])
    anti_diag_op_dense=DenseOperator(get_matrix(anti_diag_op))

    @test !isapprox(diag_op,anti_diag_op)
    
    sum_op=diag_op+anti_diag_op

    @test get_matrix(sum_op)==Matrix{ComplexF64}([[1.,4.] [3.,2.]])
    
    diff_op=diag_op-anti_diag_op

    @test get_matrix(diff_op)==Matrix{ComplexF64}([[1.,-4.] [-3.,2.]])
    
    @test commute(diag_op,anti_diag_op) ≈ commute(diag_op_dense,anti_diag_op_dense)
    @test anticommute(diag_op,anti_diag_op) ≈ anticommute(diag_op_dense,anti_diag_op_dense)

    @test kron(diag_op,anti_diag_op)≈ kron(diag_op_dense,anti_diag_op_dense)

end
