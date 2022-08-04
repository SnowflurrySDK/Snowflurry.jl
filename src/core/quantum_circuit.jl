
"""
        QuantumCircuit(qubit_count = .., bit_count = ...)

A data structure to represent a *quantum circuit*.  
# Fields
- `qubit_count::Int` -- number of qubits (i.e. quantum register size).
- `bit_count::Int` -- number of classical bits (i.e. classical register size).
- `id::UUID` -- a universally unique identifier for the circuit. A UUID is automatically generated once an instance is created. 
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

"""
    append!(base_circuit::QuantumCircuit, circuits_to_append::QuantumCircuit...)

Appends circuits to the `base_circuit`. The `circuits_to_append` cannot have more qubits
than the `base_circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2, bit_count=0);

julia> push_gate!(c, [hadamard(1), sigma_x(2)])
Quantum Circuit Object:
   id: d64381ca-1360-11ed-2fc3-7b86db8b7417 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--


julia> c1 = QuantumCircuit(qubit_count=1, bit_count=0);

julia> push_gate!(c1, [sigma_x(1)])
Quantum Circuit Object:
   id: ed46d94e-1360-11ed-3c11-33df7e129e0b 
   qubit_count: 1 
   bit_count: 0 
q[1]:--X--


julia> c2 = QuantumCircuit(qubit_count=2, bit_count=0);

julia> push_gate!(c2, [control_z(1,2)])
Quantum Circuit Object:
   id: fd6df078-1360-11ed-19e5-cf1aa91338b3 
   qubit_count: 2 
   bit_count: 0 
q[1]:--*--
       |  
q[2]:--Z--


julia> append!(c, c1, c2);

julia> print(c)
Quantum Circuit Object:
   id: d64381ca-1360-11ed-2fc3-7b86db8b7417 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----X----*--
                 |  
q[2]:--X---------Z--


```
"""
function Base.append!(base_circuit::QuantumCircuit, circuits_to_append::QuantumCircuit...)
    for circuit in circuits_to_append
        if base_circuit.qubit_count < circuit.qubit_count
            throw(ErrorException(
                "the circuit to append cannot be wider than the base circuit"))
        end
        append!(base_circuit.pipeline, circuit.pipeline)
    end
end

"""
    get_wider_circuit(circuit::QuantumCircuit, num_qubits::Int)

Return a copy of `circuit` but with a width of `num_qubits`. `num_qubits` cannot be less
than the width of `circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2, bit_count=0);

julia> push_gate!(c, [hadamard(1), sigma_x(2)])
Quantum Circuit Object:
   id: c6bc82e2-1365-11ed-1a9f-757e431ca715 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--


julia> wider_circuit = get_wider_circuit(c, 3)
Quantum Circuit Object:
   id: e28ec322-1365-11ed-06e3-ddae6aeb2c36 
   qubit_count: 3 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--
          
q[3]:-----


```
"""
function get_wider_circuit(circuit::QuantumCircuit, num_qubits::Int)
    if circuit.qubit_count > num_qubits
        throw(ErrorException("num_qubits cannot be less than the circuit width"))
    end
    new_circuit = QuantumCircuit(qubit_count=num_qubits,
        bit_count=circuit.bit_count, pipeline=circuit.pipeline)
    return new_circuit
end

"""
    get_reordered_circuit(circuit::QuantumCircuit, qubit_map::Dict{Int, Int})

Returns a circuit containing the gates of the input `circuit`. The gates are reordered
according to the `qubit_map`. Qubits which are not reordered do not need to
be included in the `qubit_map`. Qubits are added to the new circuit if necessary.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2, bit_count=0);

julia> push_gate!(c, [hadamard(1), sigma_x(2)])
Quantum Circuit Object:
   id: 5930787e-133c-11ed-3e7c-3701268d56db 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--


julia> new_c = get_reordered_circuit(c, Dict(1=>3))
Quantum Circuit Object:
   id: 7ff7f0da-1344-11ed-1ab8-03b49d30363b 
   qubit_count: 3 
   bit_count: 0 
q[1]:-----
          
q[2]:--X--
          
q[3]:--H--


```
"""
function get_reordered_circuit(circuit::QuantumCircuit, qubit_map::Dict{Int, Int})
    assert_qubit_mapping_is_valid(qubit_map, circuit.qubit_count)
    pipeline = Array{Gate}[]
    for moment in circuit.pipeline
        new_moment = Gate[]
        for gate in moment
            new_target = Int[]
            for single_target in gate.target
                if haskey(qubit_map, single_target)
                    push!(new_target, qubit_map[single_target])
                else
                    push!(new_target, single_target)
                end
            end
            new_gate = copy(gate, new_target)
            push!(new_moment, new_gate)
        end
        push!(pipeline, new_moment)
    end
    largest_new_qubit_id = maximum(values(qubit_map))
    qubit_count = max(circuit.qubit_count, largest_new_qubit_id)
    new_circuit = QuantumCircuit(qubit_count=qubit_count,
        bit_count=circuit.bit_count, pipeline=pipeline)
    return new_circuit
end

function assert_qubit_mapping_is_valid(qubit_map, qubit_count)
    unique_values = unique(values(qubit_map))
    if length(unique_values) != length(qubit_map)
        throw(ErrorException("the qubit map is not injective"))
    end

    for qubit_pair in qubit_map
        target_qubit = qubit_pair.second
        if target_qubit <= qubit_count && !haskey(qubit_map, target_qubit)
            throw(ErrorException("the qubit map is not valid"))
        end
    end
end

function Base.show(io::IO, circuit::QuantumCircuit)
    println(io, "Quantum Circuit Object:")
    println(io, "   id: $(circuit.id) ")
    println(io, "   qubit_count: $(circuit.qubit_count) ")
    println(io, "   bit_count: $(circuit.bit_count) ")
    print_circuit_diagram(io, circuit)
end

function print_circuit_diagram(io, circuit)
    circuit_layout = get_circuit_layout(circuit)
    num_wires = size(circuit_layout, 1)
    pipeline_length = size(circuit_layout, 2)
    for i_wire in range(1, length = num_wires-1)
        for i_step in range(1, length = pipeline_length)
            print(io, circuit_layout[i_wire, i_step])
        end
        println(io, "")
    end
end

function get_circuit_layout(circuit)
    wire_count = 2 * circuit.qubit_count
    circuit_layout = fill("", (wire_count, length(circuit.pipeline) + 1))
    add_qubit_labels_to_circuit_layout!(circuit_layout, circuit.qubit_count)
    
    for i_step in 1:length(circuit.pipeline)
        step = circuit.pipeline[i_step]
        add_wires_to_circuit_layout!(circuit_layout, i_step, circuit.qubit_count)

        for gate in step
            add_coupling_lines_to_circuit_layout!(circuit_layout, gate, i_step)
            add_target_to_circuit_layout!(circuit_layout, gate, i_step)
        end
    end
    return circuit_layout
end

function add_qubit_labels_to_circuit_layout!(circuit_layout, num_qubits)
    for i_qubit in range(1, length = num_qubits)
        id_wire = 2 * (i_qubit - 1) + 1
        circuit_layout[id_wire, 1] = "q[$i_qubit]:"
        circuit_layout[id_wire+1, 1] = String(fill(' ', length(circuit_layout[id_wire, 1])))
    end
end

function add_wires_to_circuit_layout!(circuit_layout, i_step, num_qubits)
    for i_qubit in range(1, length = num_qubits)
        id_wire = 2 * (i_qubit - 1) + 1
        # qubit wire
        circuit_layout[id_wire, i_step+1] = "-----"
        # spacer line
        circuit_layout[id_wire+1, i_step+1] = "     "
    end
end

function add_coupling_lines_to_circuit_layout!(circuit_layout, gate, i_step)
    min_wire = 2*(minimum(gate.target)-1)+1
    max_wire = 2*(maximum(gate.target)-1)+1
    for i_wire in min_wire+1:max_wire-1
        if iseven(i_wire)
            circuit_layout[i_wire, i_step+1] = "  |  "
        else
            circuit_layout[i_wire, i_step+1] = "--|--"
        end
    end
end

function add_target_to_circuit_layout!(circuit_layout, gate, i_step)
    for i_target in 1:length(gate.target)
        single_target = gate.target[i_target]
        id_wire = 2*(single_target-1)+1
        circuit_layout[id_wire, i_step+1] = "--$(gate.display_symbol[i_target])--"
    end
end

"""
        simulate(circuit::QuantumCircuit)

Simulates and returns the wavefunction of the quantum device after running `circuit`. 

Employs the approach described in Listing 5 of
[Suzuki *et. al.* (2021)](https://doi.org/10.22331/q-2021-10-06-559).

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

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
               


julia> ket = simulate(c);

julia> print(ket)
4-element Ket:
0.7071067811865475 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.7071067811865475 + 0.0im


```
"""
function simulate(circuit::QuantumCircuit)
    hilbert_space_size = 2^circuit.qubit_count
    # initial state 
    ψ = fock(0, hilbert_space_size)
    for step in circuit.pipeline 
        for gate in step
            apply_gate!(ψ, gate, circuit.qubit_count)
        end
    end
    return ψ
end

function apply_gate!(state::Ket, gate::Gate, qubit_count)
    b0 = get_b0_bases_list(gate, qubit_count)
    b1 = get_b1_bases_list(gate, qubit_count)
    temp_state = zeros(Complex, length(b1))
    for x0 in b0
        for (index, x1) in enumerate(b1)
            temp_state[index] = state.data[x0+x1+1]
        end
        temp_state = gate.operator.data*temp_state
        for (index, x1) in enumerate(b1)
            state.data[x0+x1+1] = temp_state[index]
        end
    end
end

function get_b0_bases_list(gate::Gate, qubit_count)
    num_targets = length(gate.target)
    num_b0_bases = 2^(qubit_count-num_targets)
    pattern = get_b0_pattern(gate, qubit_count)
    b0_bitstrings = fill(pattern, num_b0_bases)
    fill_bit_string_list!(b0_bitstrings, pattern)
    b0 = get_int_list(b0_bitstrings)
    return b0
end

function get_b0_pattern(gate::Gate, qubit_count)
    pattern = ""
    for i_qubit in 1:qubit_count
        if i_qubit in gate.target
            pattern = pattern * '0'
        else
            pattern = pattern * 'x'
        end
    end
    return pattern
end

function fill_bit_string_list!(list, pattern)
    fill_bit_string_list_and_return_counter!(list, pattern)
end

function fill_bit_string_list_and_return_counter!(list, pattern, counter=1)
    if !('x' in pattern)
        list[counter] = pattern
        counter += 1
        return counter
    else
        pattern_with_0 = replace(pattern, 'x'=>'0', count=1)
        counter = fill_bit_string_list_and_return_counter!(list, pattern_with_0, counter)

        pattern_with_1 = replace(pattern, 'x'=>'1', count=1)
        counter = fill_bit_string_list_and_return_counter!(list, pattern_with_1, counter)
        return counter
    end
end

function get_int_list(bitstring_list)
    int_list = Vector{Int}(undef, length(bitstring_list))
    for (i_string, bitstring) in enumerate(bitstring_list)
        int_list[i_string] = parse(Int, bitstring, base=2)
    end
    return int_list
end

function get_b1_bases_list(gate::Gate, qubit_count)
    num_targets = length(gate.target)
    target_space_bitstrings = get_bitstring_vector_for_target_space(num_targets)
    b1_bitstrings = get_b1_bitstrings(gate, target_space_bitstrings, qubit_count)
    b1 = get_int_list(b1_bitstrings)
    return b1
end

function get_bitstring_vector_for_target_space(num_targets)
    num_bases = 2^num_targets
    bitstrings = fill('0'^num_targets, num_bases)
    for i_basis = 0:num_bases-1
        raw_bitsring = bitstring(i_basis)
        formatted_bitstring = raw_bitsring[end-num_targets+1:end]
        bitstrings[i_basis+1] = formatted_bitstring
    end
    return bitstrings
end

function get_b1_bitstrings(gate::Gate, target_space_bitstrings, qubit_count)
    num_bases = length(target_space_bitstrings)
    bitstring_list = fill('0'^qubit_count, num_bases)
    for (i_basis, bitstring) in enumerate(bitstring_list)
        bitstring_as_chars = collect(bitstring)
        for (i_target, target) in enumerate(gate.target)
            bitstring_as_chars[target] = target_space_bitstrings[i_basis][i_target]
        end
        bitstring_list[i_basis] = join(bitstring_as_chars)
    end
    return bitstring_list
end

"""
        simulate_shots(c::QuantumCircuit, shots_count::Int = 100)

Emulates a quantum computer by running a circuit for a given number of shots and returning measurement results.

# Examples
```jldoctest simulate_shots; filter = r"00|11"
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

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
               


julia> simulate_shots(c, 99)
99-element Vector{String}:
 "11"
 "00"
 "11"
 "11"
 "11"
 "11"
 "11"
 "00"
 "00"
 "11"
 ⋮
 "00"
 "00"
 "11"
 "00"
 "00"
 "00"
 "00"
 "00"
 "00"
```
"""
function simulate_shots(c::QuantumCircuit, shots_count::Int = 100)
    # return simulateShots(c, shots_count)
    ψ = simulate(c)
    amplitudes = adjoint.(ψ) .* ψ
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
