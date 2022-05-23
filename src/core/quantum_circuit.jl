
"""
        QuantumCircuit(qubit_count = .., bit_count = ...)

A data structure to represnts a *quantum circuit*.  
**Fields**
- `qubit_count::Int` -- number of qubits (i.e. quantum register size).
- `bit_count::Int` -- number of classical bits (i.e. classical register size).
- `id::UUID` -- a universally unique identifier for the circuit. This id is automatically generated one an instance is created. 
- `pipeline::Array{Array{Gate}}` -- the pipeline of gates to operate on qubits.

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0)
Quantum Circuit Object:
   id: b2d2be56-7af2-11ec-31a6-ed9e71cb3360 
   qubit_count: 2 
   bit_count: 0 
q[1]:
     
q[2]:
```
"""
Base.@kwdef struct QuantumCircuit
    qubit_count::Int
    bit_count::Int
    id::UUID = UUIDs.uuid1()
    pipeline::Array{Array{Gate}} = []
end

"""
        push_gate!(circuit::QuantumCircuit, gate::Gate)
        push_gate!(circuit::QuantumCircuit, gates::Array{Gate})

Pushes a single gate or an array of gates to the `circuit` pipeline. This function is mutable. 

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

julia> push_gate!(c, [hadamard(1),sigma_x(2)])
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:--X----X--
```
"""
function push_gate!(circuit::QuantumCircuit, gate::Gate)
    push_gate!(circuit, [gate])
    return circuit
end

function push_gate!(circuit::QuantumCircuit, gates::Array{Gate})
    ensure_gates_are_in_circuit(circuit, gates)
    push!(circuit.pipeline, gates)
    return circuit
end

function ensure_gates_are_in_circuit(circuit::QuantumCircuit, gates::Array{Gate})
    for gate in gates
        for target in gate.target
            if target > circuit.qubit_count
                throw(DomainError(target, "the gate does no fit in the circuit"))
            end
        end
    end
end

"""
        pop_gate!(circuit::QuantumCircuit)

Removes the last gate from `circuit.pipeline`. 

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

julia> push_gate!(c, [hadamard(1),sigma_x(2)])
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:--X----X--

julia> pop_gate!(c)
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--
```
"""
function pop_gate!(circuit::QuantumCircuit)
    pop!(circuit.pipeline)
    return circuit
end

function Base.show(io::IO, circuit::QuantumCircuit)
    println(io, "Quantum Circuit Object:")
    println(io, "   id: $(circuit.id) ")
    println(io, "   qubit_count: $(circuit.qubit_count) ")
    println(io, "   bit_count: $(circuit.bit_count) ")

    wire_count = 2 * circuit.qubit_count
    circuit_layout = fill("", (wire_count, length(circuit.pipeline) + 1))

    for i_qubit in range(1, length = circuit.qubit_count)
        id_wire = 2 * (i_qubit - 1) + 1
        circuit_layout[id_wire, 1] = "q[$i_qubit]:"
        circuit_layout[id_wire+1, 1] = String(fill(' ', length(circuit_layout[id_wire, 1])))
    end

    i_step = 1
    for step in circuit.pipeline
        i_step += 1 # the first elemet of the layout is the qubit tag
        for i_qubit in range(1, length = circuit.qubit_count)
            id_wire = 2 * (i_qubit - 1) + 1
            # qubit wire
            circuit_layout[id_wire, i_step] = "-----"
            # spacer line
            circuit_layout[id_wire+1, i_step] = "     "
        end

        for gate in step
            for i_qubit in range(1, length = circuit.qubit_count)
                if (i_qubit in gate.target)
                    id_wire = 2 * (i_qubit - 1) + 1
                    id = findfirst(isequal(i_qubit), gate.target)
                    circuit_layout[id_wire, i_step] = "--$(gate.display_symbol[id])--"
                    if length(gate.target) > 1 && gate.target[1] == i_qubit
                        circuit_layout[id_wire+1, i_step] = "  |  "
                    end
                end
            end
        end
    end


    # circuit_layout[id_wire] = circuit_layout[id_wire] * ".\n"
    # circuit_layout[id_wire + 1] = circuit_layout[id_wire + 1] * ".\n"

    for i_wire in range(1, length = wire_count)
        for i_step in range(1, length = length(circuit.pipeline) + 1)
            # print(io, circuit_layout[i_wire, i_step])
            # println(io, "  i_wire=", i_wire, " i_step=", i_step)
            print(io, circuit_layout[i_wire, i_step])

        end
        println(io, "")
    end
end

"""
        simulate(circuit::QuantumCircuit)

Simulates and returns the wavefunction of the quantum device after running `circuit`. 

# Examples
```jldoctest
jjulia> push_gate!(c, hadamard(1))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:-----
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:-------X--
               


julia> simulate(c)
4-element Ket:
0.7071067811865475 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.7071067811865475 + 0.0im


```
"""
function simulate(circuit::QuantumCircuit)
    hilbert_space_size = 2^circuit.qubit_count
    system = MultiBodySystem(circuit.qubit_count, 2)
    # initial state 
    ψ = fock(0, hilbert_space_size)
    for step in circuit.pipeline 
        for gate in step 
            S = get_embed_operator(gate, system)
            ψ = S * ψ
        end

    end
    return ψ
end

function get_embed_operator(gate::Gate, system::MultiBodySystem)
    if length(gate.target) == 1
        return get_embed_operator(gate.operator, gate.target[1], system)
    else
        gate_to_operator =
            Dict("cz"=>get_embed_controlled_gate_operator(sigma_z(), gate, system),
            "cx"=>get_embed_controlled_gate_operator(sigma_x(), gate, system),
            "iswap"=>get_swap(gate, system))
        return gate_to_operator[gate.instruction_symbol]
    end
end

function get_embed_controlled_gate_operator(controlled_operator::Operator, gate::Gate,
    system::MultiBodySystem)
    control = gate.target[1]
    target = gate.target[2]
    lower_op_1, lower_op_2 = get_controlled_gate_operations_at_qubit(controlled_operator,
        control, target, 1)
    for i_qubit = 2:system.n_body
        upper_op_1, upper_op_2 =
            get_controlled_gate_operations_at_qubit(controlled_operator,
            control, target, i_qubit)
        lower_op_1 = kron(lower_op_1, upper_op_1)
        lower_op_2 = kron(lower_op_2, upper_op_2)
    end
    embed_operator = lower_op_1+lower_op_2
    return embed_operator
end

function get_controlled_gate_operations_at_qubit(controlled_operator, control, target,
    qubit_index)

    if control == qubit_index
        operation_1 = projector_0()
        operation_2 = projector_1()
    elseif target == qubit_index
        operation_1 = eye()
        operation_2 = controlled_operator
    else
        operation_1 = eye()
        operation_2 = eye()
    end
    return operation_1, operation_2
end

function get_swap(gate::Gate, system::MultiBodySystem)
    target_1 = gate.target[1]
    target_2 = gate.target[2]
    lower_operators =
        get_swap_at_qubit(target_1, target_2, 1)
    for i_qubit = 2:system.n_body
        upper_operators =
            get_swap_at_qubit(target_1, target_2, i_qubit)
        for i_operator in 1:length(lower_operators)
                lower_operators[i_operator] =
                    kron(lower_operators[i_operator], upper_operators[i_operator])
        end
    end
    embed_operator = sum(lower_operators)
    return embed_operator
end
    
function get_swap_at_qubit(target_1, target_2, qubit_index)

    if target_1 == qubit_index
        operation_1 = projector_0()
        operation_2 = im*sigma_p()
        operation_3 = im*sigma_m()
        operation_4 = projector_1()
    elseif target_2 == qubit_index
        operation_1 = projector_0()
        operation_2 = sigma_m()
        operation_3 = sigma_p()
        operation_4 = projector_1()
    else
        operation_1 = eye()
        operation_2 = eye()
        operation_3 = eye()
        operation_4 = eye()
    end
    return [operation_1, operation_2, operation_3, operation_4]
end

"""
        simulate_shots(c::QuantumCircuit, shots_count::Int = 100)

Emulates the function of a quantum computer by running a circuit for given number of shots and return measurement results.

# Examples
```jldoctest
julia> push_gate!(c, hadamard(1))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:-----
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:-------X--
               


julia> simulate_shots(c, 100)
100-element Vector{String}:
 "00"
 "00"
 "11"
 "00"
 "11"
 ⋮
 "11"
 "11"
 "11"
 "00"
 "11"
```
"""
function simulate_shots(c::QuantumCircuit, shots_count::Int = 100)
    # return simulateShots(c, shots_count)
    ψ = simulate(c)
    amplitudes = real.(ψ .* ψ)
    weights = Float32[]

    for a in amplitudes
        push!(weights, a)
    end

    ##preparing the labels
    labels = String[]
    for i in range(0, length = length(ψ))
        s = bitstring(i)
        n = length(s)
        s_trimed = s[n-c.qubit_count+1:n]
        push!(labels, s_trimed)
    end

    data = StatsBase.sample(labels, StatsBase.Weights(weights), shots_count)
    return data
end
