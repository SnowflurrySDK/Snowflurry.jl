using Snowflurry
using Test

@testset "Readout: getters and Base functions" begin
    test_readout = readout(1)

    @test get_instruction_symbol(test_readout) == "readout"
    @test get_symbol_for_instruction("readout") == Snowflurry.Readout
    @test get_display_symbols(test_readout) == ["✲"]
    @test Snowflurry.get_longest_symbol_length(test_readout) == 1

    expected =
        "Quantum Circuit Object:\n" *
        "   qubit_count: 1 \n" *
        "q[1]:──✲──\n" *
        "          \n" *
        "\n"

    io = IOBuffer()
    print(io, QuantumCircuit(qubit_count = 1, instructions = [test_readout]))
    @test String(take!(io)) == expected

    @test move_instruction(test_readout, Dict{Int,Int}(1 => 2)) == readout(2)

end

@testset "Readout: compare_circuit" begin

    c = QuantumCircuit(qubit_count = 1, instructions = [readout(1), hadamard(1)])

    # cannot assert equivalence if Gate follows readout
    @test_throws ArgumentError compare_circuits(c, c)

    # Readout on separate line doesn't trigger error
    c = QuantumCircuit(qubit_count = 2, instructions = [readout(1), hadamard(2)])

    @test compare_circuits(c, c)

    # Equivalent circuits with identical Readouts are equivalent 
    c0 = QuantumCircuit(
        qubit_count = 2,
        instructions = [sigma_x(1), readout(1), sigma_y(2), readout(2)],
    )
    c1 = QuantumCircuit(
        qubit_count = 2,
        instructions = [x_90(1), x_90(1), readout(1), y_90(2), y_90(2), readout(2)],
    )

    #Identical circuits with different Readouts are not equivalent
    c0 = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), readout(1)])
    c2 = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), readout(2)])

    @test !compare_circuits(c0, c2)
end

@testset "CircuitContainsAReadoutTranspiler" begin
    transpiler = CircuitContainsAReadoutTranspiler()

    c = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), readout(1)])

    transpiled_circuit = transpile(transpiler, c)

    @test isequal(c, transpiled_circuit)

    c = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1)])

    @test_throws ArgumentError transpile(transpiler, c)
end
