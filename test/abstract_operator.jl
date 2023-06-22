using Snowflurry
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

    # mixing operator data types

    op_32=AntiDiagonalOperator(ComplexF32[3,4])
    op_64=AntiDiagonalOperator(ComplexF64[1,5])

    @test typeof((op_32*op_64)[1,1])==typeof(promote(op_32[1,1],op_64[1,1])[1])

    op_32=AntiDiagonalOperator(ComplexF32[3,4])
    op_64=DiagonalOperator(ComplexF64[3,4])

    @test typeof((op_32*op_64)[1,1])==typeof(promote(op_32[1,1],op_64[1,1])[1])    
end


@testset "AbstractOperator cross-compatibility" begin
    
    function math_operations(op1::AbstractOperator,op2::AbstractOperator)

        if size(op1)==size(op2)
            @test get_matrix(op1 * op2) == get_matrix(op1) * get_matrix(op2)
            @test get_matrix(op2 * op1) == get_matrix(op2) * get_matrix(op1) 
            @test typeof((op2 * op1)[1,1]) == typeof(op1[1,1])

            @test get_matrix(op1 + op2) == get_matrix(op1) + get_matrix(op2)
            @test get_matrix(op2 + op1) == get_matrix(op1) + get_matrix(op2)
            @test typeof((op2 + op1)[1,1]) == typeof(op1[1,1])

            @test get_matrix(op1 - op2) == get_matrix(op1) - get_matrix(op2)
            @test typeof((op2 - op1)[1,1]) == typeof(op1[1,1])

        else
            @test_throws DimensionMismatch op1*op2
            @test_throws DimensionMismatch op1+op2
            @test_throws DimensionMismatch op1-op2
        end

    end

    dtypes=[ComplexF64,ComplexF32]

    for dtype in dtypes
        size_2_operators=[
            DenseOperator(reshape(dtype[v*10 for v in 1:4],2,2)),
            DiagonalOperator(dtype[1.,2.]),
            AntiDiagonalOperator(dtype[3.,4.]),
            IdentityOperator(dtype),
            SparseOperator(reshape(dtype[v!=2 ? v*3 : 0 for v in 1:4],2,2)),
        ]

        for op1 in size_2_operators
            for op2 in size_2_operators
                math_operations(op1,op2)
            end
        end

        size_4_operators=[
            DenseOperator(reshape(dtype[v*10 for v in 1:16],4,4)),
            DiagonalOperator(dtype[1.,2.,3.,4.]),
            SparseOperator(reshape(dtype[v%3==0 ? v*3 : 0 for v in 1:16],4,4)),
            SwapLikeOperator(dtype(im)),
        ]

        for op1 in size_4_operators
            for op2 in size_4_operators
                math_operations(op1,op2)
            end
        end

        #DimensionMismatch
        for op1 in size_4_operators
            for op2 in size_2_operators
                math_operations(op1,op2)
                math_operations(op2,op1)
            end
        end
    end

end

@testset "AbstractOperator promotion rules" begin
    
    function assert_promotion_rules(op1::AbstractOperator,op2::AbstractOperator)
 
        @test typeof(op1[1,1]) != typeof(op2[1,1])

        @test typeof((op2 * op1)[1,1]) == typeof(op1[1,1]*op2[1,1])
        @test typeof((op2 + op1)[1,1]) == typeof(op1[1,1]+op2[1,1])
        @test typeof((op2 - op1)[1,1]) == typeof(op1[1,1]-op2[1,1])

    end

    size_2_operators_ComplexF64=[
        DenseOperator(reshape(ComplexF64[v*10 for v in 1:4],2,2)),
        DiagonalOperator(ComplexF64[1.,2.]),
        AntiDiagonalOperator(ComplexF64[3.,4.]),
        IdentityOperator(ComplexF64),
        SparseOperator(reshape(ComplexF64[v!=2 ? v*3 : 0 for v in 1:4],2,2)),
    ]

    size_2_operators_ComplexF32=[
        DenseOperator(reshape(ComplexF32[v*10 for v in 1:4],2,2)),
        DiagonalOperator(ComplexF32[1.,2.]),
        AntiDiagonalOperator(ComplexF32[3.,4.]),
        IdentityOperator(ComplexF32),
        SparseOperator(reshape(ComplexF32[v!=2 ? v*3 : 0 for v in 1:4],2,2)),
    ]

    for op1 in size_2_operators_ComplexF32
        for op2 in size_2_operators_ComplexF64
            assert_promotion_rules(op1,op2)
        end
    end

    size_4_operators_ComplexF64=[
        DenseOperator(reshape(ComplexF64[v*10 for v in 1:16],4,4)),
        DiagonalOperator(ComplexF64[1.,2.,3.,4.]),
        SparseOperator(reshape(ComplexF64[v%3==0 ? v*3 : 0 for v in 1:16],4,4)),
        SwapLikeOperator(ComplexF64(im)),
    ]

    size_4_operators_ComplexF32=[
        DenseOperator(reshape(ComplexF32[v*10 for v in 1:16],4,4)),
        DiagonalOperator(ComplexF32[1.,2.,3.,4.]),
        SparseOperator(reshape(ComplexF32[v%3==0 ? v*3 : 0 for v in 1:16],4,4)),
        SwapLikeOperator(ComplexF32(im)),
    ]

    for op1 in size_4_operators_ComplexF32
        for op2 in size_4_operators_ComplexF64
            assert_promotion_rules(op1,op2)
        end
    end
end
