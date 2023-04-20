using Snowflake

abstract type Transpiler end

transpile(t::Transpiler,::QuantumCircuit)::QuantumCircuit= 
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
q[1]:──Z────X_90────Z_90────X_m90────Z──
                                                              
q[2]:───────────────────────────────────
                                                              



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
               



julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──U(θ=0.0000,ϕ=3.1416,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                      



julia> compare_circuits(circuit,transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 3, gates=[sigma_x(1),sigma_y(1),control_x(2,3),phase_shift(1,π/3)])
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──X────Y─────────P(1.0472)──
                                 
q[2]:────────────*───────────────
                 |               
q[3]:────────────X───────────────
                                 



julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──U(θ=0.0000,ϕ=-2.0944,λ=0.0000)───────
                                            
q[2]:────────────────────────────────────*──
                                         |  
q[3]:────────────────────────────────────X──
                                            




julia> compare_circuits(circuit,transpiled_circuit)
true

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
    throw(NotImplementedError(:cast_to_cz,gate))
end

function cast_to_cz(gate::Snowflake.Swap)::AbstractVector{Snowflake.AbstractGate}
    connected_qubits = get_connected_qubits(gate)
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    return Vector{AbstractGate}([
        y_minus_90(q2),
        control_z(q1, q2),
        y_minus_90(q1),
        y_90(q2),
        control_z(q1, q2),
        y_90(q1),
        y_minus_90(q2),
        control_z(q1, q2),
        y_90(q2),
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
q[1]:───────────*────Y_m90────────────*────Y_90─────────────*──────────
                |                     |                     |          
q[2]:──Y_m90────Z─────────────Y_90────Z────────────Y_m90────Z────Y_90──
                                              

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

function cast_to_cz(gate::Snowflake.ControlX)::AbstractVector{Snowflake.AbstractGate}
    connected_qubits = get_connected_qubits(gate)
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    return Vector{AbstractGate}([
        hadamard(q2),
        control_z(q1, q2),
        hadamard(q2),
    ])
end

struct CastCXToCZGateTranspiler <: Transpiler end

"""
    transpile(::CastCXToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `CastCZToCZGateTranspiler` transpiler stage which
expands all CX gates into CZ gates and single-qubit gates. The result of the
input and output circuit on any arbitrary state Ket is unchanged (up to a
global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.CastCXToCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[control_x(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
q[1]:──*──
       |
q[2]:──X──

julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2
q[1]:───────*───────
            |
q[2]:──H────Z────H──
```
"""
function transpile(::CastCXToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count=get_num_qubits(circuit)
    output=QuantumCircuit(qubit_count=qubit_count)

    for gate in get_circuit_gates(circuit)
        if gate isa Snowflake.ControlX
            push!(output, cast_to_cz(gate))
        else
            push!(output, gate)
        end
    end

    return output
end

function cast_to_cz(gate::Snowflake.ISwap)::AbstractVector{Snowflake.AbstractGate}
    connected_qubits = get_connected_qubits(gate)
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    return Vector{AbstractGate}([
        y_minus_90(q1),
        x_minus_90(q2),
        control_z(q1, q2),
        y_90(q1),
        x_minus_90(q2),
        control_z(q1, q2),
        y_90(q1),
        x_90(q2),
    ])
end

struct CastISwapToCZGateTranspiler <: Transpiler end

"""
    transpile(::CastISwapToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `CastISwapToCZGateTranspiler` transpiler stage which
expands all ISwap gates into CZ gates and single-qubit gates. The result of the
input and output circuit on any arbitrary state Ket is unchanged (up to a
global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.CastISwapToCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[iswap(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
q[1]:──x──
       |
q[2]:──x──

julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Y_m90─────────────*────Y_90─────────────*────Y_90──────────
                         |                     |                  
q[2]:───────────X_m90────Z────────────X_m90────Z────────────X_90──
                                                                  

```
"""
function transpile(::CastISwapToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count=get_num_qubits(circuit)
    output=QuantumCircuit(qubit_count=qubit_count)

    for gate in get_circuit_gates(circuit)
        if gate isa Snowflake.ISwap
            push!(output, cast_to_cz(gate))
        else
            push!(output, gate)
        end
    end

    return output
end

function cast_to_cx(gate::Toffoli)::AbstractVector{Snowflake.AbstractGate}
    connected_qubits = get_connected_qubits(gate)
    @assert length(connected_qubits) == 3
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]
    q3 = connected_qubits[3]

    h(q) = hadamard(q)
    cnot(q1, q2) = control_x(q1, q2)
    t(q) = pi_8(q)
    t_dag(q) = pi_8_dagger(q)

    return Vector{Snowflake.AbstractGate}([
        h(q3),
        cnot(q2,q3),
        t_dag(q3),
        cnot(q1, q3),
        t(q3),
        cnot(q2, q3),
        t_dag(q3),
        cnot(q1, q3),
        t(q2),
        t(q3),
        cnot(q1, q2),
        hadamard(q3),
        t(q1),
        t_dag(q2),
        cnot(q1, q2),
    ])
end

struct CastToffoliToCXGateTranspiler <: Transpiler end

"""
    transpile(::CastToffoliToCXGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `CastToffoliToCXGateTranspiler` transpiler stage which
expands all Toffoli gates into CX gates and single-qubit gates. The result of the
input and output circuit on any arbitrary state Ket is unchanged (up to a
global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.CastToffoliToCXGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 3, gates=[toffoli(1, 2, 3)])
Quantum Circuit Object:
   qubit_count: 3
q[1]:──*──
       |
q[2]:──*──
       |
q[3]:──X──

julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 3
Part 1 of 2
q[1]:──────────────────*────────────────────*──────────────*───────
                       |                    |              |
q[2]:───────*──────────|─────────*──────────|────T─────────X───────
            |          |         |          |
q[3]:──H────X────T†────X────T────X────T†────X─────────T─────────H──


Part 2 of 2
q[1]:──T──────────*──
                  |
q[2]:───────T†────X──

q[3]:────────────────```
"""
function transpile(::CastToffoliToCXGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count=get_num_qubits(circuit)
    output=QuantumCircuit(qubit_count=qubit_count)

    for gate in get_circuit_gates(circuit)
        if gate isa Snowflake.Toffoli
            push!(output, cast_to_cx(gate))
        else
            push!(output, gate)
        end
    end

    return output
end

struct CastToPhaseShiftAndHalfRotationX<:Transpiler 
    atol::Real
end

CastToPhaseShiftAndHalfRotationX()=CastToPhaseShiftAndHalfRotationX(1e-6)

function rightangle_or_arbitrary_phase_shift(target::Int,phase_angle::Real; atol=1e-6)
    if isapprox(phase_angle,π/2,atol=atol) 
        return z_90(target)

    elseif isapprox(abs(phase_angle),π,atol=atol) 
        return sigma_z(target)

    elseif isapprox(phase_angle,-π/2,atol=atol) 
        return z_minus_90(target)
    
    else
        return phase_shift(target,phase_angle)
    
    end
end

function simplify_rx_gate(
    target::Int,
    theta::Real; 
    atol=1e-6)::Union{AbstractGate,Nothing}
    
    if isapprox(theta,π/2,atol=atol) 
        return x_90(target)

    elseif isapprox(abs(theta),π,atol=atol) 
        return sigma_x(target)

    elseif isapprox(theta,-π/2,atol=atol) 
        return x_minus_90(target)
    
    elseif isapprox(theta,0.,atol=atol) 
        return nothing

    else
        return rotation_x(target,theta)
    
    end
end


function cast_to_phase_shift_and_half_rotation_x(gate::Universal;atol=1e-6)
    params=get_gate_parameters(gate)
   
    target=get_connected_qubits(gate)[1]

    theta   =params["theta"]
    phi     =params["phi"]
    lambda  =params["lambda"]

    gate_array=Vector{AbstractGate}([])

    if !(isapprox(lambda,0.,atol=atol))
        push!(
            gate_array,
            rightangle_or_arbitrary_phase_shift(target,lambda;atol=atol)
        )
    end

    if !(isapprox(theta,0.,atol=atol))
        push!(gate_array,x_90(target))
        push!(
            gate_array,
            rightangle_or_arbitrary_phase_shift(target,theta;atol=atol)
        )
        push!(gate_array,x_minus_90(target))
    end

    if !(isapprox(phi,0.,atol=atol))
        push!(
            gate_array,
            rightangle_or_arbitrary_phase_shift(target,phi;atol=atol)
        )
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
          



julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Z────X_90────Z────X_m90──
                                                 
q[2]:───────────────────────────
                                                 



julia> circuit = QuantumCircuit(qubit_count = 2, gates=[sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Y──
          
q[2]:─────
          



julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Z_90────X_90────Z────X_m90────Z_90──
                                           
q[2]:──────────────────────────────────────
                                           



julia> compare_circuits(circuit,transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[universal(1,0.,0.,0.)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──U(θ=0.0000,ϕ=0.0000,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                      



julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:
     
q[2]:
     



julia> compare_circuits(circuit,transpiled_circuit)
true

```
"""
function transpile(transpiler_stage::CastToPhaseShiftAndHalfRotationX, circuit::QuantumCircuit)::QuantumCircuit

    gates=get_circuit_gates(circuit)
    
    qubit_count=get_num_qubits(circuit)
    output_circuit=QuantumCircuit(qubit_count=qubit_count)

    atol=transpiler_stage.atol

    for gate in gates

        targets=get_connected_qubits(gate)

        if length(targets)>1
            push!(output_circuit,gate)
        else
            if !(gate isa Snowflake.Universal)
                gate=as_universal_gate(targets[1],get_operator(gate))
            end

            gate_array=cast_to_phase_shift_and_half_rotation_x(gate;atol=atol)
            push!(output_circuit,gate_array)
        end
    end

    return output_circuit
end

struct SimplifyRxGates<:Transpiler 
    atol::Real
end

SimplifyRxGates()=SimplifyRxGates(1e-6)

"""
    transpile(::SimplifyRxGates, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `SimplifyRxGates` transpiler stage 
which finds RotationX gates in an input circuit and according to it's 
angle theta, casts them to one of the right-angle RotationX gates, 
e.g. SigmaX, X90, or XM90. In the case where theta≈0., the gate is removed.
The result of the input and output circuit on any arbitrary state Ket is 
unchanged (up to a global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.SimplifyRxGates();

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[rotation_x(1,pi/2)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Rx(1.5708)──
                   
q[2]:──────────────
                   

julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X_90──
             
q[2]:────────
             

julia> compare_circuits(circuit,transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[rotation_x(1,pi)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Rx(3.1416)──
                   
q[2]:──────────────
                   


julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X──
          
q[2]:─────
          

julia> compare_circuits(circuit,transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, gates=[rotation_x(1,0.)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Rx(0.0000)──
                   
q[2]:──────────────
                   


julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:
     
q[2]:
     



julia> compare_circuits(circuit,transpiled_circuit)
true

```
"""
function transpile(transpiler_stage::SimplifyRxGates, circuit::QuantumCircuit)::QuantumCircuit

    qubit_count=get_num_qubits(circuit)
    output=QuantumCircuit(qubit_count=qubit_count)

    atol=transpiler_stage.atol

    for gate in get_circuit_gates(circuit)
        if gate isa Snowflake.RotationX
            new_gate=simplify_rx_gate(
                get_connected_qubits(gate)[1],
                get_gate_parameters(gate)["theta"];
                atol=atol
            )

            if !isnothing(new_gate)
                push!(output,new_gate)
            end
        else
            push!(output, gate)
        end
    end

    return output
end

struct PlaceOperationsOnLine<:Transpiler end

function remap_qubits_to_consecutive(connected_qubits::Vector{Int})::Tuple{Vector{Int},Vector{Int}}
    min_qubit=minimum(connected_qubits)

    sorting_order=sortperm(connected_qubits)

    # this contains an array of consecutive elements,
    # in the same unsorted order as the input,
    # meaning: sortperm(connected_qubits)==sortperm(mapped_indices)
    mapped_indices=sortperm(sorting_order)
    
    consecutive_mapping=[min_qubit+offset for offset in ([v-1 for v in mapped_indices])]

    return (consecutive_mapping,sorting_order)
end

function remap_connections_using_swaps(
    gates_block::Vector{<:AbstractGate},
    connected_qubits::Vector{Int},
    consecutive_mapping::Vector{Int}
    )::Vector{AbstractGate}

    for (previous_qubit_num,current_qubit_num) in zip(connected_qubits,consecutive_mapping)

        while !isequal(previous_qubit_num,current_qubit_num)
            # surround current gates_block with swap gates 
            # to bring one step closer
            gates_block=vcat(
                swap(current_qubit_num,current_qubit_num+1),
                gates_block,
                swap(current_qubit_num,current_qubit_num+1)
            )
            current_qubit_num+=1
        end
    end

    return gates_block
end


"""
    transpile(::PlaceOperationsOnLine, circuit::QuantumCircuit)::QuantumCircuit

Implementation of the `PlaceOperationsOnLine` transpiler stage 
which adds Swap gates around multi-qubit gates so that the 
final operator acts on adjacent qubits. The result of the input 
and output circuit on any arbitrary state Ket is unchanged 
(up to a global phase).

# Examples
```jldoctest
julia> transpiler=Snowflake.PlaceOperationsOnLine();

julia> circuit = QuantumCircuit(qubit_count = 6, gates=[toffoli(4,6,1)])
Quantum Circuit Object:
   qubit_count: 6 
q[1]:──X──
       |  
q[2]:──|──
       |  
q[3]:──|──
       |  
q[4]:──*──
       |  
q[5]:──|──
       |  
q[6]:──*──
          




julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 6 
q[1]:───────────────────────────X───────────────────────────
                                |                           
q[2]:───────☒───────────────────*───────────────────☒───────
            |                   |                   |       
q[3]:──☒────☒──────────────☒────*────☒──────────────☒────☒──
       |                   |         |                   |  
q[4]:──☒──────────────☒────☒─────────☒────☒──────────────☒──
                      |                   |                 
q[5]:────────────☒────☒───────────────────☒────☒────────────
                 |                             |            
q[6]:────────────☒─────────────────────────────☒────────────
                                                            



julia> compare_circuits(circuit,transpiled_circuit)
true

```
"""
function transpile(::PlaceOperationsOnLine, circuit::QuantumCircuit)::QuantumCircuit

    gates=get_circuit_gates(circuit)
    
    qubit_count=get_num_qubits(circuit)
    output_circuit=QuantumCircuit(qubit_count=qubit_count)

    for gate in gates

        connected_qubits=get_connected_qubits(gate)
        (consecutive_mapping,sorting_order)=remap_qubits_to_consecutive(connected_qubits)

        if length(consecutive_mapping)>1
    
            gates_block=[typeof(gate)(consecutive_mapping...)]

            @assert get_connected_qubits(gates_block[1])==consecutive_mapping (
                "Failed to construct gate: $(typeof((gates_block[1])))")

            # leaving first (minimum) qubit unchanged,
            # add swaps starting from the farthest qubit
            connected_qubits    =connected_qubits[   reverse(sorting_order[2:end])]
            consecutive_mapping =consecutive_mapping[reverse(sorting_order[2:end])]

            gates_block=remap_connections_using_swaps(
                gates_block,
                connected_qubits,
                consecutive_mapping
            )

            push!(output_circuit,gates_block)
        else
            # no effect for single-target gate
            push!(output_circuit,gate)
        end
    end

    return output_circuit

end

