using Nemo: GF, zero_matrix, identity_matrix
using Snowflake
using Test

@testset "clifford_operator" begin
    c = zero_matrix(GF(2), 4, 4)
    c[1, 1] = 1
    c[1, 2] = 1
    c[2, 2] = 1
    c[3, 3] = 1
    c[4, 3] = 1
    c[4, 4] = 1

    h = zero_matrix(GF(2), 4, 1)
    h[1, 1] = 1
    h[4, 1] = 1

    clifford = get_clifford_operator(c, h)

    expected_c_bar = zero_matrix(GF(2), 5, 5)
    expected_c_bar[1, 1] = 1
    expected_c_bar[1, 2] = 1
    expected_c_bar[2, 2] = 1
    expected_c_bar[3, 3] = 1
    expected_c_bar[4, 3] = 1
    expected_c_bar[4, 4] = 1
    expected_c_bar[5, 5] = 1

    @test clifford.c_bar == expected_c_bar

    expected_h_bar = zero_matrix(GF(2), 5, 1)
    expected_h_bar[1, 1] = 1
    expected_h_bar[4, 1] = 1

    @test clifford.h_bar == expected_h_bar

    non_symplectic_c_bar = zero_matrix(GF(2), 5, 5)
    @test_throws ErrorException CliffordOperator(non_symplectic_c_bar, expected_h_bar)

    c_bar_with_invalid_d = deepcopy(expected_c_bar)
    c_bar_with_invalid_d[5, 1] = 1
    @test_throws ErrorException CliffordOperator(c_bar_with_invalid_d, expected_h_bar)

    clifford_control_x = get_clifford_operator(control_x())
    expected_control_x_c = identity_matrix(GF(2), 4)
    expected_control_x_c[1, 2] = 1
    expected_control_x_c[4, 3] = 1
    @test clifford_control_x.c_bar[1:4, 1:4] == expected_control_x_c
    @test clifford_control_x.h_bar[1:4, 1] == zero_matrix(GF(2), 4, 1)

    random_clifford = get_random_clifford(2)
    @test isa(random_clifford, CliffordOperator)
end

@testset "clifford_operator_manipulations" begin
    c1 = identity_matrix(GF(2), 2)
    h1 = zero_matrix(GF(2), 2, 1)
    h1[1, 1] = 1
    q1 = get_clifford_operator(c1, h1)

    c2 = zero_matrix(GF(2), 2, 2)
    c2[1, 2] = 1
    c2[2, 1] = 1
    h2 = zero_matrix(GF(2), 2, 1)
    q2 = get_clifford_operator(c2, h2)
    
    q21 = q2*q1

    expected_c_bar_21 = zero_matrix(GF(2), 3, 3)
    expected_c_bar_21[1, 2] = 1
    expected_c_bar_21[2, 1] = 1
    expected_c_bar_21[3, 3] = 1

    @test q21.c_bar == expected_c_bar_21

    expected_h_bar_21 = zero_matrix(GF(2), 3, 1)
    expected_h_bar_21[1, 1] = 1
    @test q21.h_bar == expected_h_bar_21

    q3 = get_clifford_operator(c2, h1)
    inv_q3 = inv(q3)
    expected_inv_c_bar = zero_matrix(GF(2), 3, 3)
    expected_inv_c_bar[1, 2] = 1
    expected_inv_c_bar[2, 1] = 1
    expected_inv_c_bar[3, 3] = 1
    @test inv_q3.c_bar == expected_inv_c_bar

    expected_inv_h_bar = zero_matrix(GF(2), 3, 1)
    expected_inv_h_bar[2, 1] = 1
    @test inv_q3.h_bar == expected_inv_h_bar
end

@testset "pauli_group_element" begin
    operator = -im*kron(eye(), kron(sigma_x(), kron(sigma_z(), im*sigma_y())))
    pauli = get_pauli_group_element(operator)
    expected_u = zero_matrix(GF(2), 8, 1)
    expected_u[3, 1] = 1
    expected_u[4, 1] = 1
    expected_u[6, 1] = 1
    expected_u[8, 1] = 1
    expected_delta = 1
    expected_epsilon = 1
    @test pauli.u == expected_u
    @test pauli.delta == expected_delta
    @test pauli.epsilon == expected_epsilon

    @test_throws ErrorException get_pauli_group_element(hadamard())
end

@testset "build_circuit_from_clifford" begin
    gate_1 = kron(hadamard(), kron(eye(), kron(eye(), eye())))
    gate_2 = kron(control_x(), kron(eye(), eye()))
    gate_3 = kron(eye(), kron(control_x(), eye()))
    gate_4 = kron(eye(), kron(eye(), control_x()))
    gate_5 = kron(eye(), kron(eye(), kron(eye(), phase())))
    operator = gate_5*gate_4*gate_3*gate_2*gate_1
    clifford = get_clifford_operator(operator)

    ground_circuit = QuantumCircuit(qubit_count=4, bit_count=0)
    ground_ket = simulate(ground_circuit)
    push_clifford!(ground_circuit, clifford)
    expected_from_ground_ket = adjoint(operator)*ground_ket
    returned_from_ground_ket = simulate(ground_circuit)
    @test expected_from_ground_ket ≈ returned_from_ground_ket

    excited_circuit = QuantumCircuit(qubit_count=4, bit_count=0)
    push_gate!(excited_circuit, [hadamard(1), hadamard(2), hadamard(3), hadamard(4)])
    push_gate!(excited_circuit, [phase(4)])
    excited_ket = simulate(excited_circuit)
    push_clifford!(excited_circuit, clifford)
    expected_from_excited_ket = adjoint(operator)*excited_ket
    returned_from_excited_ket = simulate(excited_circuit)
    @test expected_from_excited_ket ≈ returned_from_excited_ket

    wrong_circuit = QuantumCircuit(qubit_count=3, bit_count=0)
    @test_throws ErrorException push_clifford!(wrong_circuit, clifford)

    one_qubit_operator = hadamard()*phase()*sigma_y()
    one_qubit_clifford = get_clifford_operator(one_qubit_operator)

    one_qubit_x_circuit = QuantumCircuit(qubit_count=1, bit_count=0)
    push_gate!(one_qubit_x_circuit, hadamard(1))
    one_qubit_x_ket = simulate(one_qubit_x_circuit)
    push_clifford!(one_qubit_x_circuit, one_qubit_clifford)
    expected_from_x_ket = adjoint(one_qubit_operator)*one_qubit_x_ket
    returned_from_x_ket = simulate(one_qubit_x_circuit)
    @test expected_from_x_ket ≈ im*returned_from_x_ket

    one_qubit_y_circuit = QuantumCircuit(qubit_count=1, bit_count=0)
    push_gate!(one_qubit_y_circuit, hadamard(1))
    push_gate!(one_qubit_y_circuit, phase(1))
    one_qubit_y_ket = simulate(one_qubit_y_circuit)
    push_clifford!(one_qubit_y_circuit, one_qubit_clifford)
    expected_from_y_ket = adjoint(one_qubit_operator)*one_qubit_y_ket
    returned_from_y_ket = simulate(one_qubit_y_circuit)
    @test expected_from_y_ket ≈ im*returned_from_y_ket
end
