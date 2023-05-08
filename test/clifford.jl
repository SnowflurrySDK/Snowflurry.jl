using Test
using Snowflake

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
end