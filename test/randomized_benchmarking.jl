using Snowflake
using Test
using LsqFit

@testset "initial_benchmark_test" begin
    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5],
        num_circuits_per_length=[2, 2, 2, 2, 2])
    transpile!(x) = x

    results = run_randomized_benchmarking(simulate_shots, transpile!, properties)
    @test results.average_clifford_fidelity ≈ 1.0

    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(1))
    results = run_randomized_benchmarking(simulate_shots, transpile!, properties)
    @test isapprox(results.average_clifford_fidelity, 1.0, rtol=1e-3)

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4],
        num_circuits_per_length=[2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(0, [1.0, 3.2]))

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(1, [3.3, 4.1]))

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(2, [3.3, 4.1]))

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(2))


    properties = RandomizedBenchmarkingProperties(
        num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2],
        num_circuits_per_length=[2, 2])
    @test_logs (:warn, "At least 3 sequence lengths are needed to generate a fit! "*
        "No fit will be determined.") run_randomized_benchmarking(simulate_shots,
        transpile!, properties)

    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4],
        num_circuits_per_length=[2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(1))
    @test_logs (:warn,
    "At least 5 sequence lengths are needed to generate a first-order fit! "*
    "A zeroth-order fit will be used instead") run_randomized_benchmarking(simulate_shots,
        transpile!, properties)
end