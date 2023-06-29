using Snowflurry
using Test

include("mock_functions.jl")
requestor=MockRequestor(request_checker,post_checker)

target=1
theta=π/5
phi=π/7
lambda=π/9

single_qubit_gates=[
    identity_gate(target),
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
        identity_gate(1),
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
        toffoli(1,4,3),
        swap(2,4),
        iswap(4,1),
        iswap_dagger(1,3),
    ]
]

@testset "as_universal_gate" begin
    for gate in single_qubit_gates    
        universal_equivalent=Snowflurry.as_universal_gate(target,get_operator(get_gate_symbol(gate)))
        @test get_operator(get_gate_symbol(gate))≈get_operator(get_gate_symbol(universal_equivalent))
    end
end

@testset "CompressSingleQubitGatesTranspiler" begin
        
    transpiler=CompressSingleQubitGatesTranspiler()
    
    # attempt compression of all pairs of single qubit gates
    for first_gate in single_qubit_gates
        for second_gate in single_qubit_gates          
            circuit = QuantumCircuit(qubit_count = 2, gates=[first_gate,second_gate])

            transpiled_circuit=transpile(transpiler,circuit)

            gates=get_circuit_gates(transpiled_circuit)

            @test length(gates)==1

            @test compare_circuits(circuit,transpiled_circuit)

            @test get_gate_symbol(gates[1]) isa Snowflurry.Universal
        end
    end

    # attempt empty circuit
    circuit = QuantumCircuit(qubit_count = 2)

    transpiled_circuit=transpile(transpiler,circuit)

    gates=get_circuit_gates(transpiled_circuit)

    @test length(gates)==0

    # circuit with single gate is unchanged
    circuit = QuantumCircuit(qubit_count = 2,gates=[sigma_x(1)])

    transpiled_circuit=transpile(transpiler,circuit)

    gates=get_circuit_gates(transpiled_circuit)

    @test length(gates)==1

    @test circuit_contains_gate_type(transpiled_circuit, Snowflurry.SigmaX)

    # circuit with single gate and boundary is unchanged
    circuit = QuantumCircuit(qubit_count = 2,gates=[sigma_x(1),control_x(1,2)])

    transpiled_circuit=transpile(transpiler,circuit)

    gates=get_circuit_gates(transpiled_circuit)

    @test length(gates)==2

    @test get_gate_symbol(gates[1]) isa Snowflurry.SigmaX
    @test get_gate_symbol(gates[2]) isa Snowflurry.ControlX
end 

@testset "Transpiler" begin
    struct NonExistentTranspiler<:Transpiler end

    @test_throws NotImplementedError transpile(NonExistentTranspiler(),QuantumCircuit(qubit_count = 2))
end

@testset "Compress to Universal: basic transpilation" begin

    transpiler=CompressSingleQubitGatesTranspiler()

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

@testset "Compress to Universal: transpilation of single and multiple target gates" begin
    
    qubit_count=4
    transpiler=CompressSingleQubitGatesTranspiler()
    
    for gates_list in test_circuits
        for end_pos in 1:length(gates_list)

            truncated_input=gates_list[1:end_pos]

            circuit = QuantumCircuit(qubit_count = qubit_count, gates=truncated_input)
            
            transpiled_circuit=transpile(transpiler,circuit)

            @test compare_circuits(circuit,transpiled_circuit)
        end
    end
end


@testset "CastUniversalToRzRxRzTranspiler" begin

    qubit_count=2
    target=1
    transpiler=CastUniversalToRzRxRzTranspiler()

    list_params=[
        #theta,     phi,    lambda, gates_in_output
        (pi/13,     pi/3,   pi/5,   3),
        (pi/13,     pi/3,   0,      3), 
        (pi/13,     0,      pi/5,   3), 
        (pi/13,     0,      0,      3), 
        (0,         pi/3,   pi/5,   3),
        (0,         pi/3,   0,      3), 
        (0,         0,      pi/5,   3),
        (0,         0,      0,      3),
    ]

    for (theta,phi,lambda,gates_in_output) in list_params

        circuit = QuantumCircuit(
            qubit_count = qubit_count, 
            gates=[universal(target,theta,phi,lambda)])
    
        transpiled_circuit=transpile(transpiler,circuit)
    
        gates=get_circuit_gates(transpiled_circuit)

        @test length(gates)==gates_in_output

        @test get_gate_symbol(gates[1]) isa Snowflurry.PhaseShift
        @test get_gate_symbol(gates[2]) isa Snowflurry.RotationX
        @test get_gate_symbol(gates[3]) isa Snowflurry.PhaseShift
    
        @test compare_circuits(circuit,transpiled_circuit)  
    end

    #from non-Universal gate
    circuit = QuantumCircuit(qubit_count = qubit_count, gates=[sigma_x(target)])

    transpiled_circuit=transpile(transpiler,circuit)

    @test compare_circuits(circuit,transpiled_circuit)  

    #from single and multiple-target gates
    circuit = QuantumCircuit(
        qubit_count = 2, 
        gates=[
            universal(1,π/2,π/4,π/8),
            control_x(1,2)
            ]
        )

    transpiled_circuit=transpile(transpiler,circuit)

    @test compare_circuits(circuit,transpiled_circuit)  

end

@testset "cast_Rx_to_Rz_and_half_rotation_x" begin

    qubit_count=2
    target=1
    transpiler=CastRxToRzAndHalfRotationXTranspiler()

    list_params=[
        #theta,     
        π,π/2,π/4,π/8,π/6,              
    ]

    for theta in list_params
        circuit = QuantumCircuit(
            qubit_count = qubit_count, 
            gates=[rotation_x(target,theta)]
        )
            
        transpiled_circuit=transpile(transpiler,circuit)
            
        @test compare_circuits(circuit,transpiled_circuit)  
        
        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.RotationX)

        gates=get_circuit_gates(transpiled_circuit)
        
        @test length(gates)==5

        @test get_gate_symbol(gates[1]) isa Snowflurry.Z90
        @test get_gate_symbol(gates[2]) isa Snowflurry.X90
        @test get_gate_symbol(gates[3]) isa Snowflurry.PhaseShift
        @test get_gate_symbol(gates[4]) isa Snowflurry.XM90
        @test get_gate_symbol(gates[5]) isa Snowflurry.ZM90
    end
end

@testset "cast_to_phase_shift_and_half_rotation_x: from universal" begin

    qubit_count=2
    target=1
    transpiler=Snowflurry.CastToPhaseShiftAndHalfRotationXTranspiler()

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
    transpiler=Snowflurry.CastToPhaseShiftAndHalfRotationXTranspiler()

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
    transpiler=Snowflurry.CastToPhaseShiftAndHalfRotationXTranspiler(1e-1)

    transpiled_circuit_high_tol=transpile(transpiler,circuit)

    @test length(get_circuit_gates(transpiled_circuit_high_tol))==0

end

@testset "SwapQubitsForLineConnectivityTranspiler" begin
    
    transpiler=Snowflurry.SwapQubitsForLineConnectivityTranspiler()

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

@testset "SwapQubitsForLineConnectivityTranspiler: multi-target multi-parameter" begin

    struct MultiParamMultiTargetGateSymbol <: Snowflurry.AbstractGateSymbol
        theta::Real
        phi::Real
    end

    Snowflurry.get_num_connected_qubits(gate::MultiParamMultiTargetGateSymbol)=3
    Snowflurry.get_gate_parameters(gate::MultiParamMultiTargetGateSymbol)=Dict("theta"=>gate.theta,"phi"=>gate.phi)
    Snowflurry.get_operator(gate::MultiParamMultiTargetGateSymbol, T::Type{<:Complex}=ComplexF64) = DenseOperator(
        T[1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
        0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0
        0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0
        0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0
        0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0
        0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0
        0.0 0.0 0.0 0.0 0.0 0.0 0.0 cos(gate.theta)
        0.0 0.0 0.0 0.0 0.0 0.0 cos(gate.phi) 0.0]
    )

    Snowflurry.gates_display_symbols[MultiParamMultiTargetGateSymbol]=["*","x","MM(θ=%s,phi=%s)","theta","phi"]

    Snowflurry.gates_instruction_symbols[MultiParamMultiTargetGateSymbol]="mm"


    circuit=QuantumCircuit(qubit_count=5,gates=[Gate(MultiParamMultiTargetGateSymbol(π,π/3), [1,3, 5])])

    transpiler=SwapQubitsForLineConnectivityTranspiler()

    transpiled_circuit=transpile(transpiler,circuit)

    println("circuit: $circuit") # test printout for multi-target multi-param gate
    
    @test compare_circuits(circuit,transpiled_circuit)

end

@testset "AnyonYukonQPU: transpilation of native gates" begin            
    qpu=AnyonYukonQPU(;host=host,user=user,access_token=access_token)

    qubit_count=1
    target=1
    
    transpiler=get_transpiler(qpu) 
        
    input_gates_native=[
        # gate_type, gate
        phase_shift(target,-phi/2),
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
    ]
    
    input_gates_foreign=[
        # gate_type, gate
        identity_gate(target),
        hadamard(target),
        rotation(target,theta,phi),
        rotation_x(target,theta),
        rotation_y(target,theta),
    ]
    
    for (gates_list,input_is_native) in vcat(
            (input_gates_native,true),
            (input_gates_foreign,false)
        )
        for gate in gates_list
    
            circuit=QuantumCircuit(qubit_count=qubit_count,gates=[gate])
            transpiled_circuit=transpile(transpiler,circuit)
                
            @test compare_circuits(circuit,transpiled_circuit)
        
            gates_in_output=get_circuit_gates(transpiled_circuit)

            if input_is_native
                test_is_not_rz=[
                    !(typeof(get_gate_symbol(gate)) in Snowflurry.set_of_rz_gates)
                    for gate in gates_in_output
                ]

                # at most one non-Rz gate in output
                @test sum(test_is_not_rz)<=1
            end

            for gate in gates_in_output
                @test is_native_gate(qpu, gate)
            end
        end
    end
end

@testset "AnyonYukonQPU: sequential transpilation" begin            
    qpu=AnyonYukonQPU(;host=host,user=user,access_token=access_token)
    transpiler=get_transpiler(qpu) 

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

@testset "AnyonYukonQPU: transpilation of a Ghz circuit" begin
    qpu=AnyonYukonQPU(;host=host,user=user,access_token=access_token)

    qubit_count=5
    
    transpiler=get_transpiler(qpu) 
    
    circuit=QuantumCircuit(qubit_count=qubit_count,gates=vcat(
        hadamard(1),[control_x(i,i+1) for i in 1:qubit_count-1])
    )

    transpiled_circuit=transpile(transpiler,circuit)

    results=Dict{Int,Vector{DataType}}([])

    for gate in get_circuit_gates(transpiled_circuit)

        targets=get_connected_qubits(gate)

        for target in targets
            if haskey(results,target)
                results[target]=push!(results[target], typeof(get_gate_symbol(gate)))
            else
                results[target]=[typeof(get_gate_symbol(gate))]
            end
        end
    end

    for (target,gates_array_per_target) in results

        if target==1
            @test gates_array_per_target==[
                Snowflurry.Z90,
                Snowflurry.X90,
                Snowflurry.Z90,
                Snowflurry.ControlZ,
            ]
        elseif target==qubit_count
            @test gates_array_per_target==[
                Snowflurry.Z90,
                Snowflurry.X90,
                Snowflurry.Z90,
                Snowflurry.ControlZ,
                Snowflurry.Z90,
                Snowflurry.X90,
                Snowflurry.Z90,
            ]            
        else
            @test gates_array_per_target==[
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

@testset "SequentialTranspiler: compress and cast_to_phase_shift_and_half_rotation_x" begin    

    transpiler=Snowflurry.SequentialTranspiler([   
            Snowflurry.CompressSingleQubitGatesTranspiler(),
            Snowflurry.CastToPhaseShiftAndHalfRotationXTranspiler()
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

@testset "cast_to_cz: unknown gate" begin
    struct UnknownCastToCZGateSymbol <: AbstractGateSymbol end
    symbol = UnknownCastToCZGateSymbol()

    @test_throws NotImplementedError Snowflurry.cast_to_cz(symbol, [1,2])
end

@testset "cast_to_cz: swap" begin
    transpiler = CastSwapToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count=2, gates=[swap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[swap(1,2), x_90(1), swap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2), swap(1,2)]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_cz: cx" begin
    transpiler = CastCXToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count=2, gates=[control_x(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[control_x(1,2), x_90(1), control_x(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2), control_x(1,2)]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.ControlX)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "cast_to_cz: iswap" begin
    transpiler = CastISwapToCZGateTranspiler()

    circuits = [
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[iswap(1,2), x_90(1), iswap(1,2)]),
        QuantumCircuit(qubit_count=2, gates=[control_x(1,2), iswap(1,2)]),
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
        QuantumCircuit(qubit_count=3, gates=[toffoli(1,2,3), iswap(1,2), toffoli(2,1,3)]),
        QuantumCircuit(qubit_count=3, gates=[toffoli(1,3,2), x_90(1), toffoli(2,3,1)]),
        QuantumCircuit(qubit_count=3, gates=[toffoli(3,1,2), control_x(1,2), toffoli(3,2,1)]),
    ]

    for circuit in circuits
        transpiled_circuit = transpile(transpiler, circuit)

        @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Toffoli)
        @test compare_circuits(circuit, transpiled_circuit)
    end
end

@testset "SequentialTranspiler: compress, cast_to_Rz_and_half_Rx and Place" begin    
    
    transpiler=Snowflurry.SequentialTranspiler([
        Snowflurry.CompressSingleQubitGatesTranspiler(),
        Snowflurry.CastToPhaseShiftAndHalfRotationXTranspiler(),
        Snowflurry.SwapQubitsForLineConnectivityTranspiler(),
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
        ( pi/2, Snowflurry.X90),
        (-pi/2, Snowflurry.XM90),
        ( pi,   Snowflurry.SigmaX),
        ( pi/3, Snowflurry.RotationX)
    ]

    target=1


    for (angle,type_result) in list_params

        result_gate=Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target,angle))

        @test get_gate_symbol(result_gate) isa type_result
    end

    # returns empty array
    result_gate=Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target,0.))

    @test isnothing(result_gate)

    result_gate=Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target,1e-3))

    @test get_gate_symbol(result_gate) isa Snowflurry.RotationX

    result_gate=Snowflurry.simplify_rx_gate(Snowflurry.rotation_x(target,1e-3),atol=1e-1)

    @test isnothing(result_gate)
end


@testset "SimplifyRxGatesTranspiler" begin
    transpiler = SimplifyRxGatesTranspiler()

    target=1

    test_inputs=[
        (rotation_x(target,pi/2),  Snowflurry.X90)
        (rotation_x(target,-pi/2), Snowflurry.XM90)
        (rotation_x(target,pi),    Snowflurry.SigmaX)
        (rotation_x(target,pi/3),  Snowflurry.RotationX)
    ]

    for (input_gate,type_result) in test_inputs
        circuit=QuantumCircuit(qubit_count=target, gates=[input_gate])

        transpiled_circuit=transpile(transpiler,circuit)

        @test compare_circuits(circuit,transpiled_circuit)

        @test get_gate_symbol(get_circuit_gates(transpiled_circuit)[1]) isa type_result
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

    transpiler=SimplifyRxGatesTranspiler(1e-1)

    transpiled_circuit=transpile(transpiler,circuit)

    @test length(get_circuit_gates(transpiled_circuit))==0
end

@testset "simplify_rz_gate" begin

    list_params=[
        ( pi/2,     Snowflurry.Z90),
        ( 5*pi/2,   Snowflurry.Z90),
        ( -3*pi/2,  Snowflurry.Z90),
        ( -7*pi/2,  Snowflurry.Z90),
        (-pi/2,     Snowflurry.ZM90),
        (-5*pi/2,   Snowflurry.ZM90),
        (3*pi/2,    Snowflurry.ZM90),
        (7*pi/2,    Snowflurry.ZM90),
        (-pi,       Snowflurry.SigmaZ),
        ( pi,       Snowflurry.SigmaZ),
        ( 3*pi,     Snowflurry.SigmaZ),
        (-3*pi,     Snowflurry.SigmaZ),
        ( pi/4,     Snowflurry.Pi8),
        (-pi/4,     Snowflurry.Pi8Dagger),
        ( pi/3,     Snowflurry.PhaseShift)
    ]

    target=1


    for (angle,type_result) in list_params

        result_gate=Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target,angle))

        @test get_gate_symbol(result_gate) isa type_result
    end

    # returns empty array
    result_gate=Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target,0.))

    @test isnothing(result_gate)

    result_gate=Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target,1e-3))

    @test get_gate_symbol(result_gate) isa Snowflurry.PhaseShift

    result_gate=Snowflurry.simplify_rz_gate(Snowflurry.phase_shift(target,1e-3),atol=1e-1)

    @test isnothing(result_gate)
end

@testset "SimplifyRzGatesTranspiler" begin
    transpiler = SimplifyRzGatesTranspiler()

    target=1

    test_inputs=[
        (phase_shift(target,pi/2),  Snowflurry.Z90)
        (phase_shift(target,-pi/2), Snowflurry.ZM90)
        (phase_shift(target,pi),    Snowflurry.SigmaZ)
        (phase_shift(target, pi/4), Snowflurry.Pi8)
        (phase_shift(target,-pi/4), Snowflurry.Pi8Dagger)
        (phase_shift(target,pi/3),  Snowflurry.PhaseShift)
    ]

    for (input_gate,type_result) in test_inputs
        circuit=QuantumCircuit(qubit_count=target, gates=[input_gate])

        transpiled_circuit=transpile(transpiler,circuit)

        @test compare_circuits(circuit,transpiled_circuit)

        @test get_gate_symbol(get_circuit_gates(transpiled_circuit)[1]) isa type_result
    end

    circuit=QuantumCircuit(qubit_count=target, gates=[phase_shift(target,0.)])

    transpiled_circuit=transpile(transpiler,circuit)

    @test compare_circuits(circuit,transpiled_circuit)

    @test length(get_circuit_gates(transpiled_circuit))==0

    # with default tolerance
    circuit=QuantumCircuit(qubit_count=target, gates=[phase_shift(target,1e-3)])

    transpiled_circuit=transpile(transpiler,circuit)

    @test length(get_circuit_gates(transpiled_circuit))==1

    # with user-defined tolerance

    transpiler=SimplifyRzGatesTranspiler(1e-1)

    transpiled_circuit=transpile(transpiler,circuit)

    @test length(get_circuit_gates(transpiled_circuit))==0
end

@testset "unsafe_compress_to_rz" begin
    target=1
    qubit_count=1

    test_inputs=[
        # single Rz-type gates
        [z_90(target)],
        [z_minus_90(target)],
        [sigma_z(target)],
        [pi_8(target)],
        [pi_8_dagger(target)],
        [phase_shift(target,pi/3)],

        # multiple Rz-type gates
        [z_90(target),pi_8(target)],
        [sigma_z(target),pi_8_dagger(target)],
        [phase_shift(target,pi/3),sigma_z(target),pi_8(target)],

        # mixture of Rz-type and other gates
        [z_90(target),pi_8(target),rotation_x(target,pi/5),pi_8(target)],
        [sigma_y(target),sigma_z(target),pi_8_dagger(target),hadamard(target)],
        [sigma_x(target),phase_shift(target,pi/3),sigma_z(target),pi_8(target)],

    ]

    for gates in test_inputs

    end

end

test_circuits_Rz_type=[
    [
        sigma_z(1),
        pi_8(1),
        phase_shift(1,pi/7),
        control_x(1,3),
        sigma_x(2),
        sigma_z(2),
        control_x(1,4),
        z_90(2),
        sigma_x(1),
        sigma_z(4),
        pi_8_dagger(4),
        toffoli(1,2,3),
        phase_shift(4,pi/3),
        pi_8_dagger(2)
    ],
    [   # all gates are `boundaries`
        control_x(1,3),
        sigma_x(2),
        sigma_y(2),
        control_x(4,2),
        hadamard(3),
        x_90(3),
        control_x(1,4),
        toffoli(1,4,3)
    ]
]

gates_in_output=[9,8]

@testset "CompressRzGatesTranspiler: transpilation of Rz-type and other gates" begin
    
    qubit_count=4
    transpiler=CompressRzGatesTranspiler()
    
    for (gates_list,gates_in_output) in zip(test_circuits_Rz_type,gates_in_output)
        for end_pos in 1:length(gates_list)

            truncated_input=gates_list[1:end_pos]

            circuit = QuantumCircuit(qubit_count = qubit_count, gates=truncated_input)
            
            transpiled_circuit=transpile(transpiler,circuit)

            @test compare_circuits(circuit,transpiled_circuit)

            if end_pos==length(gates_list)
                @test length(get_circuit_gates(transpiled_circuit))==gates_in_output
            end
        end
    end
end

@testset "remove_swap_by_swapping_gates" begin
    transpiler = RemoveSwapBySwappingGatesTranspiler()

    circuit =
        QuantumCircuit(qubit_count=4, gates=[hadamard(1), sigma_x(3), control_x(1, 4),
            swap(1, 2), swap(2, 3), sigma_x(2)])

    transpiled_circuit = transpile(transpiler, circuit)

    @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
    @test simulate(circuit) ≈ simulate(transpiled_circuit)

    circuit =
        QuantumCircuit(qubit_count=4, gates=[hadamard(1), sigma_x(3), control_x(1, 4),
            swap(1, 2), swap(1, 4), sigma_x(2)])

    transpiled_circuit = transpile(transpiler, circuit)

    @test !circuit_contains_gate_type(transpiled_circuit, Snowflurry.Swap)
    @test simulate(circuit) ≈ simulate(transpiled_circuit)
end

@testset "UnsupportedGatesTranspiler" begin
    
    circuit =QuantumCircuit(qubit_count=4, gates=[controlled(hadamard(2),[1])])

    @test_throws NotImplementedError transpile(UnsupportedGatesTranspiler(), circuit)

end
