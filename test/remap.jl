using Snowflurry
using Test

# Snowflurry uses the The qubit ordering convention used is qubit number 1 on the left, 
# with each following qubit to the right of it.
data_2qubits = Dict{String,Int}("00" => 1, "10" => 20, "01" => 300, "11" => 4000)

data_3qubits = Dict{String,Int}(
    "000" => 1,
    "100" => 20,
    "010" => 300,
    "110" => 4000,
    "001" => 50000,
    "101" => 600000,
    "011" => 7000000,
    "111" => 80000000,
)

test_cases = [
    (data_2qubits, Dict(1 => 1, 2 => 2), data_2qubits)
    (data_2qubits, Dict(2 => 2, 1 => 1), data_2qubits) # out of order
    #
    # single readout, no swaps
    (data_2qubits, Dict(1 => 1), Dict{String,Int}("0" => 301, "1" => 4020))
    (data_2qubits, Dict(2 => 2), Dict{String,Int}("00"=> 21,"01"=> 4300))
    #
    # single readout, with swap
    (data_2qubits, Dict(1 => 2), Dict{String,Int}("0" => 21, "1" => 4300))
    (data_2qubits, Dict(2 => 1), Dict{String,Int}("00" => 301, "01" => 4020))
    (data_2qubits, Dict(3 => 1), Dict{String,Int}("000" => 301, "001" => 4020)) #expanding Hilbert space
    #
    (
        data_2qubits,
        Dict(1 => 2, 2 => 1),
        Dict{String,Int}("00" => 1, "10" => 300, "01" => 20, "11" => 4000),
    ) # symmetric swaps
    #
    (data_3qubits, Dict(1 => 1, 2 => 2, 3 => 3), data_3qubits)
    (data_3qubits, Dict(3 => 3, 2 => 2, 1 => 1), data_3qubits) # out of order
    #
    # single readout, no swaps
    (data_3qubits, Dict(1 => 1), Dict{String,Int}("0" => 7050301, "1" => 80604020))
    (data_3qubits, Dict(2 => 2), Dict{String,Int}("00" => 650021, "01" => 87004300))
    (data_3qubits, Dict(3 => 3), Dict{String,Int}("000" => 4321, "001" => 87650000))
    #
    # single readout, with swap
    (data_3qubits, Dict(1 => 2), Dict{String,Int}("0" => 650021, "1" => 87004300))
    (data_3qubits, Dict(1 => 3), Dict{String,Int}("0" => 4321, "1" => 87650000))
    (data_3qubits, Dict(2 => 3), Dict{String,Int}("00" => 4321, "01" => 87650000))
    # #
    (data_3qubits, Dict(2 => 1), Dict{String,Int}("00" => 7050301, "01" => 80604020))
    (data_3qubits, Dict(3 => 1), Dict{String,Int}("000" => 7050301, "001" => 80604020))
    (data_3qubits, Dict(3 => 2), Dict{String,Int}("000" => 650021, "001" => 87004300))
    #
    # # multiple readouts, single swap
    (
        data_3qubits,
        Dict(1 => 2, 3 => 3),
        Dict{String,Int}("000" => 21, "100" => 4300, "001" => 650000, "101" => 87000000),
    )
    (
        data_3qubits,
        Dict(2 => 3, 1 => 1),
        Dict{String,Int}("00" => 301, "10" => 4020, "01" => 7050000, "11" => 80600000),
    )
    #
    # multiple readouts, multiple swap
    (
        data_3qubits,
        Dict(1 => 2, 2 => 3),
        Dict{String,Int}("00" => 21, "10" => 4300, "01" => 650000, "11" => 87000000),
    )
    (
        data_3qubits,
        Dict(1 => 3, 2 => 2, 3 => 1),
        Dict{String,Int}(
            "000" => 1,
            "100" => 50000,
            "010" => 300,
            "110" => 7000000,
            "001" => 20,
            "101" => 600000,
            "011" => 4000,
            "111" => 80000000,
        ),
    )
]

@testset "remap_counts" begin

    for (input_histogram, readout_bit_to_qubit_map, expected_result) in test_cases

        max_classical_bit = 0
        for (b, ___) in readout_bit_to_qubit_map
            max_classical_bit = maximum([max_classical_bit, b])
        end
        @assert max_classical_bit > 0

        @test Snowflurry.remap_counts(
            input_histogram,
            readout_bit_to_qubit_map,
            max_classical_bit,
        ) == expected_result

    end
end
