using Snowflake
using Test

@testset "initial_benchmark_test" begin
    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=3,
        target_qubits=[2,3], sequence_length_list=[2], num_sequences_per_length=[1])
    transpile!(x) = x
    circuits = Snowflake.get_random_clifford_circuits(1, transpile!, properties)
    shots = simulate_shots(circuits[1], 5)
    @test all(x->(x=="000"), shots)
end