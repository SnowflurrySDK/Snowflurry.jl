using Snowflurry
using Test

target=1
qubit_count=1
phi=π/3
theta=π/5
lambda=π/7

@testset "SimplifyTrivialGatesTranspiler" begin

    transpiler=SimplifyTrivialGatesTranspiler()

    inputs=[
        #gates_input,                gate_count_output
        ([identity_gate(target)],       0),

        ([universal(target,0. ,0.   , 0.    )], 0),
        ([universal(target,0. ,0.   , lambda)], 1),
        ([universal(target,0. ,theta, 0.    )], 1),
        ([universal(target,0. ,theta, lambda)], 1),
        ([universal(target,phi,0.   , 0.    )], 1),
        ([universal(target,phi,0.   , lambda)], 1),
        ([universal(target,phi,theta, 0.    )], 1),
        ([universal(target,phi,theta, lambda)], 1),
        
        ([rotation(target,phi,theta )], 1),
        ([rotation(target,phi,0.    )], 1),
        ([rotation(target,0. ,theta )], 1),
        ([rotation(target,0. ,0. )],    0),

        ([rotation_x(target,theta)],    1),
        ([rotation_x(target,0.)],   0),

        ([rotation_y(target,theta)],   1),
        ([rotation_y(target,0.)],   0),

        ([phase_shift(target,theta)],   1),
        ([phase_shift(target,0.)],   0),
        
        ([
            identity_gate(target), 
            universal(target,0. ,0.   , 0.    ),
            rotation(target,0. ,0. ),
            rotation_x(target,0.),
            rotation_y(target,0.),
            phase_shift(target,0.)
        ],   0),
    ]

    for (gates_input, gates_count_output) in inputs

        circuit = QuantumCircuit(
            qubit_count = qubit_count, 
            gates=gates_input)
    
        transpiled_circuit=transpile(transpiler,circuit)
    
        gates=get_circuit_gates(transpiled_circuit)

        @test length(gates)==gates_count_output 

        @test compare_circuits(circuit,transpiled_circuit)  
    end

end

@testset "SimplifyTrivialGatesTranspiler: tolerance" begin
    
    #default tolerance
    transpiler=SimplifyTrivialGatesTranspiler()

    circuit = QuantumCircuit(qubit_count = 2, gates=[universal(target,1e-3,1e-3,1e-3)])
    
    transpiled_circuit=transpile(transpiler,circuit)
    
    gates=get_circuit_gates(transpiled_circuit)
    
    @test length(gates)==1
    
    @test compare_circuits(circuit,transpiled_circuit)
    
    # user-defined tolerance
    transpiler=SimplifyTrivialGatesTranspiler(1e-1)

    circuit = QuantumCircuit(qubit_count = 2, gates=[universal(target,1e-3,1e-3,1e-3)])
    
    transpiled_circuit=transpile(transpiler,circuit)
    
    gates=get_circuit_gates(transpiled_circuit)
    
    @test length(gates)==0

end 

@testset "SequentialTranspiler: Compress and simplify gates" begin    
    
    transpiler=Snowflurry.SequentialTranspiler([
        CompressSingleQubitGatesTranspiler(),
        SimplifyTrivialGatesTranspiler(),
    ])

    inputs=[
        #gates_input,                gate_count_output
        ([sigma_x(1)],                          1),
        ([sigma_x(1),sigma_x(1)],               0),

        ([sigma_y(1)],                          1),
        ([sigma_y(1),sigma_y(1)],               0),

        ([sigma_z(1)],                          1),
        ([sigma_z(1),sigma_z(1)],               0),

        ([x_90(1)],                             1),
        ([x_90(1),x_minus_90(1)],               0),
        ([x_90(1),x_90(1),x_90(1),x_90(1)],     0),
        ([x_minus_90(1),x_minus_90(1),x_minus_90(1),x_minus_90(1)],     0),

        ([y_90(1)],                             1),
        ([y_90(1),y_minus_90(1)],               0),
        ([y_90(1),y_90(1),y_90(1),y_90(1)],     0),
        ([y_minus_90(1),y_minus_90(1),y_minus_90(1),y_minus_90(1)],     0),

        ([z_90(1)],                             1),
        ([z_90(1),z_minus_90(1)],               0),
        ([z_90(1),z_90(1),z_90(1),z_90(1)],     0),
        ([z_minus_90(1),z_minus_90(1),z_minus_90(1),z_minus_90(1)],     0),
    ]

    for (gates_input, gates_count_output) in inputs

        circuit = QuantumCircuit(
            qubit_count = qubit_count, 
            gates=gates_input)
    
        transpiled_circuit=transpile(transpiler,circuit)
    
        gates=get_circuit_gates(transpiled_circuit)

        @test length(gates)==gates_count_output 

        @test compare_circuits(circuit,transpiled_circuit)  
    end
end
