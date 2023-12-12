using Snowflurry
using Test

@testset "Readout: getters and Base functions" begin
    readout = Readout(1)

    @test get_instruction_symbol(readout) == "readout"
    @test get_symbol_for_instruction("readout") == Readout
    @test get_display_symbols(readout) == ["▽"]
    @test Snowflurry.get_longest_symbol_length(readout) == 1

    expected =
        "Quantum Circuit Object:\n" *
        "   qubit_count: 1 \n" *
        "q[1]:──▽──\n" *
        "          \n" *
        "\n"

    io = IOBuffer()
    print(io, QuantumCircuit(qubit_count = 1, instructions = [readout]))
    @test String(take!(io)) == expected

    @test move_instruction(readout, Dict{Int,Int}(1 => 2)) == Readout(2)

end
