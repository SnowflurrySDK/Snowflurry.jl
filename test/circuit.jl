using Snowflake
using Test

@testset "push_pop_gate" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [hadamard(1)])
    @test length(c.pipeline) == 1


    push_gate!(c, [control_x(1, 2)])
    @test length(c.pipeline) == 2
    pop_gate!(c)
    @test length(c.pipeline) == 1

    push_gate!(c, control_x(1, 2))
    @test length(c.pipeline) == 2

    plot_histogram(c,100)

    print(c)
end

@testset "reorder_circuit" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [hadamard(1)])
    push_gate!(c, [control_x(1, 2)])
    qubit_map = Dict(1=>3, 2=>1)
    larger_c = get_reordered_circuit(c, qubit_map)
    @test larger_c.pipeline[1][1] ≈ hadamard(3)
    @test larger_c.pipeline[2][1] ≈ control_x(3, 1)
    @test larger_c.qubit_count == 3

    empty_line_c = QuantumCircuit(qubit_count = 4, bit_count = 0)
    push_gate!(empty_line_c, [hadamard(2), hadamard(3)])
    new_empty_line_c = get_reordered_circuit(empty_line_c, Dict(2=>1, 1=>2))
    @test new_empty_line_c.pipeline[1][1] ≈ hadamard(1)
    @test new_empty_line_c.pipeline[1][2] ≈ hadamard(3)
    @test new_empty_line_c.qubit_count == 4

    @test_throws ErrorException get_reordered_circuit(c, Dict(1=>2, 2=>2))
    @test_throws ErrorException get_reordered_circuit(c, Dict(2=>1))
end

@testset "append_circuit" begin
    base_circuit = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(base_circuit, [hadamard(1)])
    circuit_to_append = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(circuit_to_append, [control_x(1, 2)])
    append!(base_circuit, circuit_to_append, circuit_to_append)
    @test base_circuit.pipeline[1][1] ≈ hadamard(1)
    @test base_circuit.pipeline[2][1] ≈ control_x(1, 2)
    @test base_circuit.pipeline[3][1] ≈ control_x(1, 2)

    too_large_circuit = QuantumCircuit(qubit_count = 3, bit_count = 0)
    @test_throws ErrorException append!(base_circuit, too_large_circuit)
end

@testset "get_wider_circuit" begin
    narrow_circuit = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(narrow_circuit, [hadamard(1)])
    num_qubits = 3
    wider_circuit = get_wider_circuit(narrow_circuit, num_qubits)
    @test wider_circuit.qubit_count == 3
    @test wider_circuit.pipeline[1][1] ≈ hadamard(1)
    
    @test_throws ErrorException get_wider_circuit(narrow_circuit, 1)
end


@testset "bellstate" begin

    Ψ_up = spin_up()
    Ψ_down = spin_down()

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [hadamard(1)])
    push_gate!(c, [control_x(1, 2)])
    ψ = simulate(c)
    @test ψ ≈ 1 / sqrt(2.0) * (kron(Ψ_up, Ψ_up) + kron(Ψ_down, Ψ_down))

    readings = simulate_shots(c, 101)
    @test ("00" in readings)
    @test ("11" in readings)
    @test ~("10" in readings)
    @test ~("01" in readings)
end

@testset "phase_kickback" begin

    Ψ_up = spin_up()
    Ψ_down = spin_down()

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)


    c = QuantumCircuit(qubit_count = 2, bit_count = 0)

    push_gate!(c, [hadamard(1), sigma_x(2)])
    push_gate!(c, [hadamard(2)])
    push_gate!(c, [control_x(1, 2)])
    ψ = simulate(c)

    @test ψ ≈ kron(Ψ_m, Ψ_m)
end

@testset "throw_if_gate_outside_circuit" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    @test_throws DomainError push_gate!(c, control_x(1, 3))
end
