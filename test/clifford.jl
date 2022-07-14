import LinearAlgebra
using Snowflake
using Test

@testset "clifford_operator" begin
    c = zeros(GF2, 4, 4)
    c[1, 1] = 1
    c[1, 2] = 1
    c[2, 2] = 1
    c[3, 3] = 1
    c[4, 3] = 1
    c[4, 4] = 1

    h = zeros(GF2, 4)
    h[1] = 1
    h[4] = 1

    clifford = get_clifford_operator(c, h)

    expected_c_bar = zeros(GF2, 5, 5)
    expected_c_bar[1, 1] = 1
    expected_c_bar[1, 2] = 1
    expected_c_bar[2, 2] = 1
    expected_c_bar[3, 3] = 1
    expected_c_bar[4, 3] = 1
    expected_c_bar[4, 4] = 1
    expected_c_bar[5, 5] = 1

    @test clifford.c_bar == expected_c_bar

    expected_h_bar = zeros(GF2, 5)
    expected_h_bar[1] = 1
    expected_h_bar[4] = 1

    @test clifford.h_bar == expected_h_bar
end

@testset "clifford_operator_manipulations" begin
    c1 = Matrix(GF2(1)*LinearAlgebra.I, 2, 2)
    h1 = zeros(GF2, 2)
    h1[1] = 1
    q1 = get_clifford_operator(c1, h1)

    c2 = zeros(GF2, 2, 2)
    c2[1, 2] = 1
    c2[2, 1] = 1
    h2 = zeros(GF2, 2)
    q2 = get_clifford_operator(c2, h2)
    
    q21 = q2*q1

    expected_c_bar_21 = zeros(GF2, 3, 3)
    expected_c_bar_21[1, 2] = 1
    expected_c_bar_21[2, 1] = 1
    expected_c_bar_21[3, 3] = 1

    @test q21.c_bar == expected_c_bar_21

    expected_h_bar_21 = zeros(GF2, 3)
    expected_h_bar_21[1] = 1
    @test q21.h_bar == expected_h_bar_21
end
