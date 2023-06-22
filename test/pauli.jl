using Test
using Snowflurry

@testset "get_pauli" begin
    num_qubits = 1
    pauli_x = get_pauli(sigma_x(1), num_qubits)
    another_pauli_x = get_pauli(sigma_x(1), num_qubits)
    outbool = pauli_x == another_pauli_x
    @test outbool

    pauli_eye = get_pauli(identity_gate(1), num_qubits)
    @test pauli_eye != pauli_x

    minus_pauli_x = get_pauli(sigma_x(1), num_qubits, negative_exponent=1)
    @test pauli_x != minus_pauli_x

    i_pauli_x = get_pauli(sigma_x(1), num_qubits, imaginary_exponent=1)
    @test pauli_x != i_pauli_x

    @test_throws ErrorException get_pauli(sigma_x(2), num_qubits)
    @test_throws ErrorException get_pauli(sigma_x(1), num_qubits, negative_exponent=-1)
    @test_throws ErrorException get_pauli(sigma_x(1), num_qubits, negative_exponent=2)
    @test_throws ErrorException get_pauli(sigma_x(1), num_qubits, imaginary_exponent=-1)
    @test_throws ErrorException get_pauli(sigma_x(1), num_qubits, imaginary_exponent=2)

    @test_throws NotImplementedError get_pauli(x_90(1), num_qubits)
    @test_throws NotImplementedError get_pauli(QuantumCircuit(qubit_count=2,gates=[hadamard(1)]))
end

@testset "multiply_paulis" begin
    num_qubits = 1
    pauli_eye = get_pauli(identity_gate(1), num_qubits)
    pauli_x = get_pauli(sigma_x(1), num_qubits)
    pauli_y = get_pauli(sigma_y(1), num_qubits)
    pauli_z = get_pauli(sigma_z(1), num_qubits)

    @test pauli_x*pauli_eye == pauli_x
    @test pauli_x*pauli_y == get_pauli(sigma_z(1), num_qubits, imaginary_exponent=1)
    @test pauli_z*pauli_y == get_pauli(sigma_x(1), num_qubits, imaginary_exponent=1,
        negative_exponent=1)

    num_qubits = 2
    pauli_x2 = get_pauli(sigma_x(2), num_qubits)
    @test_throws ErrorException pauli_eye*pauli_x2
end

@testset "get_pauli_using_circuit" begin
    circuit = QuantumCircuit(qubit_count=4, gates=[sigma_z(2), sigma_x(3), sigma_y(4)])
    push!(circuit, identity_gate(2), sigma_z(3))
    pauli = get_pauli(circuit, imaginary_exponent=1, negative_exponent=1)
    
    expected_circuit = QuantumCircuit(qubit_count=4,
        gates=[sigma_z(2), sigma_y(3), sigma_y(4)])
    expected_pauli = get_pauli(expected_circuit)
    @test pauli == expected_pauli
end

@testset "get_quantum_circuit_using_pauli" begin
    circuit = QuantumCircuit(qubit_count=4, gates=[sigma_z(2), sigma_x(3), sigma_y(4)])
    pauli = get_pauli(circuit, imaginary_exponent=1, negative_exponent=1)
    returned_circuit = get_quantum_circuit(pauli)
    @test compare_circuits(circuit, returned_circuit)
end

@testset "get_exponents" begin
    circuit = QuantumCircuit(qubit_count=4, gates=[sigma_z(2), sigma_x(3), sigma_y(4)])
    pauli = get_pauli(circuit, imaginary_exponent=0, negative_exponent=1)
    negative_exponent = get_negative_exponent(pauli)
    @test negative_exponent == 1
    
    imaginary_exponent = get_imaginary_exponent(pauli)
    @test imaginary_exponent == 0
end

@testset "print_pauli" begin
    circuit = QuantumCircuit(qubit_count=4, gates=[sigma_z(2), sigma_x(3), sigma_y(4)])
    pauli = get_pauli(circuit, imaginary_exponent=1, negative_exponent=1)
    print(pauli)
end
