
"""
    QuantumCircuit(qubit_count)

A data structure to represent a *quantum circuit*.  
# Fields
- `qubit_count::Int` -- number of qubits (i.e. quantum register size).
- `pipeline::Array{Array{Gate}}` -- the pipeline of gates to operate on qubits.

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:
     
q[2]:
```
"""
Base.@kwdef struct QuantumCircuit
    qubit_count::Int
    pipeline::Vector{AbstractGate} = []
end

"""
    push_gate!(circuit::QuantumCircuit, gate::AbstractGate)
    push_gate!(circuit::QuantumCircuit, gates::Array{AbstractGate})

Pushes a single gate or an array of gates to the `circuit` pipeline. This function is mutable. 

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2);

julia> push_gate!(c, [hadamard(1),sigma_x(2)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────X────X──
                    



```
"""
function push_gate!(circuit::QuantumCircuit, gate::AbstractGate)
    ensure_gate_is_in_circuit(circuit, gate)
    push!(circuit.pipeline, gate)
    return circuit
end

function push_gate!(circuit::QuantumCircuit, gates::Vector{<:AbstractGate})
    for gate in gates
        push_gate!(circuit, gate)
    end
    return circuit
end

function ensure_gate_is_in_circuit(circuit::QuantumCircuit, gate::AbstractGate)
    for target in gate.target
        if target > circuit.qubit_count
            throw(DomainError(target, "the gate does no fit in the circuit"))
        end
    end
end

formatter(str_label,args...) = @eval @sprintf($str_label,$args...)

get_display_symbol(gate::AbstractGate)=gates_display_symbols[typeof(gate)]

function get_display_symbol(gate::ParameterizedGate;precision::Integer=4)

    params=Vector{Real}([])

    for key in ["theta","phi","lambda"]
        if key in keys(gate_params)
            push!(gate_params,gate_params[key])
        end
    end

    symbol_gate=gates_display_symbols[typeof(gate)][1]
    repetitions=gates_display_symbols[typeof(gate)][2]
    precisionStr=string("%.",precision,"f")
    precisionArray=[precisionStr for _ in 1:repetitions]

    str_label_with_precision=formatter(
        symbol_gate,
        precisionArray...
    )
    return [formatter(str_label_with_precision,params...)]
end

gates_display_symbols=Dict(
    SigmaX      =>["X"],
    SigmaY      =>["Y"],
    SigmaZ      =>["Z"],
    Hadamard    =>["H"],
    Phase       =>["S"],
    PhaseDagger =>["S†"],
    Pi8         =>["T"],
    Pi8Dagger   =>["T†"],
    X90         =>["X_90"],
    Rotation    =>["R(θ=%s,ϕ=%s)",2],
    RotationX   =>["Rx(%s)",1],
    RotationY   =>["Ry(%s)",1],
    RotationZ   =>["Rz(%s)",1],
    PhaseShift  =>["P(%s)",1],
    Universal   =>["U(θ=%s,ϕ=%s,λ=%s)",3],
    ControlZ    =>["*", "Z"],
    ControlX    =>["*", "X"],
    ISwap       =>["x", "x"],
    ISwapDagger =>["x†", "x†"],
    Toffoli     =>["*", "*", "X"],
)

get_instruction_symbol(gate::AbstractGate)=gates_instruction_symbols[typeof(gate)]

gates_instruction_symbols=Dict(
    SigmaX      =>"x",
    SigmaY      =>"y",
    SigmaZ      =>"z",
    Hadamard    =>"h",
    Phase       =>"s",
    PhaseDagger =>"s_dag",
    Pi8         =>"t",
    Pi8Dagger   =>"t_dag",
    X90         =>"x_90",
    Rotation    =>"r",
    RotationX   =>"rx",
    RotationY   =>"ry",
    RotationZ   =>"rz",
    PhaseShift  =>"p",
    Universal   =>"u",
    ControlZ    =>"cz",
    ControlX    =>"cx",
    ISwap       =>"iswap",
    ISwapDagger =>"iswap_dag",
    Toffoli     =>"ccx",
    )

"""
    pop_gate!(circuit::QuantumCircuit)

Removes the last gate from `circuit.pipeline`. 

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2);

julia> push_gate!(c, [hadamard(1),sigma_x(2)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────X────X──
                    



julia> pop_gate!(c)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



```
"""
function pop_gate!(circuit::QuantumCircuit)
    pop!(circuit.pipeline)
    return circuit
end

function Base.show(io::IO, circuit::QuantumCircuit, padding_width::Integer=10)
    println(io, "Quantum Circuit Object:")
    println(io, "   qubit_count: $(circuit.qubit_count) ")
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
    
    for (i_step, gate) in enumerate(circuit.pipeline)
        longest_symbol_length=get_longest_symbol_length(gate)
        add_wires_to_circuit_layout!(circuit_layout, i_step, circuit.qubit_count,longest_symbol_length)
        add_coupling_lines_to_circuit_layout!(circuit_layout, gate, i_step,longest_symbol_length)
        add_target_to_circuit_layout!(circuit_layout, gate, i_step,longest_symbol_length)
    end
    return circuit_layout
end

function get_longest_symbol_length(gate::AbstractGate)
    largest_length = 0
    for symbol in get_display_symbol(gate)
        symbol_length = length(symbol)
        if symbol_length > largest_length
            largest_length = symbol_length
        end
    end
    return largest_length
end

function add_qubit_labels_to_circuit_layout!(
    circuit_layout::Array{String},
    num_qubits::Integer
    )

    max_num_digits = ndigits(num_qubits)
    for i_qubit in range(1, length = num_qubits)
        num_digits = ndigits(i_qubit)
        padding = max_num_digits-num_digits
        id_wire = 2 * (i_qubit - 1) + 1
        circuit_layout[id_wire, 1] = "q[$i_qubit]:" * " "^padding
        circuit_layout[id_wire+1, 1] = String(fill(' ', length(circuit_layout[id_wire, 1])))
    end
end

function add_wires_to_circuit_layout!(
    circuit_layout::Array{String}, 
    i_step::Integer,
    num_qubits::Integer,
    longest_symbol_length::Integer
    )

    num_chars = 4+longest_symbol_length
    for i_qubit in range(1, length = num_qubits)
        id_wire = 2 * (i_qubit - 1) + 1
        # qubit wire
        circuit_layout[id_wire, i_step+1] = "─"^num_chars
        # spacer line
        circuit_layout[id_wire+1, i_step+1] = " "^num_chars
    end
end

function add_coupling_lines_to_circuit_layout!(
    circuit_layout::Array{String}, 
    gate::AbstractGate,
    i_step::Integer,
    longest_symbol_length::Integer
    )
    
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

function add_target_to_circuit_layout!(circuit_layout::Array{String}, gate::AbstractGate,
    i_step::Integer, longest_symbol_length::Integer)
    
    symbols_gate=get_display_symbol(gate)

    for (i_target, target) in enumerate(gate.target)
        symbol_length = length(symbols_gate[i_target])
        length_difference = longest_symbol_length-symbol_length
        num_left_dashes = 2 + floor(Int, length_difference/2)
        num_right_dashes = 2 + ceil(Int, length_difference/2)
        id_wire = 2*(target-1)+1
        circuit_layout[id_wire, i_step+1] = '─'^num_left_dashes *
            "$(symbols_gate[i_target])" * '─'^num_right_dashes
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
julia> c = Snowflake.QuantumCircuit(qubit_count = 2);

julia> push_gate!(c, hadamard(1))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H──
          
q[2]:─────
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H────*──
            |  
q[2]:───────X──
               


julia> ket = simulate(c)
4-element Ket{ComplexF64}:
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
    for gate in circuit.pipeline 
        apply_gate!(ψ, gate)        
    end
    return ψ
end

"""
    simulate_shots(c::QuantumCircuit, shots_count::Int = 100)

Emulates a quantum computer by running a circuit for a given number of shots and returning measurement results.

# Examples
```jldoctest simulate_shots; filter = r"00|11"
julia> c = Snowflake.QuantumCircuit(qubit_count = 2);

julia> push_gate!(c, hadamard(1))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H──
          
q[2]:─────
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   qubit_count: 2 
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

"""
    get_measurement_probabilities(circuit::QuantumCircuit,
        [target_qubits::Vector{<:Integer}])::AbstractVector{<:Real}

Returns a vector listing the measurement probabilities for the `target_qubits` in the `circuit`.

If no `target_qubits` are provided, the probabilities are computed for all the qubits.

The measurement probabilities are listed from the smallest to the largest computational
basis state. For instance, for a 2-qubit `QuantumCircuit`, the probabilities are listed
for 00, 01, 10, and 11.
# Examples
The following example constructs a `QuantumCircuit` where the probability of measuring 01
is 50% and the probability of measuring 11 is also 50%.
```jldoctest get_circuit_measurement_probabilities
julia> circuit = QuantumCircuit(qubit_count=2);

julia> push_gate!(circuit, [hadamard(1), sigma_x(2)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> get_measurement_probabilities(circuit)
4-element Vector{Float64}:
 0.0
 0.4999999999999999
 0.0
 0.4999999999999999

```

For the same `circuit`, the probability of measuring qubit 2 and finding 1 is 100%.
```jldoctest get_circuit_measurement_probabilities
julia> target_qubit = [2];

julia> get_measurement_probabilities(circuit, target_qubit)
2-element Vector{Float64}:
 0.0
 0.9999999999999998

```
"""
function get_measurement_probabilities(circuit::QuantumCircuit)::AbstractVector{<:Real}
    ket = simulate(circuit)
    return get_measurement_probabilities(ket)
end

function get_measurement_probabilities(circuit::QuantumCircuit,
    target_qubits::Vector{<:Integer})::AbstractVector{<:Real}
    
    ket = simulate(circuit)
    return get_measurement_probabilities(ket, target_qubits)
end

"""
    get_inverse(circuit::QuantumCircuit)

Return a `QuantumCircuit` which is the inverse of the input `circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2);

julia> push_gate!(c, rotation_y(1, pi/4));

julia> push_gate!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Ry(0.7854)────*──
                     |  
q[2]:────────────────X──
                        



julia> get_inverse(c)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──*────Ry(-0.7854)──
       |                 
q[2]:──X─────────────────
                         



```
"""
function get_inverse(circuit::QuantumCircuit)

    inverse_pipeline = Vector{AbstractGate}( 
        [get_inverse(g) for g in reverse(circuit.pipeline)] 
    )

    return QuantumCircuit(qubit_count=circuit.qubit_count,
        pipeline=inverse_pipeline)
end

"""
    get_gate_counts(circuit::QuantumCircuit)::AbstractDict{<:AbstractString, <:Integer}

Returns a dictionary listing the number of gates of each type found in the `circuit`.

The dictionary keys are the instruction_symbol of the gates while the values are the number of gates found.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2);

julia> push_gate!(c, [hadamard(1), hadamard(2)]);

julia> push_gate!(c, control_x(1, 2));

julia> push_gate!(c, hadamard(2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*───────
                 |       
q[2]:───────H────X────H──
                         



julia> get_gate_counts(c)
Dict{String, Int64} with 2 entries:
  "h"  => 3
  "cx" => 1

```
"""
function get_gate_counts(circuit::QuantumCircuit)::AbstractDict{<:AbstractString, <:Integer}
    gate_counts = Dict{String, Int}()
    for gate in circuit.pipeline
        instruction_symbol=get_instruction_symbol(gate)
        if haskey(gate_counts, instruction_symbol)
            gate_counts[instruction_symbol] += 1
        else
            gate_counts[instruction_symbol] = 1
        end
    end
    return gate_counts
end

"""
    get_num_gates(circuit::QuantumCircuit)::Integer

Returns the number of gates in the `circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2);

julia> push_gate!(c, [hadamard(1), hadamard(2)]);

julia> push_gate!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────H────X──
                    



julia> get_num_gates(c)
3

```
"""
get_num_gates(circuit::QuantumCircuit)::Integer=length(circuit.pipeline)
