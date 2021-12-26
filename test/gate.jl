using Snowflake
using Test

@testset "push_pop_gate" begin
    c = Circuit(qubit_count=2, bit_count=0)
    pushGate!(c, [hadamard(1)])
    @test length(c.pipeline) == 1

    
    pushGate!(c, [control_x(1, 2)])
    @test length(c.pipeline) == 2
    popGate!(c)
    @test length(c.pipeline) == 1

end


@testset "gate_set" begin
    H = hadamard(1)
    @test H.instruction_symbol == "ha"
    @test H.display_symbol == ["H"]

    X = sigma_x(1)
    @test X.instruction_symbol == "x"
    @test X.display_symbol == ["X"]

    Y = sigma_y(1)
    @test Y.instruction_symbol == "y"
    @test Y.display_symbol == ["Y"]

    Z = sigma_z(1)
    @test Z.instruction_symbol == "z"
    @test Z.display_symbol == ["Z"]

end