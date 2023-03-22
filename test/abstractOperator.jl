using Snowflake
using Test

@testset "AbstractGate: notImplemented" begin

    nonexistent_gate(target::Integer) = NonExistentGate(target) # to test MethodError on non-implemented AbstractGates

    struct NonExistentGate <: Snowflake.AbstractGate
        target::Int
    end

    target=1

    nonexistent_gate=nonexistent_gate(target)

    @test_throws NotImplementedError Snowflake.get_connected_qubits(nonexistent_gate)

end

@testset "AbstractOperator: math operations" begin

    # mixing AbstractOperator subtypes

    diag_op=DiagonalOperator([1.,2.])
    anti_diag_op=AntiDiagonalOperator([3.,4.])

    @test !isapprox(diag_op,anti_diag_op)
    
    sum_op=diag_op+anti_diag_op

    @test sum_op.data==Matrix{ComplexF64}([[1.,4.] [3.,2.]])
    
    diff_op=diag_op-anti_diag_op

    @test diff_op.data==Matrix{ComplexF64}([[1.,-4.] [-3.,2.]])
    
    @test commute(diag_op,anti_diag_op) ≈ commute(Operator(diag_op),Operator(anti_diag_op))
    @test anticommute(diag_op,anti_diag_op) ≈ anticommute(Operator(diag_op),Operator(anti_diag_op))

    @test kron(diag_op,anti_diag_op)≈ kron(Operator(diag_op),Operator(anti_diag_op))

end
