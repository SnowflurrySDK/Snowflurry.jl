using Snowflake
using Test

@testset "initial_benchmark_test" begin
    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=3,
        target_qubits=[2,3], sequence_length_list=[2, 4], num_circuits_per_length=[2, 2])
    transpile!(x) = x

    sequence_fidelities = Snowflake.get_sequence_fidelities(simulate_shots, transpile!, 
        properties)
    @test sequence_fidelities == [1.0, 1.0]
end