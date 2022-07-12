using GaloisFields
using Snowflake
using Test

const GF = @GaloisField 2

@testset "clifford_operator" begin
    c = zeros(GF, 4, 4)
    c[1, 1] = 1
    c[1, 2] = 1
    c[2, 2] = 1
    c[3, 3] = 1
    c[4, 3] = 1
    c[4, 4] = 1

    h = zeros(GF, 4)
    h[1] = 1
    h[4] = 1

    clifford = CliffordOperator(c, h)

    expected_c_bar = zeros(GF, 5, 5)
    expected_c_bar[1, 1] = 1
    expected_c_bar[1, 2] = 1
    expected_c_bar[2, 2] = 1
    expected_c_bar[3, 3] = 1
    expected_c_bar[4, 3] = 1
    expected_c_bar[4, 4] = 1
    expected_c_bar[5, 5] = 1

    @test clifford.c_bar == expected_c_bar

    expected_h_bar = zeros(GF, 5)
    expected_h_bar[1] = 1
    expected_h_bar[4] = 1

    @test clifford.h_bar == expected_h_bar
end