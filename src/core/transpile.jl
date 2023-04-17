using Snowflake

abstract type Transpiler end

transpile(t::Transpiler,::QuantumCircuit)= 
    throw(NotImplementedError(:transpile,t))

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

struct CastToNativeGatesTranspiler<:Transpiler end

function cast_to_native(gate::Universal)
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

function transpile(::CastToNativeGatesTranspiler, circuit::QuantumCircuit)::QuantumCircuit

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

            gate_array=cast_to_native(gate)
            push!(output_circuit,gate_array)
        end
    end

    return output_circuit
end

function get_transpiler(qpu::QPU)::Transpiler
    return SequentialTranspiler([
        CompressSingleQubitGatesTranspiler(),
        CastToNativeGatesTranspiler()
    ])
end