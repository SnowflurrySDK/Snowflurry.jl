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
