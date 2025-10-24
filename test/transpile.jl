using Snowflurry
using Test

include("mock_functions.jl")

target = 1
destination_bit = 1

default_readout = readout(target, destination_bit)

theta = π / 5
phi = π / 7
lambda = π / 9

single_qubit_instructions = [
    identity_gate(target),
    hadamard(target),
    phase_shift(target, -phi / 2),
    pi_8(target),
    pi_8_dagger(target),
    rotation(target, theta, phi),
    rotation_x(target, theta),
    rotation_y(target, theta),
    rotation_z(target, theta),
    sigma_x(target),
    sigma_y(target),
    sigma_z(target),
    universal(target, theta, phi, lambda),
    x_90(target),
    x_minus_90(target),
    y_90(target),
    y_minus_90(target),
    z_90(target),
    z_minus_90(target),
]

test_instructions = [
    [
        sigma_x(1),
        sigma_y(1),
        identity_gate(1),
        hadamard(2),
        control_x(1, 3),
        sigma_x(2),
        sigma_y(2),
        controlled(sigma_x(4), [1]),
        hadamard(2),
        sigma_z(1),
        sigma_x(4),
        sigma_y(4),
        toffoli(1, 2, 3),
        hadamard(4),
        sigma_z(2),
    ],
    [   # all gates are `boundaries`
        control_x(1, 3),
        control_x(4, 2),
        control_x(1, 4),
        toffoli(1, 4, 3),
        swap(2, 4),
        iswap(4, 1),
        iswap_dagger(1, 3),
        root_zz(1, 2),
        root_zz_dagger(1, 3),
    ],
]

@testset "as_universal_gate" begin
    for instr in single_qubit_instructions
        universal_equivalent =
            Snowflurry.as_universal_gate(target, get_operator(get_gate_symbol(instr)))

        @test Snowflurry.compare_operators(
            get_operator(get_gate_symbol(instr)),
            get_operator(get_gate_symbol(universal_equivalent)),
        )
    end

    # Operations with rounding errors
    threshold = 1e-12
    operator = DenseOperator([
        1.0+threshold 0.0
        0.0 1.0
    ])
    universal_equivalent = Snowflurry.as_universal_gate(target, operator)
    @test Snowflurry.compare_operators(
        operator,
        get_operator(get_gate_symbol(universal_equivalent)),
    )
end

@testset "CompressSingleQubitGatesTranspiler" begin

    transpiler = CompressSingleQubitGatesTranspiler()

    # attempt compression of all pairs of single qubit gates
    for first_gate in single_qubit_instructions
        for second_gate in single_qubit_instructions
            circuit = QuantumCircuit(
                qubit_count = 2,
                instructions = [first_gate, second_gate],
                name = "test-name",
            )

            transpiled_circuit = transpile(transpiler, circuit)

            gates = get_circuit_instructions(transpiled_circuit)

            @test length(gates) == 1

            @test compare_circuits(circuit, transpiled_circuit)
            @test gates[1] isa Snowflurry.Gate{Snowflurry.Universal}

            # presence of Readout should have no effect on transpilation
            circuit_with_readout = QuantumCircuit(
                qubit_count = 2,
                instructions = [first_gate, second_gate, default_readout],
            )

            transpiled_circuit = transpile(transpiler, circuit_with_readout)

            @test compare_circuits(circuit_with_readout, transpiled_circuit)
            @test length(get_circuit_instructions(transpiled_circuit)) == 2
            @test gates[1] isa Snowflurry.Gate{Snowflurry.Universal}
        end
    end

    # attempt empty circuit
    circuit = QuantumCircuit(qubit_count = 2, name = "test-name")

    transpiled_circuit = transpile(transpiler, circuit)

    gates = get_circuit_instructions(transpiled_circuit)

    @test length(gates) == 0

    # circuit with single gate is unchanged
    circuit =
        QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1)], name = "test-name")

    transpiled_circuit = transpile(transpiler, circuit)

    gates = get_circuit_instructions(transpiled_circuit)

    @test length(gates) == 1

    @test circuit_contains_gate_type(transpiled_circuit, Snowflurry.SigmaX)

    # circuit with single gate and boundary is unchanged
    circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [sigma_x(1), control_x(1, 2)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    gates = get_circuit_instructions(transpiled_circuit)

    @test length(gates) == 2

    @test gates[1] isa Snowflurry.Gate{Snowflurry.SigmaX}
    @test gates[2] isa Snowflurry.Gate{Snowflurry.ControlX}
end

@testset "Transpiler" begin
    struct NonExistentTranspiler <: Transpiler end

    @test_throws NotImplementedError transpile(
        NonExistentTranspiler(),
        QuantumCircuit(qubit_count = 2),
    )
end

@testset "Compress to Universal: basic transpilation" begin

    transpiler = CompressSingleQubitGatesTranspiler()

    input_gate = sigma_x(1)

    #compressing single input gate does nothing
    circuit =
        QuantumCircuit(qubit_count = 2, instructions = [input_gate], name = "test-name")

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

    #compressing gates on different targets does nothing
    circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [sigma_x(1), sigma_x(2)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

    #compressing one single and one multi target gates does nothing
    circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [sigma_x(1), control_x(1, 2)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

    #compressing one gate and one readout does nothing
    circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), default_readout])

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

    circuit =
        QuantumCircuit(qubit_count = 2, instructions = [control_x(1, 2), default_readout])

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)
end

@testset "Compress to Universal: transpilation of single and multiple target gates" begin

    qubit_count = 4
    transpiler = CompressSingleQubitGatesTranspiler()

    test_instr_with_readout = Vector{Vector{AbstractInstruction}}()
    push!(test_instr_with_readout, test_instructions[1])
    push!(test_instr_with_readout, vcat(test_instructions[2], [default_readout]))

    for gates_list in test_instr_with_readout
        for end_pos ∈ 1:length(gates_list)

            truncated_input = gates_list[1:end_pos]

            circuit = QuantumCircuit(
                qubit_count = qubit_count,
                instructions = truncated_input,
                name = "test-name",
            )

            transpiled_circuit = transpile(transpiler, circuit)

            @test compare_circuits(circuit, transpiled_circuit)
        end
    end
end


@testset "CastUniversalToRzRxRzTranspiler" begin

    qubit_count = 2
    target = 1
    transpiler = CastUniversalToRzRxRzTranspiler()

    list_params = [
        #theta,     phi,    lambda, gates_in_output
        (pi / 13, pi / 3, pi / 5, 3),
        (pi / 13, pi / 3, 0, 3),
        (pi / 13, 0, pi / 5, 3),
        (pi / 13, 0, 0, 3),
        (0, pi / 3, pi / 5, 3),
        (0, pi / 3, 0, 3),
        (0, 0, pi / 5, 3),
        (0, 0, 0, 3),
    ]

    for (theta, phi, lambda, gates_in_output) in list_params

        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = [universal(target, theta, phi, lambda)],
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        gates = get_circuit_instructions(transpiled_circuit)

        @test length(gates) == gates_in_output

        @test gates[1] isa Snowflurry.Gate{Snowflurry.PhaseShift}
        @test gates[2] isa Snowflurry.Gate{Snowflurry.RotationX}
        @test gates[3] isa Snowflurry.Gate{Snowflurry.PhaseShift}

        @test compare_circuits(circuit, transpiled_circuit)
    end

    #from non-Universal gate
    circuit = QuantumCircuit(
        qubit_count = qubit_count,
        instructions = [sigma_x(target)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

    #from single and multiple-target gates
    circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [universal(1, π / 2, π / 4, π / 8), control_x(1, 2)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

end

@testset "cast_Rx_to_Rz_and_half_rotation_x" begin

    qubit_count = 2
    target = 1
    transpiler = CastRxToRzAndHalfRotationXTranspiler()

    list_params = [
        #theta,     
        π,
        π / 2,
        π / 4,
        π / 8,
        π / 6,
    ]

    for theta in list_params
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = [rotation_x(target, theta)],
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        @test compare_circuits(circuit, transpiled_circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.RotationX)

        gates = get_circuit_instructions(transpiled_circuit)

        @test length(gates) == 5

        @test gates[1] isa Snowflurry.Gate{Snowflurry.Z90}
        @test gates[2] isa Snowflurry.Gate{Snowflurry.X90}
        @test gates[3] isa Snowflurry.Gate{Snowflurry.PhaseShift}
        @test gates[4] isa Snowflurry.Gate{Snowflurry.XM90}
        @test gates[5] isa Snowflurry.Gate{Snowflurry.ZM90}
    end
end

@testset "cast_Rx_to_Rz_and_half_rotation_x: trivial cases" begin
    qubit_count = 2
    transpiler = CastRxToRzAndHalfRotationXTranspiler()

    for instr in vcat(single_qubit_instructions, [default_readout])
        if instr isa Gate{Snowflurry.RotationX}
            continue
        end

        circuit = QuantumCircuit(qubit_count = qubit_count, instructions = [instr])

        transpiled_circuit = transpile(transpiler, circuit)

        # transpiler does nothing on non-RotationX gates
        @test isequal(circuit, transpiled_circuit)
    end
end

@testset "cast_to_phase_shift_and_half_rotation_x: from universal" begin

    qubit_count = 2
    target = 1
    transpiler = CastToPhaseShiftAndHalfRotationXTranspiler()

    list_params = [
        #theta,     phi,    lambda, gates_in_output
        (pi / 13, pi / 3, pi / 5, 5),
        (pi / 13, pi / 3, 0, 4),
        (pi / 13, 0, pi / 5, 4),
        (pi / 13, 0, 0, 3),
        (0, pi / 3, pi / 5, 2),
        (0, pi / 3, 0, 1),
        (0, 0, pi / 5, 1),
        (0, 0, 0, 0),
    ]

    for (theta, phi, lambda, gates_in_output) in list_params
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = [universal(target, theta, phi, lambda)],
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        gates = get_circuit_instructions(transpiled_circuit)

        @test length(gates) == gates_in_output

        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_phase_shift_and_half_rotation_x: from any single_qubit_gates" begin

    qubit_count = 2
    target = 1
    transpiler = CastToPhaseShiftAndHalfRotationXTranspiler()

    for instr in vcat(single_qubit_instructions, [default_readout])

        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = [instr],
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        @test compare_circuits(circuit, transpiled_circuit)
    end

    circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [universal(1, 1e-3, 1e-3, 1e-3)],
        name = "test-name",
    )

    # with default tolerance        
    transpiled_circuit_default_tol = transpile(transpiler, circuit)

    @test length(get_circuit_instructions(transpiled_circuit_default_tol)) == 5

    # with user-defined tolerance
    transpiler = CastToPhaseShiftAndHalfRotationXTranspiler(1e-1)

    transpiled_circuit_high_tol = transpile(transpiler, circuit)

    @test length(get_circuit_instructions(transpiled_circuit_high_tol)) == 0

end

@testset "SwapQubitsForAdjacencyTranspiler{LineConnectivity}" begin

    qubit_count = 10
    transpiler = SwapQubitsForAdjacencyTranspiler(LineConnectivity(qubit_count))


    test_specs = [
        # (gates list       gates_in_output)
        ([swap(2, 3)], 1),          # no effect
        ([swap(2, 8)], 11),
        ([swap(8, 2)], 11),
        ([iswap(2, 3)], 1),         # no effect
        ([iswap(2, 8)], 11),
        ([iswap(8, 2)], 11),
        ([control_z(5, 6)], 1),     # no effect
        ([control_z(5, 10)], 9),    # target at bottom
        ([control_z(10, 1)], 17),   # target on top
        ([toffoli(4, 5, 6)], 1),    # no effect
        ([toffoli(4, 6, 5)], 1),    # no effect
        ([toffoli(6, 5, 4)], 1),    # no effect
        ([toffoli(4, 6, 2)], 7),    # target on top
        ([toffoli(2, 6, 4)], 7),    # target in middle
        ([toffoli(1, 3, 6)], 9),    # target at bottom
        ([toffoli(5, 10, 2)], 17),  # larger distance
        ([control_z(10, 1), toffoli(2, 4, 8)], 28), # sequence of gates
    ]

    for (input_gates, gates_in_output) in test_specs
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = input_gates,
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        gates = get_circuit_instructions(transpiled_circuit)

        @test length(gates) == gates_in_output

        if !(compare_circuits(circuit, transpiled_circuit))
            println("gates in input: $(get_circuit_instructions(circuit))")
        end

        @test compare_circuits(circuit, transpiled_circuit)

    end

end


@testset "SwapQubitsForAdjacencyTranspiler{LatticeConnectivity}" begin

    nrows = 4
    ncols = 3
    qubit_count = nrows * ncols
    transpiler = SwapQubitsForAdjacencyTranspiler(LatticeConnectivity(nrows, ncols))

    # LatticeConnectivity{4,3}
    #         1 
    #         | 
    #   7 ──  4 ──  2 
    #   |     |     | 
    #  10 ──  8 ──  5 ──  3 
    #         |     |     | 
    #        11 ──  9 ──  6 
    #               | 
    #              12 

    test_specs = [
        # (gates list       gates_in_output)
        ([swap(4, 1)], 1),          # no effect
        ([swap(1, 8)], 3),
        ([swap(8, 1)], 3),
        ([iswap(4, 1)], 1),         # no effect
        ([iswap(1, 8)], 3),
        ([iswap(8, 1)], 3),
        ([control_z(5, 2)], 1),     # no effect
        ([control_z(5, 1)], 5),     # target at bottom
        ([control_z(1, 6)], 9),     # target on top
        ([toffoli(7, 4, 2)], 1),    # no effect
        ([toffoli(7, 2, 4)], 1),    # no effect
        ([toffoli(2, 4, 7)], 1),    # no effect
        ([toffoli(7, 2, 1)], 3),    # 1 swap required
        ([toffoli(1, 2, 7)], 3),    # 1 swap required
        ([toffoli(7, 2, 5)], 5),    # 1 swap required on 2 targets
        ([toffoli(7, 5, 2)], 5),    # 1 swap required on 2 targets
        ([toffoli(7, 8, 11)], 5),   # 1 swap required on 2 targets
        ([toffoli(7, 11, 8)], 5),   # 1 swap required on 2 targets
        ([toffoli(6, 11, 2)], 7),   # 1 swap required on 2 targets
        ([toffoli(6, 10, 7)], 13),  # 3 swap required on 2 targets
        ([control_z(1, 6), toffoli(1, 7, 8)], 12), # sequence of gates
    ]

    for (input_gates, gates_in_output) in test_specs
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = input_gates,
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        gates = get_circuit_instructions(transpiled_circuit)

        @test length(gates) == gates_in_output

        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "SwapQubitsForAdjacencyTranspiler{LatticeConnectivity}: update qubit count" begin

    nrows = 4
    ncols = 3
    transpiler = SwapQubitsForAdjacencyTranspiler(LatticeConnectivity(nrows, ncols))

    # LatticeConnectivity{4,3}
    #        1 
    #        | 
    #  7 ──  4 ──  2 
    #  |     |     | 
    # 10 ──  8 ──  5 ──  3 
    #        |     |     | 
    #       11 ──  9 ──  6 
    #              | 
    #             12 

    circuit = QuantumCircuit(
        qubit_count = 3,
        instructions = [control_z(1, 2)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    gates = get_circuit_instructions(transpiled_circuit)

    @test length(gates) == 3

    new_qubit_count = 4
    larger_original_circuit = update_circuit_qubit_count(circuit, new_qubit_count)
    @test compare_circuits(larger_original_circuit, transpiled_circuit)
end

@testset "SwapQubitsForAdjacencyTranspiler{LatticeConnectivity}: excluded_positions" begin

    nrows = 4
    ncols = 3
    qubit_count = nrows * ncols
    transpiler = SwapQubitsForAdjacencyTranspiler(LatticeConnectivity(nrows, ncols, [4, 5]))

    # LatticeConnectivity{4,3}
    #         4 ──  1 
    #         |     | 
    #  10 ──  7 ──  5 ──  2 
    #         |     |     | 
    #        11 ──  8 ──  6 ──  3 
    #               |     | 
    #              12 ──  9 

    success_cases = [
        # (gates list       gates_in_output)
        ([swap(10, 7)], 1),          # no effect
        ([swap(10, 11)], 3),
        ([swap(11, 12)], 3),
    ]

    failure_cases = [[swap(1, 7)], [swap(1, 8)], [swap(1, 2)]]

    for (input_gates, gates_in_output) in success_cases
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = input_gates,
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        gates = get_circuit_instructions(transpiled_circuit)

        @test length(gates) == gates_in_output

        @test compare_circuits(circuit, transpiled_circuit)
    end

    for input_gates in failure_cases
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = input_gates,
            name = "test-name",
        )

        @test_throws AssertionError(
            "cannot find path on connectivity given excluded positions",
        ) transpile(transpiler, circuit)
    end
end


@testset "SwapQubitsForAdjacencyTranspiler: multi-target multi-parameter" begin

    struct MultiParamMultiTargetGateSymbol <: Snowflurry.AbstractGateSymbol
        theta::Real
        phi::Real
    end

    Snowflurry.get_num_connected_qubits(gate::MultiParamMultiTargetGateSymbol) = 3
    Snowflurry.get_gate_parameters(gate::MultiParamMultiTargetGateSymbol) =
        Dict("theta" => gate.theta, "phi" => gate.phi)
    Snowflurry.get_operator(
        gate::MultiParamMultiTargetGateSymbol,
        T::Type{<:Complex} = ComplexF64,
    ) = DenseOperator(
        T[
            1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
            0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0
            0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0
            0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0
            0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0
            0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0
            0.0 0.0 0.0 0.0 0.0 0.0 0.0 cos(gate.theta)
            0.0 0.0 0.0 0.0 0.0 0.0 cos(gate.phi) 0.0
        ],
    )

    Snowflurry.gates_display_symbols[MultiParamMultiTargetGateSymbol] =
        ["*", "x", "MM(θ=%s,phi=%s)", "theta", "phi"]

    Snowflurry.instruction_symbols[MultiParamMultiTargetGateSymbol] = "mm"

    qubit_count = 6
    nrows = 2
    ncols = 3
    circuit = QuantumCircuit(
        qubit_count = qubit_count,
        instructions = [Gate(MultiParamMultiTargetGateSymbol(π, π / 3), [1, 3, 5])],
        name = "test-name",
    )

    # test printout for multi-target multi-param gate
    io = IOBuffer()
    println(io, "circuit: $circuit")
    @test String(take!(io)) ==
          "circuit: Quantum Circuit Object:\n" *
          "   qubit_count: 6 \n" *
          "   bit_count: 6 \n" *
          "q[1]:─────────────*─────────────\n" *
          "                  |             \n" *
          "q[2]:─────────────|─────────────\n" *
          "                  |             \n" *
          "q[3]:─────────────x─────────────\n" *
          "                  |             \n" *
          "q[4]:─────────────|─────────────\n" *
          "                  |             \n" *
          "q[5]:──MM(θ=3.1416,phi=1.0472)──\n" *
          "                                \n" *
          "q[6]:───────────────────────────\n" *
          "                                \n\n\n"

    transpilers = [
        SwapQubitsForAdjacencyTranspiler(LineConnectivity(qubit_count)),
        SwapQubitsForAdjacencyTranspiler(LatticeConnectivity(nrows, ncols)),
        SwapQubitsForAdjacencyTranspiler(LatticeConnectivity(ncols, nrows)),
    ]

    for transpiler in transpilers
        transpiled_circuit = transpile(transpiler, circuit)
        @test compare_circuits(circuit, transpiled_circuit)
    end


end

@testset "AnyonYukonQPU: transpilation of native gates" begin
    requestor = MockRequestor(
        stub_response_sequence([stubMetadataResponse(yukonMetadata)]),
        make_post_checker(expected_json_yukon),
    )
    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )

    qubit_count = 2
    target = 1
    control = 2

    transpiler = get_transpiler(qpu)

    input_gates_native = [
        identity_gate(target),
        phase_shift(target, -phi / 2),
        pi_8(target),
        pi_8_dagger(target),
        sigma_x(target),
        sigma_y(target),
        sigma_z(target),
        x_90(target),
        x_minus_90(target),
        y_90(target),
        y_minus_90(target),
        z_90(target),
        z_minus_90(target),
        control_z(control, target),
        controlled(sigma_z(target), [control]),
    ]

    input_gates_foreign = [
        hadamard(target),
        rotation(target, theta, phi),
        rotation_x(target, theta),
        rotation_y(target, theta),
        root_zz(target, control),
    ]

    for (gates_list, input_is_native) in
        vcat((input_gates_native, true), (input_gates_foreign, false))
        for gate in gates_list

            circuit = QuantumCircuit(
                qubit_count = qubit_count,
                instructions = [gate, default_readout],
                name = "test-name",
            )
            transpiled_circuit = transpile(transpiler, circuit)

            @test compare_circuits(circuit, transpiled_circuit)

            instructions_in_output = get_circuit_instructions(transpiled_circuit)

            if input_is_native
                # at most one non-Rz gate
                count_of_non_rz_gates = 0

                for instr in instructions_in_output
                    if !(instr isa Snowflurry.Readout) &&
                       !(typeof(get_gate_symbol(instr)) in Snowflurry.set_of_rz_gates)
                        count_of_non_rz_gates += 1
                    end
                end

                @test count_of_non_rz_gates <= 1
            end

            for gate in instructions_in_output
                @test is_native_instruction(gate, Snowflurry.AnyonYukonConnectivity)
            end
        end
    end
end

@testset "AnyonYukonQPU: sequential transpilation" begin
    requestor = MockRequestor(
        stub_response_sequence([stubMetadataResponse(yukonMetadata)]),
        make_post_checker(expected_json_yukon),
    )
    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )
    transpiler = get_transpiler(qpu)

    qubit_count = 4

    for gates_list in test_instructions
        for end_pos ∈ 1:length(gates_list)
            truncated_input = vcat(gates_list[1:end_pos], [default_readout])
            circuit = QuantumCircuit(
                qubit_count = qubit_count,
                instructions = truncated_input,
                name = "test-name",
            )
            transpiled_circuit = transpile(transpiler, circuit)
            @test compare_circuits(circuit, transpiled_circuit)
        end
    end
end

@testset "AnyonYukonQPU: transpilation of a Ghz circuit" begin
    requestor = MockRequestor(
        stub_response_sequence([stubMetadataResponse(yukonMetadata)]),
        make_post_checker(expected_json_yukon),
    )
    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )

    qubit_count = 5

    transpiler = get_transpiler(qpu)

    circuit = QuantumCircuit(
        qubit_count = qubit_count,
        instructions = vcat(
            hadamard(1),
            [control_x(i, i + 1) for i ∈ 1:(qubit_count-1)],
            [default_readout],
        ),
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    results = Dict{Int,Vector{DataType}}([])

    for instr in get_circuit_instructions(transpiled_circuit)
        if instr isa Snowflurry.Readout
            continue
        end

        targets = get_connected_qubits(instr)

        for target in targets
            if haskey(results, target)
                results[target] = push!(results[target], typeof(get_gate_symbol(instr)))
            else
                results[target] = [typeof(get_gate_symbol(instr))]
            end
        end
    end

    for (target, gates_array_per_target) in results

        if target == 1
            @test gates_array_per_target ==
                  [Snowflurry.Z90, Snowflurry.X90, Snowflurry.Z90, Snowflurry.ControlZ]
        elseif target == qubit_count
            @test gates_array_per_target == [
                Snowflurry.Z90,
                Snowflurry.X90,
                Snowflurry.Z90,
                Snowflurry.ControlZ,
                Snowflurry.Z90,
                Snowflurry.X90,
                Snowflurry.Z90,
            ]
        else
            @test gates_array_per_target == [
                Snowflurry.Z90,
                Snowflurry.X90,
                Snowflurry.Z90,
                Snowflurry.ControlZ,
                Snowflurry.Z90,
                Snowflurry.X90,
                Snowflurry.Z90,
                Snowflurry.ControlZ,
            ]
        end
    end
end

@testset "AnyonQPUs: SwapQubitsForAdjacencyTranspiler: full connectivity" begin
    qpus_and_connectivities = [
        (
            AnyonYukonQPU(;
                host = expected_host,
                user = expected_user,
                access_token = expected_access_token,
                project_id = expected_project_id,
            ),
            Snowflurry.AnyonYukonConnectivity,
        )
        (
            AnyonYamaskaQPU(;
                host = expected_host,
                user = expected_user,
                access_token = expected_access_token,
                project_id = expected_project_id,
            ),
            # testing with LatticeConnectivity(6,4) induces massive demand on simulate(), with 24-qubit Kets
            Snowflurry.LatticeConnectivity(3, 4),
        )
    ]

    for (qpu, connectivity) in qpus_and_connectivities
        transpiler = Snowflurry.get_anyon_transpiler(connectivity = connectivity)
        qubit_count = get_num_qubits(connectivity)

        for t_0 ∈ 1:qubit_count
            for t_1 ∈ 1:qubit_count
                if t_0 == t_1
                    continue
                end
                circuit = QuantumCircuit(
                    qubit_count = qubit_count,
                    instructions = [control_z(t_0, t_1), default_readout],
                    name = "test-name",
                )
                transpiled_circuit = transpile(transpiler, circuit)
                @test compare_circuits(circuit, transpiled_circuit)

                instructions_in_output = get_circuit_instructions(transpiled_circuit)

                for instr in instructions_in_output
                    connected_qubits = get_connected_qubits(instr)
                    if length(connected_qubits) > 1
                        (t_2, t_3) = connected_qubits

                        #confirm adjacency
                        @test get_qubits_distance(t_2, t_3, connectivity) == 1
                    end
                end
            end
        end
    end
end

@testset "SequentialTranspiler: compress and cast_to_phase_shift_and_half_rotation_x" begin

    transpiler = SequentialTranspiler([
        CompressSingleQubitGatesTranspiler(),
        CastToPhaseShiftAndHalfRotationXTranspiler(),
    ])

    qubit_count = 4

    for gates_list in test_instructions
        for end_pos ∈ 1:length(gates_list)

            truncated_input = gates_list[1:end_pos]

            circuit = QuantumCircuit(
                qubit_count = qubit_count,
                instructions = truncated_input,
                name = "test-name",
            )

            transpiled_circuit = transpile(transpiler, circuit)

            @test compare_circuits(circuit, transpiled_circuit)
        end
    end
end

@testset "cast_to_cz: unknown gate" begin
    struct UnknownCastToCZGateSymbol <: AbstractGateSymbol end
    symbol = UnknownCastToCZGateSymbol()

    @test_throws NotImplementedError Snowflurry.cast_to_cz(symbol, [1, 2])
end

@testset "cast_to_cz: swap" begin
    transpiler = CastSwapToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count = 2, instructions = [swap(1, 2)], name = "test-name-1"),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [swap(1, 2), x_90(1), swap(1, 2)],
            name = "test-name-2",
        ),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [iswap(1, 2), swap(1, 2)],
            name = "test-name-3",
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "CastSwapToCZGateTranspiler: Readout" begin
    transpiler = CastSwapToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count = 2, instructions = [default_readout]),
        QuantumCircuit(qubit_count = 2, instructions = [swap(1, 2), default_readout]),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [swap(1, 2), x_90(1), swap(1, 2), default_readout],
        ),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [iswap(1, 2), swap(1, 2), default_readout],
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "CastCXToCZGateTranspiler: cx" begin
    transpiler = CastCXToCZGateTranspiler()

    circuits = [
        QuantumCircuit(
            qubit_count = 2,
            instructions = [control_x(1, 2)],
            name = "test-name-1",
        ),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [control_x(1, 2), x_90(1), control_x(1, 2)],
            name = "test-name-2",
        ),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [iswap(1, 2), control_x(1, 2)],
            name = "test-name-3",
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.ControlX)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "CastCXToCZGateTranspiler: Readout" begin
    transpiler = CastCXToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count = 2, instructions = [default_readout]),
        QuantumCircuit(qubit_count = 2, instructions = [control_x(1, 2), default_readout]),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [control_x(1, 2), x_90(1), control_x(1, 2), default_readout],
        ),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [iswap(1, 2), control_x(1, 2), default_readout],
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.ControlX)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "CastISwapToCZGateTranspiler: iswap" begin
    transpiler = CastISwapToCZGateTranspiler()

    instructions = [
        [iswap(1, 2)],
        [iswap_dagger(1, 2)],
        [iswap(1, 2), x_90(1), iswap(1, 2)],
        [iswap(1, 2), x_90(1), iswap_dagger(1, 2)],
        [iswap_dagger(1, 2), x_90(1), iswap(1, 2)],
        [control_x(1, 2), iswap(1, 2)],
        [control_x(1, 2), iswap_dagger(1, 2)],
    ]

    for instrs in instructions
        circuit = QuantumCircuit(qubit_count = 2, instructions = instrs)

        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.ISwap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "CastISwapToCZGateTranspiler: Readout" begin
    transpiler = CastISwapToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count = 2, instructions = [default_readout]),
        QuantumCircuit(qubit_count = 2, instructions = [iswap(1, 2), default_readout]),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [iswap(1, 2), x_90(1), iswap(1, 2), default_readout],
        ),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [control_x(1, 2), iswap(1, 2), default_readout],
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.ISwap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_cx: toffoli" begin
    transpiler = CastToffoliToCXGateTranspiler()

    circuits = [
        QuantumCircuit(
            qubit_count = 3,
            instructions = [toffoli(1, 2, 3), iswap(1, 2), toffoli(2, 1, 3)],
            name = "test-name-1",
        ),
        QuantumCircuit(
            qubit_count = 3,
            instructions = [toffoli(1, 3, 2), x_90(1), toffoli(2, 3, 1)],
            name = "test-name-2",
        ),
        QuantumCircuit(
            qubit_count = 3,
            instructions = [toffoli(3, 1, 2), control_x(1, 2), toffoli(3, 2, 1)],
            name = "test-name-3",
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Toffoli)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_cx: Toffoli and Readout" begin
    transpiler = CastToffoliToCXGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count = 2, instructions = [default_readout]),
        QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), default_readout]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "SequentialTranspiler: compress, cast_to_Rz_and_half_Rx and Place" begin

    qubit_count = 6

    transpiler = SequentialTranspiler([
        CompressSingleQubitGatesTranspiler(),
        CastToPhaseShiftAndHalfRotationXTranspiler(),
        SwapQubitsForAdjacencyTranspiler(LineConnectivity(qubit_count)),
    ])

    test_inputs = [
        toffoli(4, 6, 2),
        sigma_x(1),
        sigma_y(1),
        sigma_y(4),
        control_z(5, 1),
        hadamard(1),
        sigma_x(4),
        default_readout,
    ]

    test_inputs = vcat(test_instructions, [test_inputs])

    for input_gates in test_inputs
        for end_pos ∈ 1:length(input_gates)

            truncated_input = input_gates[1:end_pos]

            circuit = QuantumCircuit(
                qubit_count = qubit_count,
                instructions = truncated_input,
                name = "test-name",
            )

            transpiled_circuit = transpile(transpiler, circuit)

            @test compare_circuits(circuit, transpiled_circuit)
        end
    end
end


@testset "simplify_rx_gate" begin

    list_params = [
        (pi / 2, Snowflurry.X90),
        (-pi / 2, Snowflurry.XM90),
        (pi, Snowflurry.SigmaX),
        (pi / 3, Snowflurry.RotationX),
    ]

    target = 1


    for (angle, type_result) in list_params

        result_gate = Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target, angle))

        @test get_gate_symbol(result_gate) isa type_result
    end

    # returns empty array
    result_gate = Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target, 0.0))

    @test isnothing(result_gate)

    result_gate = Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target, 1e-3))

    @test result_gate isa Snowflurry.Gate{Snowflurry.RotationX}

    result_gate =
        Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target, 1e-3), atol = 1e-1)

    @test isnothing(result_gate)
end


@testset "SimplifyRxGatesTranspiler" begin
    transpiler = SimplifyRxGatesTranspiler()

    target = 1

    test_inputs = [
        (rotation_x(target, pi / 2), Snowflurry.X90)
        (rotation_x(target, -pi / 2), Snowflurry.XM90)
        (rotation_x(target, pi), Snowflurry.SigmaX)
        (rotation_x(target, pi / 3), Snowflurry.RotationX)
    ]

    for (input_gate, type_result) in test_inputs
        circuit = QuantumCircuit(
            qubit_count = target,
            instructions = [input_gate],
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        @test compare_circuits(circuit, transpiled_circuit)

        @test get_gate_symbol(get_circuit_instructions(transpiled_circuit)[1]) isa
              type_result
    end

    circuit = QuantumCircuit(
        qubit_count = target,
        instructions = [rotation_x(target, 0.0)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

    @test length(get_circuit_instructions(transpiled_circuit)) == 0

    # with default tolerance
    circuit = QuantumCircuit(
        qubit_count = target,
        instructions = [rotation_x(target, 1e-3)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test length(get_circuit_instructions(transpiled_circuit)) == 1

    # with user-defined tolerance

    transpiler = SimplifyRxGatesTranspiler(1e-1)

    transpiled_circuit = transpile(transpiler, circuit)

    @test length(get_circuit_instructions(transpiled_circuit)) == 0
end

@testset "CastRootZZToZ90AndCZGateTranspiler: Readout" begin
    transpiler = CastRootZZToZ90AndCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count = 2, instructions = [default_readout]),
        QuantumCircuit(qubit_count = 2, instructions = [root_zz(1, 2), default_readout]),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [root_zz_dagger(1, 2), default_readout],
        ),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [root_zz(1, 2), root_zz_dagger(1, 2), default_readout],
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.RootZZ)
        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.RootZZDagger)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "SimplifyRxGatesTranspiler: Readout" begin
    transpiler = SimplifyRxGatesTranspiler()

    test_inputs = [
        (rotation_x(target, pi / 2), Snowflurry.X90)
        (rotation_x(target, -pi / 2), Snowflurry.XM90)
        (rotation_x(target, pi), Snowflurry.SigmaX)
        (rotation_x(target, pi / 3), Snowflurry.RotationX)
    ]

    for (input_gate, type_result) in test_inputs
        circuit = QuantumCircuit(
            qubit_count = target,
            instructions = [input_gate, default_readout],
        )

        transpiled_circuit = transpile(transpiler, circuit)

        @test compare_circuits(circuit, transpiled_circuit)

        @test get_gate_symbol(get_circuit_instructions(transpiled_circuit)[1]) isa
              type_result
    end
end

@testset "simplify_rz_gate" begin

    list_params = [
        (pi / 2, Snowflurry.Z90),
        (5 * pi / 2, Snowflurry.Z90),
        (-3 * pi / 2, Snowflurry.Z90),
        (-7 * pi / 2, Snowflurry.Z90),
        (-pi / 2, Snowflurry.ZM90),
        (-5 * pi / 2, Snowflurry.ZM90),
        (3 * pi / 2, Snowflurry.ZM90),
        (7 * pi / 2, Snowflurry.ZM90),
        (-pi, Snowflurry.SigmaZ),
        (pi, Snowflurry.SigmaZ),
        (3 * pi, Snowflurry.SigmaZ),
        (-3 * pi, Snowflurry.SigmaZ),
        (pi / 4, Snowflurry.Pi8),
        (-pi / 4, Snowflurry.Pi8Dagger),
        (pi / 3, Snowflurry.PhaseShift),
    ]

    target = 1


    for (angle, type_result) in list_params

        result_gate = Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target, angle))

        @test get_gate_symbol(result_gate) isa type_result
    end

    # returns empty array
    result_gate = Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target, 0.0))

    @test isnothing(result_gate)

    result_gate = Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target, 1e-3))

    @test result_gate isa Snowflurry.Gate{Snowflurry.PhaseShift}

    result_gate =
        Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target, 1e-3), atol = 1e-1)

    @test isnothing(result_gate)
end

@testset "SimplifyRzGatesTranspiler" begin
    transpiler = SimplifyRzGatesTranspiler()

    target = 1

    test_inputs = [
        (phase_shift(target, pi / 2), Snowflurry.Z90)
        (phase_shift(target, -pi / 2), Snowflurry.ZM90)
        (phase_shift(target, pi), Snowflurry.SigmaZ)
        (phase_shift(target, pi / 4), Snowflurry.Pi8)
        (phase_shift(target, -pi / 4), Snowflurry.Pi8Dagger)
        (phase_shift(target, pi / 3), Snowflurry.PhaseShift)
    ]

    for (input_gate, type_result) in test_inputs
        circuit = QuantumCircuit(
            qubit_count = target,
            instructions = [input_gate],
            name = "test-name",
        )

        transpiled_circuit = transpile(transpiler, circuit)

        @test compare_circuits(circuit, transpiled_circuit)

        @test get_gate_symbol(get_circuit_instructions(transpiled_circuit)[1]) isa
              type_result
    end

    circuit = QuantumCircuit(
        qubit_count = target,
        instructions = [phase_shift(target, 0.0)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test compare_circuits(circuit, transpiled_circuit)

    @test length(get_circuit_instructions(transpiled_circuit)) == 0

    # with default tolerance
    circuit = QuantumCircuit(
        qubit_count = target,
        instructions = [phase_shift(target, 1e-3)],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test length(get_circuit_instructions(transpiled_circuit)) == 1

    # with user-defined tolerance

    transpiler = SimplifyRzGatesTranspiler(1e-1)

    transpiled_circuit = transpile(transpiler, circuit)

    @test length(get_circuit_instructions(transpiled_circuit)) == 0
end

@testset "SimplifyRzGatesTranspiler: Readout" begin
    transpiler = SimplifyRzGatesTranspiler()

    circuits = [
        QuantumCircuit(qubit_count = 2, instructions = [default_readout]),
        QuantumCircuit(
            qubit_count = 2,
            instructions = [phase_shift(target, pi / 2), default_readout],
        ),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "unsafe_compress_to_rz" begin
    target = 1
    qubit_count = 1

    test_inputs = [
        # single Rz-type gates
        [z_90(target)],
        [z_minus_90(target)],
        [sigma_z(target)],
        [pi_8(target)],
        [pi_8_dagger(target)],
        [rotation_z(target, pi / 5)],
        [phase_shift(target, pi / 3)],

        # multiple Rz-type gates
        [z_90(target), pi_8(target)],
        [sigma_z(target), pi_8_dagger(target)],
        [phase_shift(target, pi / 3), sigma_z(target), pi_8(target)],

        # mixture of Rz-type and other gates
        [z_90(target), pi_8(target), rotation_x(target, pi / 5), pi_8(target)],
        [sigma_y(target), sigma_z(target), pi_8_dagger(target), hadamard(target)],
        [sigma_x(target), phase_shift(target, pi / 3), sigma_z(target), pi_8(target)],
    ]

    for gates in test_inputs

    end

end

test_circuits_Rz_type = [
    [
        sigma_z(1),
        pi_8(1),
        rotation_z(1, pi / 9),
        phase_shift(1, pi / 7),
        control_x(1, 3),
        sigma_x(2),
        sigma_z(2),
        control_x(1, 4),
        z_90(2),
        sigma_x(1),
        sigma_z(4),
        pi_8_dagger(4),
        toffoli(1, 2, 3),
        phase_shift(4, pi / 3),
        pi_8_dagger(2),
    ],
    [   # all gates are `boundaries`
        control_x(1, 3),
        sigma_x(2),
        sigma_y(2),
        control_x(4, 2),
        hadamard(3),
        x_90(3),
        control_x(1, 4),
        toffoli(1, 4, 3),
        default_readout,
    ],
]

gates_in_output = [9, 9]

@testset "CompressRzGatesTranspiler: transpilation of Rz-type and other gates" begin

    qubit_count = 4
    transpiler = CompressRzGatesTranspiler()

    for (gates_list, gates_in_output) in zip(test_circuits_Rz_type, gates_in_output)
        for end_pos = 1:length(gates_list)

            truncated_input = gates_list[1:end_pos]

            circuit = QuantumCircuit(
                qubit_count = qubit_count,
                instructions = truncated_input,
                name = "test-name",
            )

            transpiled_circuit = transpile(transpiler, circuit)

            @test compare_circuits(circuit, transpiled_circuit)

            if end_pos == length(gates_list)
                @test length(get_circuit_instructions(transpiled_circuit)) ==
                      gates_in_output
            end
        end
    end
end

@testset "remove_swap_by_swapping_gates" begin
    transpiler = RemoveSwapBySwappingGatesTranspiler()

    circuit = QuantumCircuit(
        qubit_count = 4,
        instructions = [
            hadamard(1),
            sigma_x(3),
            control_x(1, 4),
            swap(1, 2),
            swap(2, 3),
            sigma_x(2),
        ],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
    @test simulate(circuit) ≈ simulate(transpiled_circuit)

    circuit = QuantumCircuit(
        qubit_count = 4,
        instructions = [
            hadamard(1),
            sigma_x(3),
            control_x(1, 4),
            swap(1, 2),
            swap(1, 4),
            sigma_x(2),
        ],
        name = "test-name",
    )

    transpiled_circuit = transpile(transpiler, circuit)

    @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
    @test simulate(circuit) ≈ simulate(transpiled_circuit)
end

@testset "UnsupportedGatesTranspiler" begin

    circuit = QuantumCircuit(
        qubit_count = 4,
        instructions = [controlled(hadamard(2), [1, 3])], # multiple-control not implemented
        name = "test-name",
    )

    @test_throws NotImplementedError transpile(UnsupportedGatesTranspiler(), circuit)

end

readout_test_circuits = [
    QuantumCircuit(qubit_count = 4, instructions = [default_readout]),
    QuantumCircuit(qubit_count = 4, instructions = [sigma_x(1), default_readout]),
    QuantumCircuit(
        qubit_count = 4,
        instructions = [sigma_x(1), default_readout, hadamard(2)],
    ),
    QuantumCircuit(
        qubit_count = 4,
        instructions = [sigma_x(1), default_readout, hadamard(2), readout(2, 2)],
    ),
]

@testset "ReadoutsAreFinalInstructionsTranspiler " begin

    transpiler = ReadoutsAreFinalInstructionsTranspiler()

    for circuit in readout_test_circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test isequal(circuit, transpiled_circuit)
    end

    ### error cases
    circuits = [
        QuantumCircuit(qubit_count = 4, instructions = [default_readout, default_readout]),
        QuantumCircuit(
            qubit_count = 4,
            instructions = [sigma_x(1), default_readout, default_readout],
        ),
        QuantumCircuit(
            qubit_count = 4,
            instructions = [sigma_x(1), default_readout, readout(2, 2), hadamard(2)],
        ),
        QuantumCircuit(
            qubit_count = 4,
            instructions = [
                sigma_x(1),
                default_readout,
                hadamard(2),
                readout(2, 2),
                rotation_x(1, pi),
            ],
        ),
    ]

    for circuit in circuits
        @test_throws AssertionError transpile(transpiler, circuit)
    end

end


@testset "ReadoutsDoNotConflictTranspiler " begin

    transpiler = ReadoutsDoNotConflictTranspiler()

    for circuit in readout_test_circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test isequal(circuit, transpiled_circuit)
    end

    ### error cases
    circuits = [
        QuantumCircuit(
            qubit_count = 4,
            instructions = [default_readout, readout(2, destination_bit)],
        ),
        QuantumCircuit(
            qubit_count = 4,
            instructions = [sigma_x(1), default_readout, readout(2, destination_bit)],
        ),
        QuantumCircuit(
            qubit_count = 4,
            instructions = [
                sigma_x(1),
                default_readout,
                readout(2, destination_bit),
                hadamard(2),
            ],
        ),
        QuantumCircuit(
            qubit_count = 4,
            instructions = [
                sigma_x(1),
                default_readout,
                hadamard(2),
                readout(2, destination_bit),
                rotation_x(1, pi),
            ],
        ),
    ]

    for circuit in circuits
        @test_throws ArgumentError transpile(transpiler, circuit)
    end

end

@testset "Transpilers: circuit properties are preserved" begin

    circuit = QuantumCircuit(
        qubit_count = 42,
        bit_count = 99,
        instructions = [readout(42, 99)],
        name = "test-name",
    )

    transpilers = [
        CircuitContainsAReadoutTranspiler(),
        ReadoutsDoNotConflictTranspiler(),
        UnsupportedGatesTranspiler(),
        DecomposeSingleTargetSingleControlGatesTranspiler(),
        CastToffoliToCXGateTranspiler(),
        CastCXToCZGateTranspiler(),
        CastISwapToCZGateTranspiler(),
        SwapQubitsForAdjacencyTranspiler(LineConnectivity(6)),
        SwapQubitsForAdjacencyTranspiler(LatticeConnectivity(4, 3)),
        CastSwapToCZGateTranspiler(),
        CompressSingleQubitGatesTranspiler(),
        SimplifyTrivialGatesTranspiler(),
        CastUniversalToRzRxRzTranspiler(),
        SimplifyRxGatesTranspiler(),
        CastRxToRzAndHalfRotationXTranspiler(),
        CastRootZZToZ90AndCZGateTranspiler(),
        CompressRzGatesTranspiler(),
        SimplifyRzGatesTranspiler(),
        ReadoutsAreFinalInstructionsTranspiler(),
        RejectNonNativeInstructionsTranspiler(LineConnectivity(42)),
    ]

    for transpiler in transpilers
        transpiled_circuit = transpile(transpiler, circuit)

        @test get_num_qubits(transpiled_circuit) == 42
        @test get_num_bits(transpiled_circuit) == 99
        @test get_name(transpiled_circuit) == "test-name"
        @test get_circuit_instructions(transpiled_circuit) == [readout(42, 99)]
    end
end

@testset "RejectNonNativeInstructionsTranspiler" begin

    connectivities_and_targets = [
        (LineConnectivity(12), (1, 2))
        (LineConnectivity(12, collect(9:12)), (1, 2))
        (LatticeConnectivity(3, 4), (1, 5))
        (LatticeConnectivity(3, 4, collect(9:12)), (1, 5))
    ]

    for (connectivity, targets) in connectivities_and_targets
        transpiler = RejectNonNativeInstructionsTranspiler(connectivity)

        for instr in vcat(single_qubit_instructions, readout(1, 1))
            circuit =
                QuantumCircuit(qubit_count = 6, instructions = [instr], name = "test-name")

            if is_native_instruction(instr, connectivity)
                @test isequal(transpile(transpiler, circuit), circuit)
            else
                @test_throws DomainError transpile(transpiler, circuit)
            end
        end

        circuit = QuantumCircuit(
            qubit_count = 6,
            instructions = [control_z(targets...)],
            name = "test-name",
        )

        @test isequal(transpile(transpiler, circuit), circuit)
    end

    connectivity = LineConnectivity(12)
    default_transpiler = RejectNonNativeInstructionsTranspiler(connectivity)
    circuit = QuantumCircuit(qubit_count = 6, instructions = [toffoli(1, 2, 3)])

    @test_throws DomainError transpile(default_transpiler, circuit)

    circuit = QuantumCircuit(qubit_count = 6, instructions = [control_x(2, 3)])
    custom_native_gates = [Snowflurry.ControlX]
    custom_transpiler =
        RejectNonNativeInstructionsTranspiler(connectivity, custom_native_gates)

    @test isequal(transpile(custom_transpiler, circuit), circuit)

    @test_throws(
        NotImplementedError,
        RejectNonNativeInstructionsTranspiler(AllToAllConnectivity())
    )

    excluded_positions = [2]
    connectivity_with_excluded_positions = LineConnectivity(12, excluded_positions)
    transpiler_with_excluded_positions =
        RejectNonNativeInstructionsTranspiler(connectivity_with_excluded_positions)
    circuit = QuantumCircuit(qubit_count = 6, instructions = [sigma_x(2)])
    @test isequal(transpile(transpiler_with_excluded_positions, circuit), circuit)
end

@testset "is_native_instruction" begin
    connectivity = LineConnectivity(9)
    @test is_native_instruction(pi_8_dagger(8), connectivity)
    @test is_native_instruction(control_z(5, 6), connectivity)
    @test is_native_instruction(readout(7, 7), connectivity)
    @test !is_native_instruction(readout(10, 10), connectivity)
    @test !is_native_instruction(toffoli(1, 2, 3), connectivity)
    @test !is_native_instruction(pi_8_dagger(10), connectivity)
    @test !is_native_instruction(control_z(5, 7), connectivity)

    custom_native_gates = [Snowflurry.ControlX, Snowflurry.X90]
    @test is_native_instruction(control_x(1, 2), connectivity, custom_native_gates)
    @test !is_native_instruction(control_x(1, 3), connectivity, custom_native_gates)
end

@testset "is_native_circuit" begin
    connectivity = LineConnectivity(20)
    default_native_instructions = [
        identity_gate(2),
        phase_shift(3, 0.2),
        pi_8(12),
        pi_8_dagger(11),
        sigma_x(1),
        sigma_y(1),
        sigma_z(2),
        x_90(1),
        x_minus_90(1),
        y_90(1),
        y_minus_90(1),
        z_90(1),
        z_minus_90(1),
        control_z(19, 20),
        readout(2, 2),
    ]

    default_circuit =
        QuantumCircuit(qubit_count = 20, instructions = default_native_instructions)
    @test is_native_circuit(default_circuit, connectivity) == (true, "")

    large_circuit = QuantumCircuit(qubit_count = 21)
    @test is_native_circuit(large_circuit, connectivity) ==
          (false, "Circuit qubit count 21 exceeds LineConnectivity qubit count: 20")

    foreign_circuit = QuantumCircuit(qubit_count = 3, instructions = [control_x(1, 2)])
    @test is_native_circuit(foreign_circuit, connectivity) == (
        false,
        "Instruction type Gate{Snowflurry.ControlX} with targets [1, 2] is not native " *
        "on the connectivity",
    )
    @test is_native_circuit(foreign_circuit, connectivity, [Snowflurry.ControlX]) ==
          (true, "")

    @test_throws(
        NotImplementedError,
        is_native_circuit(default_circuit, AllToAllConnectivity())
    )
end

@testset "RejectGatesOnExcludedPositionsTranspiler for all-to-all" begin

    connectivity = AllToAllConnectivity()

    circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [control_z(1, 2), readout(1, 1)],
        name = "test-name",
    )
    transpiler = RejectGatesOnExcludedPositionsTranspiler(connectivity)

    @test isequal(transpile(transpiler, circuit), circuit)
end

@testset "RejectGatesOnExcludedPositionsTranspiler for line connectivity" begin

    excluded_positions = [2]
    connectivity = LineConnectivity(4, excluded_positions)
    transpiler = RejectGatesOnExcludedPositionsTranspiler(connectivity)

    invalid_circuit = QuantumCircuit(
        qubit_count = 4,
        instructions = [sigma_x(4), control_z(1, 2), readout(1, 1)],
        name = "test-name",
    )
    @test_throws DomainError(
        connectivity,
        "the Gate{Snowflurry.ControlZ} on qubits [1, 2] cannot be applied " *
        "since qubit 2 is unavailable",
    ) transpile(transpiler, invalid_circuit)

    circuit_with_invalid_readout = QuantumCircuit(
        qubit_count = 4,
        instructions = [sigma_x(4), control_z(1, 3), readout(2, 1)],
        name = "test-name",
    )
    @test_throws DomainError(
        connectivity,
        "the Readout on qubits [2] cannot be applied " * "since qubit 2 is unavailable",
    ) transpile(transpiler, circuit_with_invalid_readout)

    valid_circuit = QuantumCircuit(
        qubit_count = 4,
        instructions = [sigma_x(1), control_z(3, 4), readout(1, 1)],
        name = "test-name",
    )

    @test isequal(transpile(transpiler, valid_circuit), valid_circuit)
end

@testset "RejectGatesOnExcludedPositionsTranspiler for lattice connectivity" begin

    excluded_positions = [2, 7]
    connectivity = LatticeConnectivity(3, 3, excluded_positions)
    transpiler = RejectGatesOnExcludedPositionsTranspiler(connectivity)

    invalid_circuit = QuantumCircuit(
        qubit_count = 7,
        instructions = [sigma_x(1), control_z(4, 7), readout(4, 1)],
        name = "test-name",
    )
    @test_throws DomainError transpile(transpiler, invalid_circuit)

    circuit_with_invalid_readout = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(5), control_z(1, 4), readout(2, 1)],
        name = "test-name",
    )
    @test_throws DomainError transpile(transpiler, circuit_with_invalid_readout)

    valid_circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(5), control_z(1, 4), readout(4, 1)],
        name = "test-name",
    )

    @test isequal(transpile(transpiler, valid_circuit), valid_circuit)
end

@testset "RejectGatesOnExcludedConnectionsTranspiler for all-to-all" begin

    connectivity = AllToAllConnectivity()

    circuit = QuantumCircuit(
        qubit_count = 2,
        instructions = [control_z(1, 2), hadamard(1)],
        name = "test-name",
    )
    transpiler = RejectGatesOnExcludedConnectionsTranspiler(connectivity)

    @test isequal(transpile(transpiler, circuit), circuit)
end

@testset "RejectGatesOnExcludedConnectionsTranspiler for line connectivity" begin

    excluded_connections = [(3, 4)]
    connectivity = LineConnectivity(5, Int[], excluded_connections)
    transpiler = RejectGatesOnExcludedConnectionsTranspiler(connectivity)

    invalid_circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(2), control_z(3, 4)],
        name = "test-name",
    )
    @test_throws(
        DomainError(
            transpiler.connectivity,
            "the Gate{Snowflurry.ControlZ} on qubits [3, 4] cannot be applied since " *
            "connection (3, 4) is unavailable",
        ),
        transpile(transpiler, invalid_circuit)
    )

    invalid_circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(2), toffoli(2, 3, 4)],
        name = "test-name",
    )

    @test_throws(
        DomainError(
            Snowflurry.are_gates_at_excluded_connections,
            "not implemented for gates with more than 2 qubits",
        ),
        transpile(transpiler, invalid_circuit)
    )

    valid_circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(3), control_z(4, 5)],
        name = "test-name",
    )

    @test isequal(transpile(transpiler, valid_circuit), valid_circuit)

    valid_circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [sigma_x(5), control_z(2, 3)],
        name = "test-name",
    )

    @test isequal(transpile(transpiler, valid_circuit), valid_circuit)
end

@testset "RejectGatesOnExcludedConnectionsTranspiler for lattice connectivity" begin

    excluded_connections = [(5, 1)]
    connectivity = LatticeConnectivity(3, 4, Int[], excluded_connections)
    transpiler = RejectGatesOnExcludedConnectionsTranspiler(connectivity)

    invalid_circuit = QuantumCircuit(
        qubit_count = 12,
        instructions = [sigma_x(6), control_z(1, 5), readout(1, 1)],
        name = "test-name",
    )
    @test_throws(
        DomainError(
            transpiler.connectivity,
            "the Gate{Snowflurry.ControlZ} on qubits [1, 5] cannot be applied since " *
            "connection (1, 5) is unavailable",
        ),
        transpile(transpiler, invalid_circuit)
    )

    valid_circuit = QuantumCircuit(
        qubit_count = 12,
        instructions = [sigma_x(1), control_z(9, 6), readout(1, 1)],
        name = "test-name",
    )
    @test isequal(transpile(transpiler, valid_circuit), valid_circuit)

    invalid_circuit = QuantumCircuit(
        qubit_count = 12,
        instructions = [sigma_x(2), controlled(sigma_x(1), [5, 9, 6]), readout(1, 1)],
        name = "test-name",
    )
    @test_throws(
        DomainError(
            Snowflurry.are_gates_at_excluded_connections,
            "not implemented for gates with more than 2 qubits",
        ),
        transpile(transpiler, invalid_circuit)
    )
end
