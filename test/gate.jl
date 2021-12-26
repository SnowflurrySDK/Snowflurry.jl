using Snowflake
using Test


@testset "gate_set" begin
    H = hadamard(1)
    @test H.instruction_symbol == "ha"
    @test H.display_symbol == ["H"]

    print(H)

    X = sigma_x(1)
    @test X.instruction_symbol == "x"
    @test X.display_symbol == ["X"]

    Y = sigma_y(1)
    @test Y.instruction_symbol == "y"
    @test Y.display_symbol == ["Y"]

    Z = sigma_z(1)
    @test Z.instruction_symbol == "z"
    @test Z.display_symbol == ["Z"]

    CX = control_x(1, 2)
    @test CX.instruction_symbol == "cx"
    
    CZ = control_z(1, 2)
    @test CZ.instruction_symbol == "cz"
end