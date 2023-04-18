using Snowflake
using Test

@testset "regression test: gate with qubit out of range of circuit should fail" begin
    @test_throws DomainError QuantumCircuit(qubit_count=1, gates=[sigma_x(5)])
end
