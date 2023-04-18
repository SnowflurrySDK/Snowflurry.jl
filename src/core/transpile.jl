using Snowflake

abstract type Transpiler end

transpile(t::Transpiler,::QuantumCircuit)= 
    throw(NotImplementedError(:transpile,t))

"""
    SequentialTranspiler(Vector{<:Transpiler})
    
Composite transpiler object which is constructed from an array 
of Transpiler stages. Calling 
    `transpile(::SequentialTranspiler,::QuantumCircuit)``
will apply each stage in sequence to the input circuit, and return
a transpiled output circuit. The result of the input and output 
circuit on any arbitrary state Ket is unchanged (up to a global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.SequentialTranspiler([Snowflake.CompressSingleQubitGatesTranspiler(),Snowflake.CastToPhaseShiftAndHalfRotationX()]);

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[sigma_x(1),hadamard(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X────H──
               
q[2]:──────────
               



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2
Part 1 of 2
q[1]:──P(-3.1416)────Rx(1.5708)────P(1.5708)────Rx(-1.5708)──

q[2]:────────────────────────────────────────────────────────


Part 2 of 2
q[1]:──P(3.1416)──

q[2]:─────────────
               



julia> circuit = QuantumCircuit(qubit_count = 3, gates=[sigma_x(1),sigma_y(1),control_x(2,3),phase_shift(1,π/3)])
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──X────Y─────────P(1.0472)──  

q[2]:────────────*───────────────
                 |               
q[3]:────────────X───────────────
                                 



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──P(-2.0944)───────
                        
q[2]:────────────────*──
                     |  
q[3]:────────────────X──
                        



```
"""  
struct SequentialTranspiler<:Transpiler
    stages::Vector{<:Transpiler}

    function SequentialTranspiler(stages::Vector{<:Transpiler})
        @assert length(stages)>0

        new(stages)
    end
end

function transpile(transpiler::SequentialTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    for stage in transpiler.stages
        circuit = transpile(stage, circuit)
    end

    return circuit
end

struct CompressSingleQubitGatesTranspiler<:Transpiler end

# convert a single-target gate to a Universal gate
function as_universal_gate(target::Integer,op::AbstractOperator)
    @assert size(op)==(2,2)
    
    matrix=get_matrix(op)

    #find global phase offset angle
    alpha=atan(imag(matrix[1,1]),real(matrix[1,1]) )
    
    #remove global offset
    matrix*=exp(-im*alpha)
    
    theta=(2*acos(real(matrix[1,1])))

    if (isapprox(theta,0.,atol=1e-6))||(isapprox(theta,2*π,atol=1e-6))
        lambda=0
        phi   =real(exp(-im*π/2)log( matrix[2,2]/cos(theta/2)))
    else
        lambda=real(exp(-im*π/2)*log(-matrix[1,2]/sin(theta/2)))
        phi   =real(exp(-im*π/2)*log( matrix[2,1]/sin(theta/2)))
    end

    # test if universal gate can be constructed from this operator
    @assert isapprox(real(matrix[2,2]),real(exp(im*(lambda+phi))*cos(theta/2)),atol=1e-6)
    @assert isapprox(imag(matrix[2,2]),imag(exp(im*(lambda+phi))*cos(theta/2)),atol=1e-6)

    return universal(target, theta, phi, lambda)
end

# compress (combine) several single-target gates with a common target to a Universal gate
function compress_to_universal(gates::Vector{<:AbstractGate})::Universal
    
    combined_op=eye()
    targets=get_connected_qubits(gates[1])

    @assert length(targets)==1 ("Received gate with multiple targets: $(gates[1])")

    common_target=targets[1]

    for gate in gates
        targets=get_connected_qubits(gate)
        @assert length(targets)==1 ("Received gate with multiple targets: $gate")
        @assert targets[1]==common_target ("Gates in array do not share common target")

        combined_op=get_operator(gate)*combined_op
    end

    return as_universal_gate(common_target,combined_op)
end

"""
    transpile(::CompressSingleQubitGatesTranspiler, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `CompressSingleQubitGatesTranspiler` transpiler stage 
which gathers all single-qubit gates sharing a common target in an input 
circuit and combines them into single universal gates in a new circuit.
Gates ordering may differ when gates are applied to different qubits, 
but the result of the input and output circuit on any arbitrary state Ket 
is unchanged (up to a global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.CompressSingleQubitGatesTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[sigma_x(1),sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X────Y──
               
q[2]:──────────
               



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──U(θ=0.0000,ϕ=3.1416,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                      



julia> circuit = QuantumCircuit(qubit_count = 3, gates=[sigma_x(1),sigma_y(1),control_x(2,3),phase_shift(1,π/3)])
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──X────Y─────────P(1.0472)──
                                 
q[2]:────────────*───────────────
                 |               
q[3]:────────────X───────────────
                                 



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──U(θ=0.0000,ϕ=-2.0944,λ=0.0000)───────
                                            
q[2]:────────────────────────────────────*──
                                         |  
q[3]:────────────────────────────────────X──
                                            




```
"""
function transpile(::CompressSingleQubitGatesTranspiler, circuit::QuantumCircuit)::QuantumCircuit

    gates=get_circuit_gates(circuit)
    if length(gates)==1
        return circuit
    end
    
    qubit_count=get_num_qubits(circuit)
    output_circuit=QuantumCircuit(qubit_count=qubit_count)

    # Split circuit into blocks of single-target gates that
    # share a common target, separated by boundaries (multi-target gates).
    # Common-target gates inside a block can be combined, 
    # but not with gates in another block,as a multi-target gate 
    # is present between them (a boundary). 
    # If first gate is multi-target, first block is left empty. 

    ######################################################
    #
    #  blocks_per_target is a Dict
    #   where:
    #       - keys    : the target numbers of qubits in circuit
    #       - values  : Vector{Vector{i_gate::Int}}
    #                   
    #           where:   - i_gate  : the gate's index in 'gates'
    #                    
    #                    - Vector{i_gate} : a block of common-target 
    #                       gates, with no boundary between them
    #
    #                    - Vector{Vector{i_gate}} : list of 
    #                       consecutive blocks, each separated by 
    #                       an entry in 'boundaries'   
    #     
    blocks_per_target=Dict{Int,Vector{Vector{Int}}}(Dict())

    #initialize empty blocks at all targets
    for target in 1:qubit_count
        blocks_per_target[target]=[[]]
    end

    ######################################################
    #
    #  boudaries is a Vector of Tuple{i_gate::Int,targets::Int}
    #  where:
    #       i_gate  : the gate's index in 'gates'
    #       targets : the targets of gate[i_gate]
    #               
    boundaries=Vector{Tuple{Int,Vector{Int}}}([]) 

    current_block=[1 for _ in 1:qubit_count]

    can_be_placed=Dict(target=>[true] for target in 1:qubit_count)

    placed_gates=[false for _ in 1:length(gates)]

    for (i_gate,gate) in enumerate(gates)
        targets=get_connected_qubits(gate)

        if length(targets)>1
            # multi-target gate

            # add group boundary at each of those targets
            push!(boundaries,(i_gate,targets))
            
            for target in targets
                # create new empty group at those targets
                push!(blocks_per_target[target],[])

                # disallow placement until boundary is passed
                push!(can_be_placed[target],false)
            end
                
        else
            # single-target gate
            target=targets[1]
            
            # inside a group, common-target gates are put in blocks.
            # append gate to last block
            push!(blocks_per_target[target][end],i_gate)
        end
    end

    # reverse so pop! returns first boundary
    boundaries=reverse(boundaries)

    iteration_count=0

    #build compressed circuit
    while true
        iteration_count+=1

        #place allowed blocks
        for target in 1:qubit_count

            block_index=current_block[target]

            if can_be_placed[target][block_index]

                block=blocks_per_target[target][block_index]

                gates_block=[gates[i] for i in block]

                if length(block)>1
                    push!(output_circuit,compress_to_universal(gates_block))
                    
                    for i_gate in block
                        placed_gates[i_gate]=true
                    end
                elseif length(block)==1
                    #no need to cast single gate to Universal
                    push!(output_circuit,gates_block[1])

                    placed_gates[block[1]]=true
                end

                can_be_placed[target][block_index]=false
            end
        end

        if !isempty(boundaries)
            # pass boundary
            (i_gate,targets)=pop!(boundaries)

            push!(output_circuit,gates[i_gate])
            placed_gates[i_gate]=true

            #unlock next blocks for those targets (boundary passed)
            for target in targets
                current_block[target]+=1
                can_be_placed[target][current_block[target]]=true
            end

        end

        if all(placed_gates)
            break
        end

        @assert iteration_count<length(gates)+1 ("Failed to construct output")
    end

    return output_circuit
end

function cast_to_cz(gate::Snowflake.AbstractGate)
    throw(NotImplementedError(:cast_to_cz_and_single_qubit_gates,gate))
end

function cast_to_cz(gate::Snowflake.Swap)::AbstractVector{Snowflake.AbstractGate}
    connected_qubits = get_connected_qubits(gate)
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    y90(q) = rotation_y(q, pi/2)
    ym90(q) = rotation_y(q, -pi/2)


    return Vector{AbstractGate}([
        ym90(q2),
        control_z(q1, q2),
        ym90(q1),
        y90(q2),
        control_z(q1, q2),
        y90(q1),
        ym90(q2),
        control_z(q1, q2),
        y90(q2),
    ])
end

struct CastSwapToCZGateTranspiler <: Transpiler end

"""
    transpile(::CastSwapToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `CastSwapToCZGateTranspiler` transpiler stage which
expands all Swap gates into CZ gates and single-qubit gates. The result of the
input and output circuit on any arbitrary state Ket is unchanged (up to a
global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.CastSwapToCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[swap(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
q[1]:──☒──
       |
q[2]:──☒──

julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2
Part 1 of 2
q[1]:─────────────────*────Ry(-1.5708)──────────────────*──
                      |                                 |
q[2]:──Ry(-1.5708)────Z───────────────────Ry(1.5708)────Z──


Part 2 of 2
q[1]:──Ry(1.5708)───────────────────*────────────────
                                    |
q[2]:────────────────Ry(-1.5708)────Z────Ry(1.5708)──
```
"""
function transpile(::CastSwapToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count=get_num_qubits(circuit)
    output=QuantumCircuit(qubit_count=qubit_count)

    for gate in get_circuit_gates(circuit)
        if gate isa Snowflake.Swap
            push!(output, cast_to_cz(gate))
        else
            push!(output, gate)
        end
    end

    return output
end

struct CastToPhaseShiftAndHalfRotationX<:Transpiler end

function cast_to_phase_shift_and_half_rotation_x(gate::Universal)
    params=get_gate_parameters(gate)
   
    target=get_connected_qubits(gate)[1]

    theta   =params["theta"]
    phi     =params["phi"]
    lambda  =params["lambda"]

    gate_array=Vector{AbstractGate}([])

    if !(isapprox(lambda,0.,atol=1e-6))
        push!(gate_array,phase_shift(target,lambda))
    end

    if !(isapprox(theta,0.,atol=1e-6))
        push!(gate_array,rotation_x( target,pi/2))
        push!(gate_array,phase_shift(target,theta))
        push!(gate_array,rotation_x( target,-pi/2))
    end

    if !(isapprox(phi,0.,atol=1e-6))
        push!(gate_array,phase_shift(target,phi))
    end

    return gate_array
end


"""
    transpile(::CastToPhaseShiftAndHalfRotationX, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `CastToPhaseShiftAndHalfRotationX` transpiler stage 
which converts all single-qubit gates in an input circuit and converts them 
into combinations of PhaseShift and RotationX with angle π/2 in an output 
circuit. For any gate in the input circuit, the number of gates in the 
output varies between zero and 5. The result of the input and output 
circuit on any arbitrary state Ket is unchanged (up to a global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.CastToPhaseShiftAndHalfRotationX();

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X──
          
q[2]:─────
          



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──P(-3.1416)────Rx(1.5708)────P(3.1416)────Rx(-1.5708)──
                                                             
q[2]:────────────────────────────────────────────────────────
                                                             



julia> circuit = QuantumCircuit(qubit_count = 2, gates=[sigma_z(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Z──
          
q[2]:─────
          



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──P(3.1416)──
                  
q[2]:─────────────
                  



julia> circuit = QuantumCircuit(qubit_count = 2, gates=[universal(1,0.,0.,0.)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──U(θ=0.0000,ϕ=0.0000,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                      



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:
     
q[2]:
     



```
"""
function transpile(::CastToPhaseShiftAndHalfRotationX, circuit::QuantumCircuit)::QuantumCircuit

    gates=get_circuit_gates(circuit)
    
    qubit_count=get_num_qubits(circuit)
    output_circuit=QuantumCircuit(qubit_count=qubit_count)

    for gate in gates

        targets=get_connected_qubits(gate)

        if length(targets)>1
            push!(output_circuit,gate)
        else
            if !(gate isa Snowflake.Universal)
                gate=as_universal_gate(targets[1],get_operator(gate))
            end

            gate_array=cast_to_phase_shift_and_half_rotation_x(gate)
            push!(output_circuit,gate_array)
        end
    end

    return output_circuit
end
