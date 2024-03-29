using Snowflurry
using Test

@testset "DecomposeSingleTargetSingleControlGatesTranspiler: single-control" begin

    transpiler = DecomposeSingleTargetSingleControlGatesTranspiler()

    phi = π / 3
    theta = π / 5
    lambda = π / 6

    instr_list = [
        identity_gate(1),
        hadamard(1),
        phase_shift(1, -phi / 2),
        pi_8(1),
        pi_8_dagger(1),
        rotation(1, theta, phi),
        rotation_x(1, theta),
        rotation_y(1, theta),
        rotation_z(1, theta),
        sigma_x(1),
        sigma_y(1),
        sigma_z(1),
        universal(1, theta, phi, lambda),
        x_90(1),
        x_minus_90(1),
        y_90(1),
        y_minus_90(1),
        z_90(1),
        z_minus_90(1),
        control_x(1, 2),
        control_z(4, 6),
        toffoli(1, 2, 6),
        swap(2, 5),
        iswap(4, 1),
        iswap_dagger(6, 3),
        readout(1, 2),
    ]

    # non-Controlled Gates are left untouched
    for instr in instr_list
        circuit = QuantumCircuit(qubit_count = 6, instructions = [instr])
        transpiled_circuit = transpile(transpiler, circuit)
        @test isequal(circuit, transpiled_circuit)
    end

    target_control_pairs = [(1, 2), (1, 3), (2, 3), (3, 2), (3, 1), (2, 1)]

    for (target, control) in target_control_pairs

        test_cases = [
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

        for kernel in test_cases
            circuit = QuantumCircuit(
                qubit_count = 4,
                instructions = [controlled(kernel, [control])],
            )
            transpiled_circuit = transpile(transpiler, circuit)
            @test compare_circuits(circuit, transpiled_circuit)

            circuit = QuantumCircuit(
                qubit_count = 4,
                instructions = [controlled(kernel, [control]), readout(1, 1)],
            )
            transpiled_circuit = transpile(transpiler, circuit)
            @test compare_circuits(circuit, transpiled_circuit)
        end
    end

end


@testset "DecomposeSingleTargetSingleControlGatesTranspiler: ignored cases" begin

    transpiler = DecomposeSingleTargetSingleControlGatesTranspiler()

    target = 1
    target_2 = 4
    control = 2
    control_2 = 3
    control_3 = 5

    # multiple-control single-target gates are ignored
    ignored_cases = [
        swap(target, target_2),
        iswap(target, target_2),
        control_x(control, target),
        toffoli(control, control_2, target),
    ]

    for kernel in ignored_cases
        circuit = QuantumCircuit(
            qubit_count = 5,
            instructions = [controlled(kernel, [control_3])],
        )
        transpiled_circuit = transpile(transpiler, circuit)

        instr_sequence = get_circuit_instructions(transpiled_circuit)
        @test length(instr_sequence) == 1
        @test isequal(instr_sequence[1], controlled(kernel, [control_3]))
    end
end

@testset "DecomposeSingleTargetSingleControlGatesTranspiler: global phase" begin

    transpiler = DecomposeSingleTargetSingleControlGatesTranspiler()

    target = 2
    control = 1

    test_cases = [
        (phase_shift(target, pi / 2), z_90(target), pi / 4),
        (phase_shift(target, -pi / 2), z_minus_90(target), -pi / 4),
    ]

    for (phase_instr, z_90_instr, global_phase) in test_cases
        phase_circuit = QuantumCircuit(
            qubit_count = 4,
            instructions = [controlled(phase_instr, [control])],
        )
        transpiled_phase_circuit = transpile(transpiler, phase_circuit)

        z_90_circuit = QuantumCircuit(
            qubit_count = 4,
            instructions = [controlled(z_90_instr, [control])],
        )
        transpiled_z90_circuit = transpile(transpiler, z_90_circuit)

        phase_gate_sequence = get_circuit_instructions(transpiled_phase_circuit)
        z_90_gate_sequence = get_circuit_instructions(transpiled_z90_circuit)

        @test length(phase_gate_sequence) == length(z_90_gate_sequence) + 1

        instr = pop!(transpiled_phase_circuit)
        @test isequal(instr, phase_shift(control, global_phase))

        @test isequal(transpiled_phase_circuit, transpiled_z90_circuit)
    end
end

@testset "DecomposeSingleTargetSingleControlGatesTranspiler: substitutions" begin

    transpiler = DecomposeSingleTargetSingleControlGatesTranspiler()

    target = 2
    control = 1

    test_cases = [
        (controlled(sigma_x(target), [control]), control_x(control, target)),
        (controlled(sigma_z(target), [control]), control_z(control, target)),
    ]

    for (instr, expected_substitute) in test_cases
        circuit = QuantumCircuit(qubit_count = 3, instructions = [instr])
        transpiled_circuit = transpile(transpiler, circuit)

        gate_sequence = get_circuit_instructions(transpiled_circuit)
        @test length(gate_sequence) == 1
        gate = pop!(transpiled_circuit)

        @test isequal(gate, expected_substitute)
    end
end
