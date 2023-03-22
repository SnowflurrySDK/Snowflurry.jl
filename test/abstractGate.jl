using Snowflake
using Test

@testset "AbstractGate" begin

    nonexistent_gate(target::Integer) = NonExistentGate(target) # to test MethodError on non-implemented AbstractGates

    struct NonExistentGate <: Snowflake.AbstractGate
        target::Int
    end

    target=1

    nonexistent_gate=nonexistent_gate(target)

    @test_throws NotImplementedError Snowflake.get_connected_qubits(nonexistent_gate)

end