using Snowflurry
using Test

@testset "bit_swap" begin

    test_cases = [
        # (inputNum, pos0, pos1, result)
        (4, 3, 3, 4),
        (4, 2, 1, 4),
        (4, 3, 1, 1),
        (4, 3, 2, 2),
        (8, 3, 1, 8),
        (8, 4, 3, 4),
        (7, 3, 2, 7),
    ]

    types = [UInt8, UInt16, UInt32, UInt64, UInt128]

    for (inputNum, pos0, pos1, result) in test_cases
        for t in types
            @test bit_swap(t(inputNum), t(pos0), t(pos1)) == t(result)
        end
    end

    error_cases = [
        # (inputNum, pos0, pos1, result)
        (4, 0, 0),
        (4, 2, 0),
        (4, 0, 2),
    ]

    for (inputNum, pos0, pos1) in error_cases
        for t in types
            @test_throws AssertionError bit_swap(t(inputNum), t(pos0), t(pos1))
        end
    end

end

amps_2qubits = [
    1, #    00
    20, #   01
    300, #  10
    4000, # 11
]

amps_3qubits = [
    1, #        000
    20, #       001
    300, #      010
    4000, #     011
    50000, #    100
    600000, #   101
    7000000, #  110
    80000000, # 111
]

test_cases = [
    (amps_2qubits, Dict(1 => 1, 2 => 2), amps_2qubits)
    (amps_2qubits, Dict(2 => 2, 1 => 1), amps_2qubits) # out of order
    #
    # single readout, no swaps
    (amps_2qubits, Dict(1 => 1), [301, 4020])
    (amps_2qubits, Dict(2 => 2), [21, 0, 4300, 0])
    #
    # single readout, with swap
    (amps_2qubits, Dict(2 => 1), [21, 4300])
    (amps_2qubits, Dict(1 => 2), [301, 0, 4020, 0])
    (amps_2qubits, Dict(1 => 3), [301, 0, 0, 0, 4020, 0, 0, 0]) #expanding Hilbert space
    #
    (amps_2qubits, Dict(1 => 2, 2 => 1), [1, 300, 20, 4000]) # symmetric swaps
    #
    (amps_3qubits, Dict(1 => 1, 2 => 2, 3 => 3), amps_3qubits)
    (amps_3qubits, Dict(3 => 3, 2 => 2, 1 => 1), amps_3qubits) # out of order
    #
    # single readout, no swaps
    (amps_3qubits, Dict(1 => 1), [7050301, 80604020])
    (amps_3qubits, Dict(2 => 2), [650021, 0, 87004300, 0])
    (amps_3qubits, Dict(3 => 3), [4321, 0, 0, 0, 87650000, 0, 0, 0])
    #
    # single readout, with swap
    (amps_3qubits, Dict(2 => 1), [650021, 87004300])
    (amps_3qubits, Dict(3 => 1), [4321, 87650000])
    (amps_3qubits, Dict(3 => 2), [4321, 0, 87650000, 0])
    #
    (amps_3qubits, Dict(1 => 2), [7050301, 0, 80604020, 0])
    (amps_3qubits, Dict(1 => 3), [7050301, 0, 0, 0, 80604020, 0, 0, 0])
    (amps_3qubits, Dict(2 => 3), [650021, 0, 0, 0, 87004300, 0, 0, 0])
    #
    # multiple readouts, single swap
    (amps_3qubits, Dict(2 => 1, 3 => 3), [21, 4300, 0, 0, 650000, 87000000, 0, 0])
    (amps_3qubits, Dict(3 => 2, 1 => 1), [301, 4020, 7050000, 80600000])
    # #
    # multiple readouts, multiple swap
    (amps_3qubits, Dict(2 => 1, 3 => 2), [21, 4300, 650000, 87000000])
    (amps_3qubits, Dict(3 => 2, 2 => 1), [21, 4300, 650000, 87000000])
    (
        amps_3qubits,
        Dict(3 => 1, 2 => 2, 1 => 3),
        [1, 50000, 300, 7000000, 20, 600000, 4000, 80000000],
    )
]

@testset "remap_amplitudes" begin

    for (input_ampls, readouts_target_to_dest_map, expected_result) in test_cases

        max_classical_bit = 0
        for (___, b) in readouts_target_to_dest_map
            max_classical_bit = maximum([max_classical_bit, b])
        end
        @assert max_classical_bit > 0

        @test Snowflurry.remap_amplitudes(
            input_ampls,
            readouts_target_to_dest_map,
            max_classical_bit,
        ) == expected_result

    end
end
