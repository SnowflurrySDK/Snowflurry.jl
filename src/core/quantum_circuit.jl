
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
q[1]:──H──
          
q[2]:──X──
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H────*──
            |  
q[2]:──X────X──
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
q[1]:──H──
          
q[2]:──X──
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H────*──
            |  
q[2]:──X────X──

julia> pop_gate!(c)
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H──
          
q[2]:──X──
```
"""
function pop_gate!(circuit::QuantumCircuit)
    pop!(circuit.pipeline)
    return circuit
end

function Base.show(io::IO, circuit::QuantumCircuit, padding_width::Integer=10)
    println(io, "Quantum Circuit Object:")
    println(io, "   id: $(circuit.id) ")
    println(io, "   qubit_count: $(circuit.qubit_count) ")
    println(io, "   bit_count: $(circuit.bit_count) ")
    print_circuit_diagram(io, circuit, padding_width)
end

function print_circuit_diagram(io::IO, circuit::QuantumCircuit, padding_width::Integer)
    circuit_layout = get_circuit_layout(circuit)
    split_circuit_layouts = get_split_circuit_layout(io, circuit_layout, padding_width)
    num_splits = length(split_circuit_layouts)

    for i_split in 1:num_splits
        if num_splits > 1
            println(io, "Part $i_split of $num_splits")
        end
        for i_wire = 1:size(split_circuit_layouts[i_split], 1)
            for i_step = 1:size(split_circuit_layouts[i_split], 2)
                print(io, split_circuit_layouts[i_split][i_wire, i_step])
            end
            println(io, "")
        end
        println(io, "")
    end
end

function get_circuit_layout(circuit::QuantumCircuit)
    wire_count = 2 * circuit.qubit_count
    circuit_layout = fill("", (wire_count, length(circuit.pipeline) + 1))
    add_qubit_labels_to_circuit_layout!(circuit_layout, circuit.qubit_count)
    
    for (i_step, step) in enumerate(circuit.pipeline)
        longest_symbol_length = get_longest_symbol_length(step)
        add_wires_to_circuit_layout!(circuit_layout, i_step, circuit.qubit_count,
            longest_symbol_length)

        for gate in step
            add_coupling_lines_to_circuit_layout!(circuit_layout, gate, i_step,
                longest_symbol_length)
            add_target_to_circuit_layout!(circuit_layout, gate, i_step,
                longest_symbol_length)
        end
    end
    return circuit_layout
end

function get_longest_symbol_length(step::Array{Gate})
    largest_length = 0
    for gate in step
        for symbol in gate.display_symbol
            symbol_length = length(symbol)
            if symbol_length > largest_length
                largest_length = symbol_length
            end
        end
    end
    return largest_length
end

function add_qubit_labels_to_circuit_layout!(circuit_layout::Array{String},
    num_qubits::Integer)

    max_num_digits = ndigits(num_qubits)
    for i_qubit in range(1, length = num_qubits)
        num_digits = ndigits(i_qubit)
        padding = max_num_digits-num_digits
        id_wire = 2 * (i_qubit - 1) + 1
        circuit_layout[id_wire, 1] = "q[$i_qubit]:" * " "^padding
        circuit_layout[id_wire+1, 1] = String(fill(' ', length(circuit_layout[id_wire, 1])))
    end
end

function add_wires_to_circuit_layout!(circuit_layout::Array{String}, i_step::Integer,
    num_qubits::Integer, longest_symbol_length::Integer)

    num_chars = 4+longest_symbol_length
    for i_qubit in range(1, length = num_qubits)
        id_wire = 2 * (i_qubit - 1) + 1
        # qubit wire
        circuit_layout[id_wire, i_step+1] = "─"^num_chars
        # spacer line
        circuit_layout[id_wire+1, i_step+1] = " "^num_chars
    end
end

function add_coupling_lines_to_circuit_layout!(circuit_layout::Array{String}, gate::Gate,
    i_step::Integer, longest_symbol_length::Integer)
    
    length_difference = longest_symbol_length-1
    num_left_chars = 2 + floor(Int, length_difference/2)
    num_right_chars = 2 + ceil(Int, length_difference/2)
    min_wire = 2*(minimum(gate.target)-1)+1
    max_wire = 2*(maximum(gate.target)-1)+1
    for i_wire in min_wire+1:max_wire-1
        if iseven(i_wire)
            circuit_layout[i_wire, i_step+1] = ' '^num_left_chars * "|" *
                ' '^num_right_chars
        else
            circuit_layout[i_wire, i_step+1] = '─'^num_left_chars * "|" *
                '─'^num_right_chars
        end
    end
end

function add_target_to_circuit_layout!(circuit_layout::Array{String}, gate::Gate,
    i_step::Integer, longest_symbol_length::Integer)
    
    for (i_target, target) in enumerate(gate.target)
        symbol_length = length(gate.display_symbol[i_target])
        length_difference = longest_symbol_length-symbol_length
        num_left_dashes = 2 + floor(Int, length_difference/2)
        num_right_dashes = 2 + ceil(Int, length_difference/2)
        id_wire = 2*(target-1)+1
        circuit_layout[id_wire, i_step+1] = '─'^num_left_dashes *
            "$(gate.display_symbol[i_target])" * '─'^num_right_dashes
    end
end

function get_split_circuit_layout(io::IO, circuit_layout::Array{String},
    padding_width::Integer)

    (display_height, display_width) = displaysize(io)
    useable_width = display_width-padding_width
    num_steps = size(circuit_layout, 2)
    num_qubit_label_chars = length(circuit_layout[1, 1])
    char_count = num_qubit_label_chars
    first_gate_step = 2
    split_layout = []
    if num_steps == 1
        push!(split_layout, circuit_layout)
    end
    for i_step = 2:num_steps
        step = circuit_layout[1, i_step]
        num_chars_in_step = length(step)
        char_count += num_chars_in_step
        if char_count > useable_width
            push!(split_layout, hcat(circuit_layout[:,1],
                circuit_layout[:,first_gate_step:i_step-1]))
            char_count = num_qubit_label_chars + num_chars_in_step
            first_gate_step = i_step
        end
        if i_step == num_steps
            push!(split_layout, hcat(circuit_layout[:,1],
                circuit_layout[:,first_gate_step:i_step]))
        end
    end
    return split_layout
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
q[1]:──H──
          
q[2]:─────
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H────*──
            |  
q[2]:───────X──
               


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
            apply_gate_without_ket_size_check!(ψ, gate, circuit.qubit_count)
        end
    end
    return ψ
end

function apply_gate_without_ket_size_check!(state::Ket, gate::Gate, qubit_count)
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
q[1]:──H──
          
q[2]:─────
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H────*──
            |  
q[2]:───────X──
               


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

"""
    get_inverse(circuit::QuantumCircuit)

Return a `QuantumCircuit` which is the inverse of the input `circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2, bit_count=0);

julia> push_gate!(c, rotation_y(1, pi/4));

julia> push_gate!(c, control_x(1, 2))
Quantum Circuit Object:
   id: 47ddf072-7293-11ed-3d64-9f4fd1e69575 
   qubit_count: 2 
   bit_count: 0 
q[1]:──Ry(0.7853981633974483)────*──
                                 |  
q[2]:────────────────────────────X──
                                    



julia> get_inverse(c)
Quantum Circuit Object:
   id: 6153cc20-7293-11ed-37d4-e14a7e7df842 
   qubit_count: 2 
   bit_count: 0 
q[1]:──*────Ry(-0.7853981633974483)──
       |                             
q[2]:──X─────────────────────────────
                                     



```
"""
function get_inverse(circuit::QuantumCircuit)
    reverse_pipeline = reverse(circuit.pipeline)
    inverse_pipeline = Vector{Gate}[]
    for step in reverse_pipeline
        inverse_gate_list = Gate[]
        for gate in step
            push!(inverse_gate_list, get_inverse(gate))
        end
        push!(inverse_pipeline, inverse_gate_list)
    end
    return QuantumCircuit(qubit_count=circuit.qubit_count, bit_count=circuit.bit_count,
        pipeline=inverse_pipeline)
end
