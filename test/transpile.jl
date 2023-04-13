using Snowflake
using Test

target=1
theta=π
phi=π/4
lambda=π/8

single_qubit_gates=[
    hadamard(target),
    phase(target),
    phase_dagger(target),
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
    x_90(target)
]

# circuits are equivalent if they both yield the same output for any input.
# circuits with different ordering of gates that apply on different targets
# can also be equivalent
function compare_circuits(c0::QuantumCircuit,c1::QuantumCircuit)

    num_qubits=get_num_qubits(c0)

    @test num_qubits==get_num_qubits(c1)

    #non-normalized ket with different scalar at each position
    ψ_0=Ket([v for v in 1:2^num_qubits])
        
    for gate in get_circuit_gates(c0) 
        apply_gate!(ψ_0, gate)
    end

    ψ_1=Ket([v for v in 1:2^num_qubits])

    for gate in get_circuit_gates(c1) 
        apply_gate!(ψ_1, gate)        
    end

    # check equality allowing a global phase offset
    return compare_kets(ψ_0,ψ_1)
end

# check for equality allowing for a global phase difference
function compare_kets(ψ_0::Ket,ψ_1::Ket)
    
    # calculate possible global phase offset angle
    # from first component 
    θ_0=atan(imag(ψ_0.data[1]),real(ψ_0.data[1]) )
    θ_1=atan(imag(ψ_1.data[1]),real(ψ_1.data[1]) )

    δ=θ_0-θ_1

    #apply phase offset
    ψ_1_prime=exp(im*δ)*ψ_1

    return ψ_0≈ψ_1_prime
end

@testset "get_universal" begin
    for gate in single_qubit_gates    
        universal_equivalent=get_universal(target,get_operator(gate))
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

    qpu = create_virtual_qpu(3,Matrix([1 1 0; 1 1 1 ; 0 1 1]), ["x"])

    transpiler=get_transpiler(qpu)

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
    
    qubit_count=3

    qpu = create_virtual_qpu(qubit_count,Matrix([1 1 0; 1 1 1 ; 0 1 1]), ["x"])
    
    transpiler=get_transpiler(qpu)
    
    input_gates=[
        sigma_x(1),
        sigma_y(1),
        sigma_x(3),
        hadamard(2),
        sigma_x(1),
        control_x(1,2),
        sigma_x(2),
        sigma_x(1),
        sigma_y(1),
        hadamard(2),
        control_x(1,3),
        sigma_z(3),    
        phase_shift(1,π/10),
        sigma_x(1),
    ]
    
    #compressing single input gate does nothing
    circuit = QuantumCircuit(qubit_count = qubit_count, gates=input_gates)
    
    transpiled_circuit=transpile(transpiler,circuit)

    println("input circuit: $circuit")
    println("transpiled circuit: $transpiled_circuit")

    @test compare_circuits(circuit,transpiled_circuit)

end