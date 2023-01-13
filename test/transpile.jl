using Snowflake
using Test


@testset "transpile" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [hadamard(1)])
    push_gate!(c, [control_x(1, 2)])
    transpile(c, ["x", "y", "z", "i", "cz"])

    @test_throws ErrorException transpile(c, ["x", "z", "i", "cz"])
end