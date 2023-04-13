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

    return get_universal(common_target,combined_op)
end

function transpile(::CompressSingleQubitGatesTranspiler, circuit::QuantumCircuit)::QuantumCircuit

    num_qubits=get_num_qubits(circuit)

    gates=get_circuit_gates(circuit)
    if length(gates)==1
        return circuit
    end
    
    qubit_count=get_num_qubits(circuit)
    output_circuit=QuantumCircuit(qubit_count=qubit_count)

    # split circuit into groups of single-target gates separated by
    # boundaries (multi-target gates). If first gate is multi-target, 
    # first group is left empty. Inside each group, gates are put in 
    # blocks of gates that share a common target

    groups=Vector{Dict{Int,Vector{Int}}}([Dict()])
    boundaries=Vector{Int}([])

    for (i_gate,gate) in enumerate(gates)
        targets=get_connected_qubits(gate)

        if length(targets)>1
            #multi-target gate

            #create group boundary
            push!(boundaries,i_gate)
           
            #create new group
            push!(groups,Dict())
        else
            # inside a group, common-target gates are put in blocks

            target=targets[1]

            if haskey(groups[end],target)
                # block for this target already present
                push!(groups[end][target],i_gate) 
            else
                groups[end][target]=[i_gate] #new block
            end
        end
    end
    
    for (i_group,group) in enumerate(groups)
      
        for (target,block) in group

            gates_block=[gates[i] for i in block]

            if length(gates_block)>1
                push!(output_circuit,compress_to_universal(gates_block))
            else
                #no need to cast single gate to Universal
                push!(output_circuit,gates_block[1])
            end
        end 

        if length(boundaries)>=i_group
            push!(output_circuit,gates[boundaries[i_group]])
        end
    end

    return output_circuit
end

function get_transpiler(qpu::QPU)::Transpiler
    return SequentialTranspiler([
        CompressSingleQubitGatesTranspiler(),
    ])
end
