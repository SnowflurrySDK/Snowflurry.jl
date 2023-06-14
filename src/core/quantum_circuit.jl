
"""
    QuantumCircuit(qubit_count)

A data structure to represent a *quantum circuit*.  
# Fields
- `qubit_count::Int` -- number of qubits (i.e. quantum register size).
- `gates::Vector{AbstractGateSymbol}` -- the sequence of gates to operate on qubits.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:
     
q[2]:
```
"""
Base.@kwdef struct QuantumCircuit
    qubit_count::Int
    gates::Vector{Gate} = Vector{Gate}([])
    
    function QuantumCircuit(qubit_count::Int,gates::Vector{GateType}) where GateType <: Gate
        @assert qubit_count>0 ("$(:QuantumCircuit) constructor requires qubit_count>0. Received: $qubit_count")
    
        c=new(qubit_count,[])

        # add gates, with ensure_gate_is_in_circuit()
        push!(c,gates...)

        return c
    end
end


get_num_qubits(circuit::QuantumCircuit)=circuit.qubit_count
get_circuit_gates(circuit::QuantumCircuit)::AbstractVector{Gate}=circuit.gates

"""
    push!(circuit::QuantumCircuit, gates::AbstractGateSymbol...)

Inserts one or more `gates` at the end of a `circuit`.

A `Vector` of `AbstractGateSymbol` objects can be passed to this function by using splatting.
More details about splatting are provided
[here](https://docs.julialang.org/en/v1/manual/faq/#What-does-the-...-operator-do?).

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1), sigma_x(2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> push!(c, control_x(1,2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────X────X──
                    



julia> gate_list = [sigma_x(1), hadamard(2)];

julia> push!(c, gate_list...)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*────X───────
                 |            
q[2]:───────X────X─────────H──
                              



```
"""
function Base.push!(circuit::QuantumCircuit, gates::Gate...)
    for single_gate in gates
        ensure_gate_is_in_circuit(circuit, single_gate)
        push!(get_circuit_gates(circuit), single_gate)
    end
    return circuit
end

"""
    append!(base_circuit::QuantumCircuit, circuits_to_append::QuantumCircuit...)

Appends one or more `circuits_to_append` to the `base_circuit`.

The `circuits_to_append` cannot contain more qubits than the `base_circuit`.

# Examples
```jldoctest
julia> base = QuantumCircuit(qubit_count=2, gates=[sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X──
          
q[2]:─────
          



julia> append_1 = QuantumCircuit(qubit_count=1, gates=[sigma_z(1)])
Quantum Circuit Object:
   qubit_count: 1 
q[1]:──Z──
          



julia> append_2 = QuantumCircuit(qubit_count=2, gates=[control_x(1,2)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──*──
       |  
q[2]:──X──
          



julia> append!(base, append_1, append_2)

julia> print(base)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X────Z────*──
                 |  
q[2]:────────────X──
                    


```
"""
function Base.append!(base_circuit::QuantumCircuit, circuits_to_append::QuantumCircuit...)
    for circuit in circuits_to_append
        if base_circuit.qubit_count < circuit.qubit_count
            throw(ErrorException("the circuit to append has more qubits "*
                "($(circuit.qubit_count)) than the base circuit "*
                "($(base_circuit.qubit_count) qubits)"))
        else
            append!(base_circuit.gates, circuit.gates)
        end
    end
end

"""
    prepend!(base_circuit::QuantumCircuit, circuits_to_prepend::QuantumCircuit...)

Prepends one or more `circuits_to_prepend` to the `base_circuit`.

The order of the `circuits_to_prepend` is maintained (i.e. `circuits_to_prepend[1]` will
appear leftmost in `base_circuit`). The `circuits_to_prepend` cannot contain more qubits
than the `base_circuit`.

# Examples
```jldoctest
julia> base = QuantumCircuit(qubit_count=2, gates=[sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X──
          
q[2]:─────
          



julia> prepend_1 = QuantumCircuit(qubit_count=1, gates=[sigma_z(1)])
Quantum Circuit Object:
   qubit_count: 1 
q[1]:──Z──
          



julia> prepend_2 = QuantumCircuit(qubit_count=2, gates=[control_x(1,2)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──*──
       |  
q[2]:──X──
          



julia> prepend!(base, prepend_1, prepend_2)

julia> print(base)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Z────*────X──
            |       
q[2]:───────X───────
                    


```
"""
function Base.prepend!(base_circuit::QuantumCircuit, circuits_to_prepend::QuantumCircuit...)
    for circuit in reverse(circuits_to_prepend)
        if base_circuit.qubit_count < circuit.qubit_count
            throw(ErrorException("the circuit to prepend has more qubits "*
                "($(circuit.qubit_count)) than the base circuit "*
                "($(base_circuit.qubit_count) qubits)"))
        else
            prepend!(base_circuit.gates, circuit.gates)
        end
    end
end


"""
    compare_circuits(c0::QuantumCircuit,c1::QuantumCircuit)::Bool

Tests for equivalence of two circuits based on their effect on an 
arbitrary input state (a Ket). Circuits are equivalent if they both 
yield the same output for any input, up to a global phase.
Circuits with different ordering of gates that apply on different 
targets can also be equivalent.


# Examples
```jldoctest
julia> c0 = QuantumCircuit(qubit_count = 1, gates=[sigma_x(1),sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 1 
q[1]:──X────Y──
               



julia> c1 = QuantumCircuit(qubit_count = 1, gates=[phase_shift(1,π)])
Quantum Circuit Object:
   qubit_count: 1  
q[1]:──Rz(3.1416)──
                   



julia> compare_circuits(c0,c1)
true            

julia> c0 = QuantumCircuit(qubit_count = 3, gates=[sigma_x(1),sigma_y(1),control_x(2,3)])
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──X────Y───────
                    
q[2]:────────────*──
                 |  
q[3]:────────────X──
                    



julia> c1 = QuantumCircuit(qubit_count = 3, gates=[control_x(2,3),sigma_x(1),sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 3 
q[1]:───────X────Y──
                    
q[2]:──*────────────
       |            
q[3]:──X────────────
                    



julia> compare_circuits(c0,c1)
true    

```
"""
function compare_circuits(c0::QuantumCircuit,c1::QuantumCircuit)::Bool

    num_qubits=get_num_qubits(c0)

    @assert num_qubits==get_num_qubits(c1) ("Input circuits have diffent number of qubits")

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

"""
    circuit_contains_gate_type(circuit::QuantumCircuit, gate_type::Type{<: AbstractGateSymbol})::Bool

Determined whether or not a type of gate is present in a circuit.

# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count = 1, gates=[sigma_x(1),sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 1 
q[1]:──X────Y──
               
julia> circuit_contains_gate_type(circuit, Snowflake.SigmaX)
true
               
julia> circuit_contains_gate_type(circuit, Snowflake.ControlZ)
false
```
"""
function circuit_contains_gate_type(circuit::QuantumCircuit, gate_type::Type{<: AbstractGateSymbol})::Bool
    for gate in get_circuit_gates(circuit)
        if is_gate_type(gate, gate_type)
            return true
        end
    end

    return false
end

function ensure_gate_is_in_circuit(circuit::QuantumCircuit, gate::AbstractGateSymbol)
    for target in get_connected_qubits(gate)
        if target > get_num_qubits(circuit)
            throw(DomainError(target, "the gate does no fit in the circuit"))
        end
    end
end

formatter(str_label,args...) = @eval @sprintf($str_label,$args...)

function format_label(
    symbol_specs::Vector{String},
    num_targets::Int,
    gate_params::Dict{String,<:Real};
    precision::Integer=4,
    )::Vector{String}

    num_params=length(gate_params)

    symbol_gate=symbol_specs[num_targets]
    fields=symbol_specs[num_targets+1:end]
    repetitions=length(fields)

    # create format specifier of correct precision
    precisionStr=string("%.",precision,"f")
    precisionArray=[precisionStr for _ in 1:repetitions]
    str_label_with_precision=formatter(symbol_gate,precisionArray...)

    # construct array of values in the order found in fields
    parameter_values=Vector{Real}([])

    for key in fields
        push!(parameter_values,gate_params[key])
    end

    # construct label using gate_params
    label_with_params=formatter(str_label_with_precision,parameter_values...)

    if num_targets==1
        return [label_with_params]
    else
        return vcat(symbol_specs[1:end-num_params-1],label_with_params)
    end
end

# TODO(#226): delete on completion
function get_display_symbol(gate::Gate;precision::Integer=4)
    return get_display_symbol(get_gate_symbol(gate), precision=precision)
end

function get_display_symbol(gate::AbstractGateSymbol;precision::Integer=4)

    gate_params=get_gate_parameters(gate)

    targets=get_connected_qubits(gate)

    num_targets=length(targets)

    symbol_specs=gates_display_symbols[get_gate_type(gate)]

    return format_label(symbol_specs,num_targets,gate_params;precision=precision)
end

function get_display_symbol(gate::ControlledGate;precision::Integer=4)

    # build new display symbol using existing symbol pertaining to kernel
    symbol_specs=get_display_symbol(gate.kernel,precision=precision)

    num_kernel_qubits=length(gate.kernel_qubits)
    
    gate_params=get_gate_parameters(gate)

    return vcat(
        [control_display_symbol for _ in 1:length(gate.control_qubits)],
        [
            format_label(
                symbol_specs,
                num_kernel_qubits,
                gate_params;
                precision=precision
            )...
        ])
end

const control_display_symbol ="*"

gates_display_symbols=Dict(
    Identity    =>["I"],
    SigmaX      =>["X"],
    SigmaY      =>["Y"],
    SigmaZ      =>["Z"],
    Hadamard    =>["H"],
    Pi8         =>["T"],
    Pi8Dagger   =>["T†"],
    X90         =>["X_90"],
    XM90         =>["X_m90"],
    Y90         =>["Y_90"],
    YM90         =>["Y_m90"],
    Z90         =>["Z_90"],
    ZM90         =>["Z_m90"],
    Rotation    =>["R(θ=%s,ϕ=%s)","theta","phi"],
    RotationX   =>["Rx(%s)","theta"],
    RotationY   =>["Ry(%s)","theta"],
    PhaseShift  =>["Rz(%s)","lambda"],
    Universal   =>["U(θ=%s,ϕ=%s,λ=%s)","theta","phi","lambda"],
    ControlZ    =>[control_display_symbol, "Z"],
    ControlX    =>[control_display_symbol, "X"],
    ISwap       =>["x", "x"],
    ISwapDagger =>["x†", "x†"],
    Toffoli     =>[control_display_symbol, control_display_symbol, "X"],
    Swap       =>["☒", "☒"],
)

get_instruction_symbol(gate::AbstractGateSymbol)=gates_instruction_symbols[get_gate_type(gate)]

gates_instruction_symbols=Dict(
    Identity    =>"i",
    SigmaX      =>"x",
    SigmaY      =>"y",
    SigmaZ      =>"z",
    Hadamard    =>"h",
    Pi8         =>"t",
    Pi8Dagger   =>"t_dag",
    X90         =>"x_90",
    XM90        =>"x_minus_90",
    Y90         =>"y_90",
    YM90        =>"y_minus_90",
    Z90         =>"z_90",
    ZM90        =>"z_minus_90",
    Rotation    =>"r",
    RotationX   =>"rx",
    RotationY   =>"ry",
    PhaseShift  =>"rz",
    Universal   =>"u",
    ControlZ    =>"cz",
    ControlX    =>"cx",
    ISwap       =>"iswap",
    ISwapDagger =>"iswap_dag",
    Toffoli     =>"ccx",
    Swap        =>"swap",
    )

"""
    pop!(circuit::QuantumCircuit)

Removes the last gate from `circuit.gates`. 

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1), sigma_x(2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> push!(c, control_x(1,2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────X────X──
                    



julia> pop!(c)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



```
"""
function Base.pop!(circuit::QuantumCircuit)
    pop!(get_circuit_gates(circuit))
    return circuit
end

function Base.show(io::IO, circuit::QuantumCircuit, padding_width::Integer=10)
    println(io, "Quantum Circuit Object:")
    println(io, "   qubit_count: $(get_num_qubits(circuit)) ")
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
    wire_count = 2 * get_num_qubits(circuit)
    circuit_layout = fill("", (wire_count, length(get_circuit_gates(circuit)) + 1))
    add_qubit_labels_to_circuit_layout!(circuit_layout, get_num_qubits(circuit))
    
    for (i_step, gate) in enumerate(get_circuit_gates(circuit))
        longest_symbol_length=get_longest_symbol_length(gate)
        add_wires_to_circuit_layout!(circuit_layout, i_step, get_num_qubits(circuit),longest_symbol_length)
        add_coupling_lines_to_circuit_layout!(circuit_layout, gate, i_step,longest_symbol_length)
        add_target_to_circuit_layout!(circuit_layout, gate, i_step,longest_symbol_length)
    end
    return circuit_layout
end

function get_longest_symbol_length(gate::AbstractGateSymbol)
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
    gate::AbstractGateSymbol,
    i_step::Integer,
    longest_symbol_length::Integer
    )
    
    length_difference = longest_symbol_length-1
    num_left_chars = 2 + floor(Int, length_difference/2)
    num_right_chars = 2 + ceil(Int, length_difference/2)
    min_wire = 2*(minimum(get_connected_qubits(gate))-1)+1
    max_wire = 2*(maximum(get_connected_qubits(gate))-1)+1
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

function add_target_to_circuit_layout!(circuit_layout::Array{String}, gate::AbstractGateSymbol,
    i_step::Integer, longest_symbol_length::Integer)
    
    symbols_gate=get_display_symbol(gate)

    for (i_target, target) in enumerate(get_connected_qubits(gate))
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

Simulates and returns the wavefunction of the quantum device after running `circuit`, 
assuming an initial state Ket ψ corresponding to the 0th Fock basis, i.e.: 
`ψ=fock(0,2^get_num_qubits(circuit))`. 

Employs the approach described in Listing 5 of
[Suzuki *et. al.* (2021)](https://doi.org/10.22331/q-2021-10-06-559).

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H──
          
q[2]:─────
          


julia> push!(c, control_x(1,2))
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
    hilbert_space_size = 2^get_num_qubits(circuit)
    # initial state 
    ψ = fock(0, hilbert_space_size)
    for gate in get_circuit_gates(circuit) 
        apply_gate!(ψ, gate)        
    end
    return ψ
end

"""
    simulate_shots(c::QuantumCircuit, shots_count::Int = 100)

Emulates a quantum computer by running a circuit for a given number of shots and returning measurement results. 
The distribution of measured states corresponds to the coefficients in the resulting state Ket. 

# Examples
```jldoctest simulate_shots; filter = r"00|11"
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H──
          
q[2]:─────
          


julia> push!(c, control_x(1,2))
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

julia> push!(circuit, hadamard(1), sigma_x(2))
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
    inv(circuit::QuantumCircuit)

Return a `QuantumCircuit` which is the inverse of the input `circuit`. 
Each gate is replaced by it's corresponding inverse, and the order of gates is reversed.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2);

julia> push!(c, rotation_y(1, pi/4));

julia> push!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Ry(0.7854)────*──
                     |  
q[2]:────────────────X──
                        



julia> inv(c)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──*────Ry(-0.7854)──
       |                 
q[2]:──X─────────────────
                         



```
"""
function Base.inv(circuit::QuantumCircuit)

    inverse_gates = Vector{Gate}( 
        [Base.inv(g) for g in reverse(get_circuit_gates(circuit))] 
    )

    return QuantumCircuit(qubit_count=get_num_qubits(circuit),
        gates=inverse_gates)
end

"""
    get_num_gates_per_type(circuit::QuantumCircuit)::AbstractDict{<: AbstractString, <:Integer}

Returns a dictionary listing the number of gates of each type found in the `circuit`.

The dictionary keys are the instruction_symbol of the gates while the values are the number of gates found.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=2);

julia> push!(c, hadamard(1), hadamard(2));

julia> push!(c, control_x(1, 2));

julia> push!(c, hadamard(2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*───────
                 |       
q[2]:───────H────X────H──
                         



julia> get_num_gates_per_type(c)
Dict{String, Int64} with 2 entries:
  "h"  => 3
  "cx" => 1

```
"""
function get_num_gates_per_type(circuit::QuantumCircuit)::AbstractDict{<: AbstractString, <:Integer}
    gate_counts = Dict{String, Int}()
    for gate in get_circuit_gates(circuit)
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

julia> push!(c, hadamard(1), hadamard(2));

julia> push!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────H────X──
                    



julia> get_num_gates(c)
3

```
"""
get_num_gates(circuit::QuantumCircuit)::Integer=length(get_circuit_gates(circuit))

"""
    permute_qubits!(circuit::QuantumCircuit,
        qubit_mapping::AbstractDict{T,T}) where T<:Integer

Modifies a `circuit` by moving the gates to other qubits based on a `qubit_mapping`.

The dictionary `qubit_mapping` contains key-value pairs describing how to update the target
qubits. The key indicates which target qubit to change while the associated value specifies
the new qubit. All the keys in the dictionary must also be present as values and vice versa.

For instance, `Dict(1=>2)` is not a valid `qubit_mapping`, but `Dict(1=>2, 2=>1)` is valid.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=3);

julia> push!(c, sigma_x(1), hadamard(2), sigma_y(3))
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──X────────────
                    
q[2]:───────H───────
                    
q[3]:────────────Y──                    



julia> permute_qubits!(c, Dict(1=>3, 3=>1))

julia> show(c)
Quantum Circuit Object:
   qubit_count: 3 
q[1]:────────────Y──
                    
q[2]:───────H───────
                    
q[3]:──X────────────
                    


```
"""
function permute_qubits!(circuit::QuantumCircuit,
    qubit_mapping::AbstractDict{T,T}) where T<:Integer

    assert_qubit_mapping_is_valid(qubit_mapping, get_num_qubits(circuit))
    unsafe_permute_qubits!(circuit, qubit_mapping)
end

function assert_qubit_mapping_is_valid(qubit_mapping::AbstractDict{T,T},
    qubit_count::Integer) where T<:Integer

    sorted_keys = sort(collect(keys(qubit_mapping)))
    sorted_values = sort(collect(values(qubit_mapping)))
    if sorted_keys != sorted_values
        throw(ErrorException("the qubit mapping is invalid"))
    end
    if last(sorted_keys) < 1 || first(sorted_keys) > qubit_count
        throw(ErrorException("the qubit mapping has a value that does not fit in the "*
            "circuit"))
    end
end

function unsafe_permute_qubits!(circuit::QuantumCircuit,
    qubit_mapping::AbstractDict{T,T}) where T<:Integer

    gates_list = get_circuit_gates(circuit)
    for (i_gate, gate) in enumerate(gates_list)
        moved_gate = move_gate(gate, qubit_mapping)
        circuit.gates[i_gate] = moved_gate
    end
end

"""
    permute_qubits(circuit::QuantumCircuit,
        qubit_mapping::AbstractDict{T,T})::QuantumCircuit where T<:Integer

Returns a `QuantumCircuit` that is a copy of `circuit` but where the gates have been moved
to other qubits based on a `qubit_mapping`.

The dictionary `qubit_mapping` contains key-value pairs describing how to update the target
qubits. The key indicates which target qubit to change while the associated value specifies
the new qubit. All the keys in the dictionary must also be present as values and vice versa.

For instance, `Dict(1=>2)` is not a valid `qubit_mapping`, but `Dict(1=>2, 2=>1)` is valid.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count=3);

julia> push!(c, sigma_x(1), hadamard(2), sigma_y(3))
Quantum Circuit Object:
   qubit_count: 3 
q[1]:──X────────────
                    
q[2]:───────H───────
                    
q[3]:────────────Y──
                    



julia> permute_qubits(c, Dict(1=>3, 3=>1))
Quantum Circuit Object:
   qubit_count: 3 
q[1]:────────────Y──
                    
q[2]:───────H───────
                    
q[3]:──X────────────
                    



```
"""
function permute_qubits(circuit::QuantumCircuit,
    qubit_mapping::AbstractDict{T,T})::QuantumCircuit where T<:Integer

    circuit_copy = deepcopy(circuit)
    permute_qubits!(circuit_copy, qubit_mapping)
    return circuit_copy
end
