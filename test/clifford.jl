using Test
using Snowflake

@testset "get_pauli" begin
    num_qubits = 1
    pauli_x = get_pauli(sigma_x(1), num_qubits)
    another_pauli_x = get_pauli(sigma_x(1), num_qubits)
    outbool = pauli_x == another_pauli_x
    @test outbool

    pauli_eye = get_pauli(identity_gate(1), num_qubits)
    @test !(pauli_eye == pauli_x)
end