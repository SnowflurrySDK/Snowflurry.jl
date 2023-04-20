using Snowflake
using Test

include("mock_functions.jl")
requestor=MockRequestor(request_checker,post_checker)

target=1
theta=π/5
phi=π/7
lambda=π/9

single_qubit_gates=[
    hadamard(target),
    phase_shift(target,-phi/2),
    pi_8(target),
    pi_8_dagger(target),
    rotation(target,theta,phi),
    rotation_x(target,theta),
    rotation_y(target,theta),
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

test_circuits=[
    [
        sigma_x(1),
        sigma_y(1),
        hadamard(2),
        control_x(1,3),
        sigma_x(2),
        sigma_y(2),
        control_x(1,4),
        hadamard(2),
        sigma_z(1),
        sigma_x(4),
        sigma_y(4),
        toffoli(1,2,3),
        hadamard(4),
        sigma_z(2)
    ],
    [   # all gates are `boundaries`
        control_x(1,3),
        control_x(4,2),
        control_x(1,4),
        toffoli(1,4,3)
    ]
]

@testset "as_universal_gate" begin
    for gate in single_qubit_gates    
        universal_equivalent=Snowflake.as_universal_gate(target,get_operator(gate))
        @test get_operator(gate)≈get_operator(universal_equivalent)
    end
end

@testset "CompressSingleQubitGatesTranspiler" begin
        
    transpiler=Snowflake.CompressSingleQubitGatesTranspiler()
    
    # attempt compression of all pairs of single qubit gates
    for first_gate in single_qubit_gates
        for second_gate in single_qubit_gates          
            circuit = QuantumCircuit(qubit_count = 2, gates=[first_gate,second_gate])

            transpiled_circuit=transpile(transpiler,circuit)

            @test compare_circuits(circuit,transpiled_circuit)
        end
    end
end 

@testset "Transpiler" begin
    struct NonExistentTranspiler<:Transpiler end

    @test_throws NotImplementedError transpile(NonExistentTranspiler(),QuantumCircuit(qubit_count = 2))
end

@testset "basic transpilation" begin

    transpiler=Snowflake.CompressSingleQubitGatesTranspiler()

    input_gate=sigma_x(1)

    #compressing single input gate does nothing
    circuit = QuantumCircuit(qubit_count = 2, gates=[input_gate])

    transpiled_circuit=transpile(transpiler,circuit)

    @test compare_circuits(circuit,transpiled_circuit)

    #compressing gates on different targets does nothing
    circuit = QuantumCircuit(qubit_count = 2, gates=[sigma_x(1),sigma_x(2)])

    transpiled_circuit=transpile(transpiler,circuit)

    @test compare_circuits(circuit,transpiled_circuit)

    #compressing one single and one multi target gates does nothing
    circuit = QuantumCircuit(qubit_count = 2, gates=[sigma_x(1),control_x(1,2)])

    transpiled_circuit=transpile(transpiler,circuit)

    @test compare_circuits(circuit,transpiled_circuit)

end

@testset "transpilation of single and multiple target gates" begin
    
    qubit_count=4
    transpiler=Snowflake.CompressSingleQubitGatesTranspiler()
    
    for gates_list in test_circuits
        for end_pos in 1:length(gates_list)

            truncated_input=gates_list[1:end_pos]

            circuit = QuantumCircuit(qubit_count = qubit_count, gates=truncated_input)
            
            transpiled_circuit=transpile(transpiler,circuit)

            @test compare_circuits(circuit,transpiled_circuit)
        end
    end
end

@testset "cast_to_phase_shift_and_half_rotation_x: from universal" begin

    qubit_count=2
    target=1
    transpiler=Snowflake.CastToPhaseShiftAndHalfRotationX()

    list_params=[
        #theta,     phi,    lambda, gates_in_output
        (pi/13,     pi/3,   pi/5,   5),
        (pi/13,     pi/3,   0,      4), 
        (pi/13,     0,      pi/5,   4), 
        (pi/13,     0,      0,      3), 
        (0,         pi/3,   pi/5,   2),
        (0,         pi/3,   0,      1), 
        (0,         0,      pi/5,   1),
        (0,         0,      0,      0),
    ]

    for (theta,phi,lambda,gates_in_output) in list_params
        circuit = QuantumCircuit(
            qubit_count = qubit_count, 
            gates=[universal(target,theta,phi,lambda)])
    
        transpiled_circuit=transpile(transpiler,circuit)
    
        gates=get_circuit_gates(transpiled_circuit)
        
        @test length(gates)==gates_in_output
    
        @test compare_circuits(circuit,transpiled_circuit)  
    end
end

@testset "cast_to_phase_shift_and_half_rotation_x: from any single_qubit_gates" begin

    qubit_count=2
    target=1
    transpiler=Snowflake.CastToPhaseShiftAndHalfRotationX()

    for gate in single_qubit_gates

        circuit = QuantumCircuit(qubit_count = qubit_count, gates=[gate])

        transpiled_circuit=transpile(transpiler,circuit)

        @test compare_circuits(circuit,transpiled_circuit)  
    end

    circuit = QuantumCircuit(
        qubit_count = 2, 
        gates=[universal(1,1e-3,1e-3,1e-3)]
        )
    
    # with default tolerance        
    transpiled_circuit_default_tol=transpile(transpiler,circuit)
        
    @test length(get_circuit_gates(transpiled_circuit_default_tol))==5

    # with user-defined tolerance
    transpiler=Snowflake.CastToPhaseShiftAndHalfRotationX(1e-1)

    transpiled_circuit_high_tol=transpile(transpiler,circuit)

    @test length(get_circuit_gates(transpiled_circuit_high_tol))==0

end

@testset "simplify_rz_gate" begin

    list_params=[
        ( pi/2, Snowflake.Z90),
        (-pi/2, Snowflake.ZM90),
        ( pi,   Snowflake.SigmaZ),
        ( pi/4, Snowflake.Pi8),
        (-pi/4, Snowflake.Pi8Dagger),
        ( pi/3, Snowflake.PhaseShift)
    ]

    target=1


    for (angle,type_result) in list_params

        result_gate=Snowflake.simplify_rz_gate(target,angle)

        @test typeof(result_gate)==type_result
    end

    # returns empty array
    result_gate=Snowflake.simplify_rz_gate(target,0.)

    @test isnothing(result_gate)

    result_gate=Snowflake.simplify_rz_gate(target,1e-3)

    @test typeof(result_gate)==Snowflake.PhaseShift

    result_gate=Snowflake.simplify_rz_gate(target,1e-3,atol=1e-1)

    @test isnothing(result_gate)
end

@testset "PlaceOperationsOnLine" begin
    
    transpiler=Snowflake.PlaceOperationsOnLine()

    qubit_count=10

    test_specs=[
        # (gates list       gates_in_output)
        ([swap(2,3)],       1)      # no effect
        ([swap(2,8)],       11)
        ([swap(8,2)],       11)

        ([iswap(2,3)],       1)      # no effect
        ([iswap(2,8)],       11)
        ([iswap(8,2)],       11)

        ([control_z(5,6)],  1)      # no effect
        ([control_z(5,10)], 9)      # target at bottom
        ([control_z(10,1)], 17)     # target on top

        ([toffoli(4,5,6)],  1)      # no effect
        ([toffoli(4,6,5)],  1)      # no effect
        ([toffoli(6,5,4)],  1)      # no effect
        ([toffoli(4,6,2)],  7)      # target on top
        ([toffoli(2,6,4)],  7)      # target in middle
        ([toffoli(1,3,6)],  9)      # target at bottom
        ([toffoli(5,10,2)], 17)     # larger distance

        ([control_z(10,1),toffoli(2,4,8)], 28) # sequence of gates
    ]

    for (input_gates,gates_in_output) in test_specs
        circuit = QuantumCircuit(qubit_count = qubit_count, gates=input_gates) 
    
        
        transpiled_circuit=transpile(transpiler,circuit)
        
        gates=get_circuit_gates(transpiled_circuit)
        
        @test length(gates)==gates_in_output
        
        if !(compare_circuits(circuit,transpiled_circuit))
            println("gates in input: $(get_circuit_gates(circuit))")
        end

        @test compare_circuits(circuit,transpiled_circuit)

    end

end

@testset "get_transpiler" begin    
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)

    num_repetitions=100
        
    qpu=AnyonQPU(test_client)

    transpiler=get_transpiler(qpu) 

    @test typeof(transpiler)==Snowflake.SequentialTranspiler
end


@testset "SequentialTranspiler: compress and cast_to_phase_shift_and_half_rotation_x" begin    

    transpiler=Snowflake.SequentialTranspiler([   
            Snowflake.CompressSingleQubitGatesTranspiler(),
            Snowflake.CastToPhaseShiftAndHalfRotationX()
        ])

    qubit_count=4
        
    for gates_list in test_circuits
        for end_pos in 1:length(gates_list)

            truncated_input=gates_list[1:end_pos]

            circuit = QuantumCircuit(qubit_count = qubit_count, gates=truncated_input)
            
            transpiled_circuit=transpile(transpiler,circuit)

            @test compare_circuits(circuit,transpiled_circuit)
        end
    end
end

@testset "cast_to_cz: unkown gate" begin
    struct UnknownCastToCZGate <: AbstractGate end
    gate = UnknownCastToCZGate()

    @test_throws NotImplementedError Snowflake.cast_to_cz(gate)
end

@testset "cast_to_cz: swap" begin
    transpiler = Snowflake.CastSwapToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count=2, gates=[swap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[swap(1,2), x_90(1), swap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2), swap(1,2)]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflake.Swap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_cz: cx" begin
    transpiler = Snowflake.CastCXToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count=2, gates=[control_x(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[control_x(1,2), x_90(1), control_x(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2), control_x(1,2)]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflake.ControlX)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_cz: iswap" begin
    transpiler = Snowflake.CastISwapToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2), x_90(1), iswap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[control_x(1,2), iswap(1,2)]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflake.ISwap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_cx: toffoli" begin
    transpiler = Snowflake.CastToffoliToCXGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count=3, gates=[toffoli(1,2,3), iswap(1,2), toffoli(2,1,3)]),
        QuantumCircuit(qubit_count=3, gates=[toffoli(1,3,2), x_90(1), toffoli(2,3,1)]),
        QuantumCircuit(qubit_count=3, gates=[toffoli(3,1,2), control_x(1,2), toffoli(3,2,1)]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflake.Toffoli)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "SequentialTranspiler: compress, cast_to_Rz_and_half_Rx and Place" begin    
    
    transpiler=Snowflake.SequentialTranspiler([
        Snowflake.CompressSingleQubitGatesTranspiler(),
        Snowflake.CastToPhaseShiftAndHalfRotationX(),
        Snowflake.PlaceOperationsOnLine(),
    ])

    qubit_count=6

    test_inputs=[
                toffoli(4,6,2),
                sigma_x(1),
                sigma_y(1),
                sigma_y(4),
                control_z(5,1),
                hadamard(1),
                sigma_x(4)
            ]

    test_inputs=vcat(test_circuits,[test_inputs])

    for input_gates in test_inputs
        for end_pos in 1:length(input_gates)

            truncated_input=input_gates[1:end_pos]

            circuit = QuantumCircuit(qubit_count = qubit_count, gates=truncated_input)
            
            transpiled_circuit=transpile(transpiler,circuit)

            @test compare_circuits(circuit,transpiled_circuit)
        end
    end
end


@testset "simplify_rx_gate" begin

    list_params=[
        ( pi/2, Snowflake.X90),
        (-pi/2, Snowflake.XM90),
        ( pi,   Snowflake.SigmaX),
        ( pi/3, Snowflake.RotationX)
    ]

    target=1


    for (angle,type_result) in list_params

        result_gate=Snowflake.simplify_rx_gate(target,angle)

        @test typeof(result_gate)==type_result
    end

    # returns empty array
    result_gate=Snowflake.simplify_rx_gate(target,0.)

    @test isnothing(result_gate)

    result_gate=Snowflake.simplify_rx_gate(target,1e-3)

    @test typeof(result_gate)==Snowflake.RotationX

    result_gate=Snowflake.simplify_rx_gate(target,1e-3,atol=1e-1)

    @test isnothing(result_gate)
end


@testset "SimplifyRxGates" begin
    transpiler = SimplifyRxGates()

    target=1

    test_inputs=[
        (rotation_x(target,pi/2),  Snowflake.X90)
        (rotation_x(target,-pi/2), Snowflake.XM90)
        (rotation_x(target,pi),    Snowflake.SigmaX)
        (rotation_x(target,pi/3),  Snowflake.RotationX)
    ]

    for (input_gate,type_result) in test_inputs
        circuit=QuantumCircuit(qubit_count=target, gates=[input_gate])

        transpiled_circuit=transpile(transpiler,circuit)

        @test compare_circuits(circuit,transpiled_circuit)

        @test typeof(get_circuit_gates(transpiled_circuit)[1])==type_result
    end

    circuit=QuantumCircuit(qubit_count=target, gates=[rotation_x(target,0.)])

    transpiled_circuit=transpile(transpiler,circuit)

    @test compare_circuits(circuit,transpiled_circuit)

    @test length(get_circuit_gates(transpiled_circuit))==0

    # with default tolerance
    circuit=QuantumCircuit(qubit_count=target, gates=[rotation_x(target,1e-3)])

    transpiled_circuit=transpile(transpiler,circuit)

    @test length(get_circuit_gates(transpiled_circuit))==1

    # with user-defined tolerance

    transpiler=SimplifyRxGates(1e-1)

    transpiled_circuit=transpile(transpiler,circuit)

    @test length(get_circuit_gates(transpiled_circuit))==0
end
