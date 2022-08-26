using Snowflake
using Test

@testset "randomized_benchmarking" begin
    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5],
        num_circuits_per_length=[2, 2, 2, 2, 2])
    num_shots = 5
    simulator(x) = simulate_shots(x, num_shots)

    results = run_randomized_benchmarking(simulator, properties)
    @test results.average_clifford_fidelity ≈ 1.0

    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(1))
    results = run_randomized_benchmarking(simulator, properties)
    @test isapprox(results.average_clifford_fidelity, 1.0, rtol=1e-3)

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4],
        num_circuits_per_length=[2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(0, Dict("p"=>0.99, "q"=>1.0)))

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(1, Dict("p"=>0.99, "q"=>1.0)))

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(2, Dict("p"=>0.99, "q"=>1.0)))

    @test_throws ErrorException RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4, 5, 6, 7],
        num_circuits_per_length=[2, 2, 2, 2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(2))


    properties = RandomizedBenchmarkingProperties(
        num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2],
        num_circuits_per_length=[2, 2])
    @test_logs (:warn, "At least 3 sequence lengths are needed to generate a fit! "*
        "No fit will be determined.") run_randomized_benchmarking(simulator, properties)

    properties = RandomizedBenchmarkingProperties(num_qubits_on_device=2,
        target_qubits=[1], sequence_length_list=[1, 2, 3, 4],
        num_circuits_per_length=[2, 2, 2, 2],
        fit_properties=RandomizedBenchmarkingFitProperties(1))
    @test_logs (:warn,
    "At least 5 sequence lengths are needed to generate a first-order fit! "*
    "A zeroth-order fit will be used instead") run_randomized_benchmarking(simulator,
        properties)
end

@testset "plot_randomized_benchmarking" begin
    fit_results = RandomizedBenchmarkingFitResults()
    results = RandomizedBenchmarkingResults([1, 2, 3],[0.99, 0.99^2, 0.99^3],
        fit_results, 0.99)
    plot_benchmarking(results)

    fit_results = RandomizedBenchmarkingFitResults(model_order=0,
        parameters=Dict("p"=>0.9, "A0"=>0.99, "B0"=>0.0))
    results = RandomizedBenchmarkingResults([1, 2, 3],[0.9, 0.9^2, 0.9^3],
        fit_results, 0.9)
    plot_benchmarking(results)

    fit_results = RandomizedBenchmarkingFitResults(model_order=1,
        parameters=Dict("p"=>0.9, "q"=>0.9^0.5, "A1"=>0.99, "B1"=>0.0, "C1"=>0.0))
    results = RandomizedBenchmarkingResults([1, 2, 3, 4, 5],
        [0.9, 0.9^2, 0.9^3, 0.9^4, 0.9^5],
        fit_results, 0.9)
    plot_benchmarking(results)
end