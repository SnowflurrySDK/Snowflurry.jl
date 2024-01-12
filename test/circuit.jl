using Snowflurry
using Test

@testset "Constructor: QuantumCircuit" begin
    c = QuantumCircuit(qubit_count = 1)

    @test get_num_qubits(c) == 1
    @test get_num_bits(c) == 1
    @test length(get_circuit_instructions(c)) == 0

    c = QuantumCircuit(qubit_count = 6, bit_count = 2, instructions = [sigma_x(5)])

    @test get_num_qubits(c) == 6
    @test get_num_bits(c) == 2
    @test length(get_circuit_instructions(c)) == 1

    @test_throws DomainError QuantumCircuit(qubit_count = 1, instructions = [sigma_x(5)])

    @test_throws AssertionError(
        "$(:QuantumCircuit) constructor requires qubit_count>0. Received: 0",
    ) QuantumCircuit(qubit_count = 0)
    @test_throws AssertionError(
        "$(:QuantumCircuit) constructor requires qubit_count>0. Received: 0",
    ) QuantumCircuit(qubit_count = 0, bit_count = 2)

    @test_throws AssertionError(
        "$(:QuantumCircuit) constructor requires bit_count>0. Received: 0",
    ) QuantumCircuit(qubit_count = 6, bit_count = 0)
    @test_throws AssertionError(
        "$(:QuantumCircuit) constructor requires bit_count>0. Received: 0",
    ) QuantumCircuit(qubit_count = 6, bit_count = 0, instructions = [sigma_x(5)])
end

@testset "push_pop_gate" begin
    c = QuantumCircuit(qubit_count = 3)
    print(c)
    push!(c, hadamard(1))
    @test length(get_circuit_instructions(c)) == 1

    push!(c, control_x(1, 2))
    @test length(get_circuit_instructions(c)) == 2
    pop!(c)
    @test length(get_circuit_instructions(c)) == 1

    push!(c, control_x(1, 2))
    @test length(get_circuit_instructions(c)) == 2

    print(c)

    push!(c, controlled(swap(2, 3), [1]))
    @test length(get_circuit_instructions(c)) == 3

    print(c)

    append!(c, [sigma_x(2), sigma_y(2)])

    @test_throws DomainError(
        5,
        "The instruction does not fit in the circuit: " * "target qubit: 5, qubit_count: 3",
    ) push!(c, sigma_x(5))
end

@testset "push_pop_readout" begin
    c = QuantumCircuit(qubit_count = 3, bit_count = 2)

    push!(c, readout(3, 2))
    @test length(get_circuit_instructions(c)) == 1

    pop!(c)
    @test length(get_circuit_instructions(c)) == 0

    append!(c, [sigma_x(2), readout(2, 2)])
    @test length(get_circuit_instructions(c)) == 2

    @test_throws DomainError(
        4,
        "The instruction does not fit in the circuit: " * "target qubit: 4, qubit_count: 3",
    ) push!(c, readout(4, 1))

    @test_throws DomainError(
        3,
        "The instruction does not fit in the circuit: " *
        "destination bit: 3, bit_count: 2",
    ) push!(c, readout(1, 3))
end

@testset "print_circuit" begin
    c = QuantumCircuit(qubit_count = 2)
    for i = 1:50
        push!(c, control_x(1, 2))
    end
    print(c)

    c = QuantumCircuit(qubit_count = 10)
    push!(c, control_x(9, 10))
    print(c)

    c = QuantumCircuit(qubit_count = 3)
    push!(c, control_x(1, 3), rotation(2, π, -π / 4), control_z(2, 1))
    print(c)
end


@testset "gate type in circuit" begin
    circuit = QuantumCircuit(qubit_count = 2)
    push!(circuit, hadamard(1))
    push!(circuit, control_x(1, 2))
    push!(circuit, controlled(hadamard(2), [1]))

    println(get_circuit_instructions(circuit))

    @test circuit_contains_gate_type(circuit, Snowflurry.Hadamard)
    @test circuit_contains_gate_type(circuit, Snowflurry.ControlX)
    @test circuit_contains_gate_type(circuit, Snowflurry.Controlled{Snowflurry.Hadamard})

    @test !circuit_contains_gate_type(circuit, Snowflurry.ControlZ)
    @test !circuit_contains_gate_type(circuit, Snowflurry.Swap)
    @test !circuit_contains_gate_type(circuit, Snowflurry.SigmaX)
    @test !circuit_contains_gate_type(circuit, Snowflurry.Controlled{Snowflurry.RotationX})

end


@testset "bellstate" begin

    Ψ_up = spin_up()
    Ψ_down = spin_down()

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)
    c = QuantumCircuit(qubit_count = 2)
    push!(c, hadamard(1))
    push!(c, control_x(1, 2))
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


    c = QuantumCircuit(qubit_count = 2)

    push!(c, hadamard(1), sigma_x(2))
    push!(c, hadamard(2))
    push!(c, control_x(1, 2))
    ψ = simulate(c)

    @test ψ ≈ kron(Ψ_m, Ψ_m)
end

@testset "throw_if_gate_outside_circuit" begin
    c = QuantumCircuit(qubit_count = 2)
    @test_throws DomainError push!(c, control_x(1, 3))
end

@testset "inv" begin
    c = QuantumCircuit(qubit_count = 2)
    push!(c, rotation_x(1, pi / 2))
    push!(c, control_x(1, 2))
    push!(c, swap(1, 2))
    inverse_c = inv(c)

    @test get_instruction_symbol(get_gate_symbol(get_circuit_instructions(inverse_c)[1])) ==
          "swap"
    @test get_connected_qubits(get_circuit_instructions(inverse_c)[1]) == [1, 2]

    @test get_instruction_symbol(get_gate_symbol(get_circuit_instructions(inverse_c)[2])) ==
          "cx"
    @test get_connected_qubits(get_circuit_instructions(inverse_c)[2]) == [1, 2]
    @test get_instruction_symbol(get_gate_symbol(get_circuit_instructions(inverse_c)[3])) ==
          "rx"
    @test get_connected_qubits(get_circuit_instructions(inverse_c)[3]) == [1]
    @test get_gate_parameters(get_gate_symbol(get_circuit_instructions(inverse_c)[3]))["theta"] ≈
          -pi / 2
end

@testset "get_num_gates_per_type" begin
    c = QuantumCircuit(qubit_count = 2)
    push!(c, sigma_x(1), sigma_x(2))
    push!(c, control_x(1, 2))
    push!(c, sigma_x(2))
    gate_counts = get_num_gates_per_type(c)
    @test gate_counts == Dict("cx" => 1, "x" => 3)
end

@testset "get_num_gates" begin
    c = QuantumCircuit(qubit_count = 2)
    push!(c, sigma_x(1), sigma_x(2))
    push!(c, control_x(1, 2))
    push!(c, sigma_x(2))
    num_gates = get_num_gates(c)
    @test num_gates == 4
end

@testset "get_measurement_probabilities" begin
    circuit = QuantumCircuit(qubit_count = 2)
    push!(circuit, hadamard(1), sigma_x(2))
    probabilities = get_measurement_probabilities(circuit)
    @test probabilities ≈ [0, 0.5, 0, 0.5]

    target_qubit = [1]
    probabilities = get_measurement_probabilities(circuit, target_qubit)
    @test probabilities ≈ [0.5, 0.5]

    target_qubit = [2]
    probabilities = get_measurement_probabilities(circuit, target_qubit)
    @test probabilities ≈ [0, 1]
end

@testset "append" begin
    circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(2)])
    wide_circuit = QuantumCircuit(qubit_count = 3)
    @test_throws ErrorException append!(circuit, wide_circuit)

    circuit_2 = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1)])
    circuit_3 = QuantumCircuit(qubit_count = 2, instructions = [hadamard(2)])
    append!(circuit, circuit_2, circuit_3)

    expected_circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [sigma_x(2), sigma_x(1), hadamard(2)],
    )
    @test compare_circuits(circuit, expected_circuit)
end

@testset "prepend" begin
    circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(2)])
    wide_circuit = QuantumCircuit(qubit_count = 3)
    @test_throws ErrorException prepend!(circuit, wide_circuit)

    circuit_2 = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1)])
    circuit_3 = QuantumCircuit(qubit_count = 2, instructions = [hadamard(1)])
    prepend!(circuit, circuit_2, circuit_3)

    expected_circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [sigma_x(1), hadamard(1), sigma_x(2)],
    )
    @test compare_circuits(circuit, expected_circuit)
end

@testset "permute_qubits!" begin
    circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(2), sigma_y(3), sigma_z(1), hadamard(4)],
    )
    map = Dict(1 => 3, 3 => 1, 2 => 5, 5 => 2)
    permute_qubits!(circuit, map)
    expected_circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(5), sigma_y(1), sigma_z(3), hadamard(4)],
    )
    @test compare_circuits(circuit, expected_circuit)

    circuit = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1)])
    map = Dict(1 => 2)
    @test_throws ErrorException permute_qubits!(circuit, map)

    circuit = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1)])
    map = Dict(2 => 1)
    @test_throws ErrorException permute_qubits!(circuit, map)

    circuit = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1)])
    map = Dict(0 => 2)
    @test_throws ErrorException permute_qubits!(circuit, map)

    circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), sigma_y(2)])
    map = Dict(1 => 1, 2 => 1)
    @test_throws ErrorException permute_qubits!(circuit, map)

    circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), sigma_y(2)])
    map = Dict(1 => 2)
    @test_throws ErrorException permute_qubits!(circuit, map)
end

@testset "permute_qubits" begin
    circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(2), sigma_y(3), sigma_z(1), hadamard(4)],
    )
    map = Dict(1 => 3, 3 => 1, 2 => 5, 5 => 2)
    new_circuit = permute_qubits(circuit, map)
    expected_circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(5), sigma_y(1), sigma_z(3), hadamard(4)],
    )
    @test compare_circuits(new_circuit, expected_circuit)
end

@testset "isequal" begin

    c0 = QuantumCircuit(qubit_count = 5, bit_count = 1, instructions = [sigma_x(2)])
    @test isequal(c0, c0) == true

    c1 = QuantumCircuit(qubit_count = 4, bit_count = 1, instructions = [sigma_x(2)])
    @test isequal(c0, c1) == false

    c2 = QuantumCircuit(qubit_count = 5, bit_count = 2, instructions = [sigma_x(2)])
    @test isequal(c0, c2) == false

    c3 = QuantumCircuit(qubit_count = 5, bit_count = 1)
    @test isequal(c0, c3) == false

    c4 = QuantumCircuit(
        qubit_count = 5,
        bit_count = 1,
        instructions = [sigma_x(2), readout(1, 1)],
    )
    @test isequal(c0, c4) == false
end
