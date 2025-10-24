
"""
    QuantumCircuit(
        qubit_count::Int,
        bit_count::Int,
        instructions::Vector{AbstractInstruction},
        name::String = "default"
    )
    QuantumCircuit(circuit::QuantumCircuit)

A data structure which describes a *quantum circuit*.
# Fields
- `qubit_count::Int` -- Largest qubit index (e.g., specifying `qubit_count=n` enables the
                        use of qubits 1 to n).
- `bit_count::Int` -- Optional: Number of classical bits (i.e., result register size).
                      Defaults to `qubit_count` if unspecified.
- `instructions::Vector{AbstractInstruction}` -- Optional: Sequence of
                                                 `AbstractInstructions` (`Gates` and
                                                 `Readouts`) that operate on the qubits.
                                                 Defaults to an empty Vector.
- `name::String` -- Optional: Name of the circuit and the corresponding job. It is used to
                    identify the job when it is sent to a hardware or virtual QPU. 

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:
     
q[2]:
```

A `QuantumCircuit` can be initialized with [`Gate`](@ref Gate) and [`Readout`](@ref Readout)
structs:

```jldoctest circuit
julia> c = QuantumCircuit(
            qubit_count = 2,
            instructions = [
                hadamard(1),
                sigma_x(2),
                control_x(1, 2),
                readout(1, 1),
                readout(2, 2)
            ])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H─────────*────✲───────
                 |            
q[2]:───────X────X─────────✲──
                              
```

A deep copy of a `QuantumCircuit` can be obtained with the following function:

```jldoctest circuit
julia> c_copy = QuantumCircuit(c)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H─────────*────✲───────
                 |            
q[2]:───────X────X─────────✲──
                              
```
"""
Base.@kwdef struct QuantumCircuit
    qubit_count::Int
    bit_count::Int = qubit_count
    instructions::Vector{AbstractInstruction} = Vector{AbstractInstruction}([])
    name::String = "default"

    function QuantumCircuit(
        qubit_count::Int,
        bit_count::Int,
        instructions::Vector{InstructionType},
        name::String,
    ) where {InstructionType<:AbstractInstruction}
        @assert qubit_count > 0 (
            "$(:QuantumCircuit) constructor requires qubit_count>0. Received: $qubit_count"
        )
        @assert bit_count > 0 (
            "$(:QuantumCircuit) constructor requires bit_count>0. Received: $bit_count"
        )

        circuit = new(qubit_count, bit_count, [], name)
        foreach(instr -> ensure_instruction_is_in_circuit(circuit, instr), instructions)
        append!(circuit.instructions, instructions)
        return circuit
    end

    function QuantumCircuit(input_circuit::QuantumCircuit)
        return new(
            input_circuit.qubit_count,
            input_circuit.bit_count,
            deepcopy(input_circuit.instructions),
        )
    end
end

"""
    update_circuit_qubit_count(
        quantum_cicuit::QuantumCircuit,
        qubit_count::Int,
    )::QuantumCircuit

Updates the `qubit_count` of the `quantum_circuit`.

# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 1 
   bit_count: 1 
q[1]:──X──
          



julia> larger_circuit = update_circuit_qubit_count(circuit, 2)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 1 
q[1]:──X──
          
q[2]:─────
          


```
"""
function update_circuit_qubit_count(
    quantum_cicuit::QuantumCircuit,
    qubit_count::Int,
)::QuantumCircuit
    return QuantumCircuit(
        qubit_count,
        quantum_cicuit.bit_count,
        quantum_cicuit.instructions,
        quantum_cicuit.name,
    )
end

function Base.isequal(c0::QuantumCircuit, c1::QuantumCircuit)::Bool
    if !(c0.qubit_count == c1.qubit_count && c0.bit_count == c1.bit_count)
        return false
    end

    if length(c0.instructions) != length(c1.instructions)
        return false
    end

    for (instr0, instr1) in zip(c0.instructions, c1.instructions)
        if !isequal(instr0, instr1)
            return false
        end
    end

    return true
end

"""
    get_num_qubits(circuit::QuantumCircuit)::Int

Returns the number of qubits in a `circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> get_num_qubits(c)
2

```
"""
get_num_qubits(circuit::QuantumCircuit)::Int = circuit.qubit_count

"""
    get_num_bits(circuit::QuantumCircuit)::Int

Returns the number of classical bits in a `circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2, bit_count=3);

julia> get_num_bits(c)
3

```
"""
get_num_bits(circuit::QuantumCircuit)::Int = circuit.bit_count

"""
    get_name(circuit::QuantumCircuit)::String

Returns the name of the `circuit` and the corresponding job.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2, name = "my_circuit");

julia> get_name(c)
"my_circuit"

```
"""
get_name(circuit::QuantumCircuit)::String = circuit.name

"""
    get_circuit_instructions(circuit::QuantumCircuit)::Vector{AbstractInstruction}

Returns the list of instructions in the `circuit`.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2, instructions = [hadamard(1), control_z(1, 2)]);

julia> get_circuit_instructions(c)
2-element Vector{AbstractInstruction}:
 Gate Object: Snowflurry.Hadamard
Connected_qubits	: [1]
Operator:
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.7071067811865475 + 0.0im    0.7071067811865475 + 0.0im
0.7071067811865475 + 0.0im    -0.7071067811865475 + 0.0im

 Gate Object: Snowflurry.ControlZ
Connected_qubits	: [1, 2]
Operator:
(4, 4)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    -1.0 + 0.0im


```
"""
get_circuit_instructions(circuit::QuantumCircuit)::Vector{AbstractInstruction} =
    circuit.instructions

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
   bit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> push!(c, control_x(1,2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────X────X──
                    



julia> gate_list = [sigma_x(1), hadamard(2)];

julia> push!(c, gate_list...)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H─────────*────X───────
                 |            
q[2]:───────X────X─────────H──
                              



```
"""
function Base.push!(circuit::QuantumCircuit, instructions::AbstractInstruction...)
    foreach(instr -> ensure_instruction_is_in_circuit(circuit, instr), instructions)
    append!(circuit.instructions, instructions)
    return circuit
end

function Base.append!(
    circuit::QuantumCircuit,
    instructions::Vector{InstructionType},
) where {InstructionType<:AbstractInstruction}
    foreach(instr -> ensure_instruction_is_in_circuit(circuit, instr), instructions)
    append!(circuit.instructions, instructions)
    return circuit
end

"""
    append!(base_circuit::QuantumCircuit, circuits_to_append::QuantumCircuit...)

Appends one or more `circuits_to_append` to the `base_circuit`.

The `circuits_to_append` cannot contain more qubits than the `base_circuit`.

# Examples
```jldoctest
julia> base = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X──
          
q[2]:─────
          



julia> append_1 = QuantumCircuit(qubit_count = 1, instructions = [sigma_z(1)])
Quantum Circuit Object:
   qubit_count: 1 
   bit_count: 1 
q[1]:──Z──
          



julia> append_2 = QuantumCircuit(qubit_count = 2, instructions = [control_x(1, 2)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──*──
       |  
q[2]:──X──
          



julia> append!(base, append_1, append_2)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X────Z────*──
                 |  
q[2]:────────────X──
                    


```
"""
function Base.append!(base_circuit::QuantumCircuit, circuits_to_append::QuantumCircuit...)
    for circuit in circuits_to_append
        if base_circuit.qubit_count < circuit.qubit_count
            throw(
                ErrorException(
                    "the circuit to append has more qubits " *
                    "($(circuit.qubit_count)) than the base circuit " *
                    "($(base_circuit.qubit_count) qubits)",
                ),
            )
        else
            append!(base_circuit.instructions, circuit.instructions)
        end
    end
    return base_circuit
end

"""
    prepend!(base_circuit::QuantumCircuit, circuits_to_prepend::QuantumCircuit...)

Prepends one or more `circuits_to_prepend` to the `base_circuit`.

The order of the `circuits_to_prepend` is maintained (i.e., `circuits_to_prepend[1]` will
appear leftmost in `base_circuit`). The `circuits_to_prepend` cannot contain more qubits
than the `base_circuit`.

# Examples
```jldoctest
julia> base = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X──
          
q[2]:─────
          



julia> prepend_1 = QuantumCircuit(qubit_count = 1, instructions = [sigma_z(1)])
Quantum Circuit Object:
   qubit_count: 1 
   bit_count: 1 
q[1]:──Z──
          



julia> prepend_2 = QuantumCircuit(qubit_count = 2, instructions = [control_x(1, 2)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──*──
       |  
q[2]:──X──
          



julia> prepend!(base, prepend_1, prepend_2)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Z────*────X──
            |       
q[2]:───────X───────
                    


```
"""
function Base.prepend!(base_circuit::QuantumCircuit, circuits_to_prepend::QuantumCircuit...)
    for circuit in reverse(circuits_to_prepend)
        if base_circuit.qubit_count < circuit.qubit_count
            throw(
                ErrorException(
                    "the circuit to prepend has more qubits " *
                    "($(circuit.qubit_count)) than the base circuit " *
                    "($(base_circuit.qubit_count) qubits)",
                ),
            )
        else
            prepend!(base_circuit.instructions, circuit.instructions)
        end
    end
    return base_circuit
end


"""
    compare_circuits(c0::QuantumCircuit, c1::QuantumCircuit)::Bool

Tests for the equivalence of two [`QuantumCircuit`](@ref) objects based on their effect
on an arbitrary input state (a `Ket`). The circuits are equivalent if they both 
yield the same output for any input, up to a global phase. Circuits with gates that are
applied in a different order and to different targets can also be equivalent. 
!!! note 
    If there are `Readout` instructions present on either `QuantumCircuit`, 
    `compare_circuits` checks that both circuits have readouts targeting
    the same qubits and that no operations exist on those qubits after
    readout.


# Examples
```jldoctest
julia> c0 = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1), sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 1 
   bit_count: 1 
q[1]:──X────Y──
               



julia> c1 = QuantumCircuit(qubit_count = 1, instructions = [phase_shift(1, π)])
Quantum Circuit Object:
   qubit_count: 1  
   bit_count: 1  
q[1]:──P(3.1416)──
                  



julia> compare_circuits(c0, c1)
true            

julia> c0 = QuantumCircuit(
                qubit_count = 3,
                instructions = [sigma_x(1), sigma_y(1), control_x(2, 3)]
            )
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X────Y───────
                    
q[2]:────────────*──
                 |  
q[3]:────────────X──
                    



julia> c1 = QuantumCircuit(
                qubit_count = 3,
                instructions = [control_x(2, 3), sigma_x(1), sigma_y(1)]
            )
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:───────X────Y──
                    
q[2]:──*────────────
       |            
q[3]:──X────────────
                    



julia> compare_circuits(c0, c1)
true    

julia> c2 = QuantumCircuit(qubit_count = 3, instructions = [sigma_x(1), readout(1, 1)])
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X────✲──
               
q[2]:──────────
               
q[3]:──────────
               
julia> c3 = QuantumCircuit(qubit_count = 3, instructions = [sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X──
          
q[2]:─────
          
q[3]:─────
          

julia> compare_circuits(c2,c3)
false    

```
"""
function compare_circuits(c0::QuantumCircuit, c1::QuantumCircuit)::Bool

    num_qubits = get_num_qubits(c0)

    @assert num_qubits == get_num_qubits(c1) (
        "Input circuits have diffent number of qubits"
    )

    #non-normalized ket with different scalar at each position
    ψ_0 = Ket([v for v = 1:(2^num_qubits)])

    readouts_present_on_qubits_c0 = compile_readouts_and_apply_gates!(ψ_0, c0)

    ψ_1 = Ket([v for v = 1:(2^num_qubits)])

    readouts_present_on_qubits_c1 = compile_readouts_and_apply_gates!(ψ_1, c1)

    if readouts_present_on_qubits_c0 != readouts_present_on_qubits_c1
        # Performing Readout on different qubits will return different results
        return false
    end

    # check equality allowing a global phase offset
    return compare_kets(ψ_0, ψ_1)
end

function compile_readouts_and_apply_gates!(ψ::Ket, c::QuantumCircuit)::Set{Int}

    readouts_present_on_qubits = Set{Int}()

    for instr in get_circuit_instructions(c)
        targets = get_connected_qubits(instr)

        if instr isa Readout
            push!(readouts_present_on_qubits, targets[1])
        else
            for target in targets
                if target in readouts_present_on_qubits
                    throw(
                        ArgumentError(
                            "compare_circuit cannot evaluate equivalence if a Gate follows a Readout",
                        ),
                    )
                end
            end

            apply_instruction!(ψ, instr)
        end
    end

    return readouts_present_on_qubits
end

"""
    circuit_contains_gate_type(
        circuit::QuantumCircuit,
        gate_type::Type{<: AbstractGateSymbol}
    )::Bool

Determines if a type of gate is present in a circuit.

# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count = 1, instructions = [sigma_x(1), sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 1 
   bit_count: 1 
q[1]:──X────Y──
               
julia> circuit_contains_gate_type(circuit, Snowflurry.SigmaX)
true
               
julia> circuit_contains_gate_type(circuit, Snowflurry.ControlZ)
false
```
"""
function circuit_contains_gate_type(
    circuit::QuantumCircuit,
    gate_type::Type{<:AbstractGateSymbol},
)::Bool
    for instr in get_circuit_instructions(circuit)
        if (instr isa Snowflurry.Gate) && get_gate_symbol(instr) isa gate_type
            return true
        end
    end

    return false
end

function ensure_instruction_is_in_circuit(
    circuit::QuantumCircuit,
    instruction::Instruction,
) where {Instruction<:AbstractInstruction}
    for target in get_connected_qubits(instruction)
        qubit_count = get_num_qubits(circuit)
        if target > qubit_count
            throw(
                DomainError(
                    target,
                    "The instruction does not fit in the circuit: " *
                    "target qubit: $target, qubit_count: $qubit_count",
                ),
            )
        end
    end

    if instruction isa Readout
        destination = get_destination_bit(instruction)
        bit_count = get_num_bits(circuit)
        if destination > bit_count
            throw(
                DomainError(
                    destination,
                    "The instruction does not fit in the circuit: " *
                    "destination bit: $destination, bit_count: $bit_count",
                ),
            )
        end
    end
end

formatter(str_label, args...) = @eval @sprintf($str_label, $args...)

function format_label(
    symbol_specs::Vector{String},
    num_targets::Int,
    gate_params::Dict{String,<:Real};
    precision::Integer = 4,
)::Vector{String}

    num_params = length(gate_params)

    symbol_gate = symbol_specs[num_targets] #label with %s fields is at index=num_targets
    fields = symbol_specs[(num_targets+1):end]
    repetitions = length(fields)

    # create format specifier of correct precision: 
    # for instance: "U(θ=%s,ϕ=%s,λ=%s)" is converted to
    # "U(θ=%.2f,ϕ=%.2f,λ=%.2f)" for precision=2
    precisionStr = string("%.", precision, "f")
    precisionArray = [precisionStr for _ = 1:repetitions]
    str_label_with_precision = formatter(symbol_gate, precisionArray...)

    # construct array of values in the order found in fields
    parameter_values = Vector{Real}([])

    for key in fields
        push!(parameter_values, gate_params[key])
    end

    # construct label using gate_params
    label_with_params = formatter(str_label_with_precision, parameter_values...)

    if num_targets == 1
        return [label_with_params]
    else
        return vcat(symbol_specs[1:(end-num_params-1)], label_with_params)
    end
end

"""
    get_display_symbols(gate::AbstractGateSymbol; precision::Integer = 4,)::Vector{String}

Returns a `Vector{String}` of the symbols that describe the `gate`.

Each element in the `Vector` is associated with a qubit on which the `gate` operates. This
is useful for the placement of the `gate` in a circuit diagram. The optional parameter
`precision` enables setting the number of digits to keep after the decimal for `gate`
parameters.

# Examples
```jldoctest
julia> get_display_symbols(get_gate_symbol(control_z(1, 2)))
2-element Vector{String}:
 "*"
 "Z"

julia> get_display_symbols(get_gate_symbol(phase_shift(1, π/2)), precision = 3)
1-element Vector{String}:
 "P(1.571)"

```
"""
function get_display_symbols(
    gate::AbstractGateSymbol;
    precision::Integer = 4,
)::Vector{String}

    gate_params = get_gate_parameters(gate)

    num_targets = get_num_connected_qubits(gate)

    symbol_specs = gates_display_symbols[typeof(gate)]

    return format_label(symbol_specs, num_targets, gate_params; precision = precision)
end

function get_display_symbols(gate::Controlled; precision::Integer = 4)::Vector{String}

    # build new display symbol using existing symbol pertaining to kernel
    symbol_specs = get_display_symbols(gate.kernel, precision = precision)

    num_target_qubits = get_num_target_qubits(gate)

    gate_params = get_gate_parameters(gate)

    return vcat(
        [control_display_symbol for _ = 1:get_num_control_qubits(gate)],
        [
            format_label(
                symbol_specs,
                num_target_qubits,
                gate_params;
                precision = precision,
            )...,
        ],
    )
end

"""
    get_display_symbols(::Readout; precision::Integer = 4,)::Vector{String}

Returns a `Vector{String}` of the symbols that describe the `Readout`.

Each element in the `Vector` is associated with a qubit on which the `Readout` operates.
This is useful for the placement of the `Readout` in a circuit diagram. The optional
parameter `precision` has no effect for `Readout`.

# Examples
```jldoctest
julia> get_display_symbols(readout(2, 2))
1-element Vector{String}:
 "✲"

```
"""
function get_display_symbols(::Readout; precision::Integer = 4)::Vector{String}

    num_targets = 1

    symbol_specs = gates_display_symbols[Readout]

    return format_label(
        symbol_specs,
        num_targets,
        Dict{String,Int}();
        precision = precision,
    )
end

const control_display_symbol = "*"

gates_display_symbols = Dict(
    Identity => ["I"],
    SigmaX => ["X"],
    SigmaY => ["Y"],
    SigmaZ => ["Z"],
    Hadamard => ["H"],
    Pi8 => ["T"],
    Pi8Dagger => ["T†"],
    X90 => ["X_90"],
    XM90 => ["X_m90"],
    Y90 => ["Y_90"],
    YM90 => ["Y_m90"],
    Z90 => ["Z_90"],
    ZM90 => ["Z_m90"],
    Rotation => ["R(θ=%s,ϕ=%s)", "theta", "phi"],
    RotationX => ["Rx(%s)", "theta"],
    RotationY => ["Ry(%s)", "theta"],
    RotationZ => ["Rz(%s)", "lambda"],
    RootZZ => ["√ZZ", "√ZZ"],
    RootZZDagger => ["√ZZ†", "√ZZ†"],
    PhaseShift => ["P(%s)", "lambda"],
    Universal => ["U(θ=%s,ϕ=%s,λ=%s)", "theta", "phi", "lambda"],
    ControlZ => [control_display_symbol, "Z"],
    ControlX => [control_display_symbol, "X"],
    ISwap => ["x", "x"],
    ISwapDagger => ["x†", "x†"],
    Toffoli => [control_display_symbol, control_display_symbol, "X"],
    Swap => ["☒", "☒"],
    Readout => ["✲"],
)

"""
    get_instruction_symbol(instruction::AbstractInstruction)::String

Returns the symbol string that is associated with an `instruction`.

# Examples
```jldoctest
julia> get_instruction_symbol(control_z(1, 2))
"cz"

```
"""
get_instruction_symbol(gate::Gate) = get_instruction_symbol(get_gate_symbol(gate))
get_instruction_symbol(readout::Readout) = instruction_symbols[Readout]

get_instruction_symbol(gate::AbstractGateSymbol) = instruction_symbols[typeof(gate)]

instruction_symbols = Dict(
    Identity => "i",
    SigmaX => "x",
    SigmaY => "y",
    SigmaZ => "z",
    Hadamard => "h",
    Pi8 => "t",
    Pi8Dagger => "t_dag",
    X90 => "x_90",
    XM90 => "x_minus_90",
    Y90 => "y_90",
    YM90 => "y_minus_90",
    Z90 => "z_90",
    ZM90 => "z_minus_90",
    Rotation => "r",
    RotationX => "rx",
    RotationY => "ry",
    RotationZ => "rz",
    RootZZ => "root_zz",
    RootZZDagger => "root_zz_dag",
    PhaseShift => "p",
    Universal => "u",
    ControlZ => "cz",
    ControlX => "cx",
    ISwap => "iswap",
    ISwapDagger => "iswap_dag",
    Toffoli => "ccx",
    Swap => "swap",
    Readout => "readout",
)

instruction_to_gate_symbol_types = Dict(v => k for (k, v) in instruction_symbols)

"""
    get_symbol_for_instruction(instruction::String)::DataType

Returns a symbol given the corresponding `String`.

# Examples
```jldoctest
julia> get_symbol_for_instruction("cz")
Snowflurry.ControlZ

```
"""
get_symbol_for_instruction(instruction::String)::DataType =
    instruction_to_gate_symbol_types[instruction]


"""
    pop!(circuit::QuantumCircuit)

Removes the last instruction from `circuit.instructions`, and returns it.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1), sigma_x(2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> push!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────X────X──
                    



julia> pop!(c)
Gate Object: Snowflurry.ControlX
Connected_qubits	: [1, 2]
Operator:
(4, 4)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im

julia> c
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               
```
"""
function Base.pop!(circuit::QuantumCircuit)
    return pop!(get_circuit_instructions(circuit))
end

function Base.show(io::IO, circuit::QuantumCircuit, padding_width::Integer = 10)
    println(io, "Quantum Circuit Object:")
    println(io, "   qubit_count: $(get_num_qubits(circuit)) ")
    println(io, "   bit_count: $(get_num_bits(circuit)) ")
    print_circuit_diagram(io, circuit, padding_width)
end

function print_circuit_diagram(io::IO, circuit::QuantumCircuit, padding_width::Integer)
    circuit_layout = get_circuit_layout(circuit)
    split_circuit_layouts = get_split_circuit_layout(io, circuit_layout, padding_width)
    num_splits = length(split_circuit_layouts)

    for i_split = 1:num_splits
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
    circuit_layout = fill("", (wire_count, length(get_circuit_instructions(circuit)) + 1))
    add_qubit_labels_to_circuit_layout!(circuit_layout, get_num_qubits(circuit))

    for (i_step, instr) in enumerate(get_circuit_instructions(circuit))
        longest_symbol_length = get_longest_symbol_length(instr)
        add_wires_to_circuit_layout!(
            circuit_layout,
            i_step,
            get_num_qubits(circuit),
            longest_symbol_length,
        )
        add_coupling_lines_to_circuit_layout!(
            circuit_layout,
            instr,
            i_step,
            longest_symbol_length,
        )
        add_target_to_circuit_layout!(circuit_layout, instr, i_step, longest_symbol_length)
    end
    return circuit_layout
end

function get_longest_symbol_length(gate::Gate)
    return get_longest_symbol_length(get_gate_symbol(gate))
end

get_longest_symbol_length(readout::Readout) = length(get_display_symbols(readout)[1])

function get_longest_symbol_length(symbol::AbstractGateSymbol)
    largest_length = 0
    for symbol in get_display_symbols(symbol)
        symbol_length = length(symbol)
        if symbol_length > largest_length
            largest_length = symbol_length
        end
    end
    return largest_length
end

function add_qubit_labels_to_circuit_layout!(
    circuit_layout::Array{String},
    num_qubits::Integer,
)

    max_num_digits = ndigits(num_qubits)
    for i_qubit in range(1, length = num_qubits)
        num_digits = ndigits(i_qubit)
        padding = max_num_digits - num_digits
        id_wire = 2 * (i_qubit - 1) + 1
        circuit_layout[id_wire, 1] = "q[$i_qubit]:" * " "^padding
        circuit_layout[id_wire+1, 1] = String(fill(' ', length(circuit_layout[id_wire, 1])))
    end
end

function add_wires_to_circuit_layout!(
    circuit_layout::Array{String},
    i_step::Integer,
    num_qubits::Integer,
    longest_symbol_length::Integer,
)

    num_chars = 4 + longest_symbol_length
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
    instr::AbstractInstruction,
    i_step::Integer,
    longest_symbol_length::Integer,
)

    length_difference = longest_symbol_length - 1
    num_left_chars = 2 + floor(Int, length_difference / 2)
    num_right_chars = 2 + ceil(Int, length_difference / 2)
    min_wire = 2 * (minimum(get_connected_qubits(instr)) - 1) + 1
    max_wire = 2 * (maximum(get_connected_qubits(instr)) - 1) + 1
    for i_wire = (min_wire+1):(max_wire-1)
        if iseven(i_wire)
            circuit_layout[i_wire, i_step+1] =
                ' '^num_left_chars * "|" * ' '^num_right_chars
        else
            circuit_layout[i_wire, i_step+1] =
                '─'^num_left_chars * "|" * '─'^num_right_chars
        end
    end
end

function add_target_to_circuit_layout!(
    circuit_layout::Array{String},
    gate::Gate,
    i_step::Integer,
    longest_symbol_length::Integer,
)

    gate_symbols = get_display_symbols(get_gate_symbol(gate))

    append_symbol_to_circuit_layout!(
        gate_symbols,
        get_connected_qubits(gate),
        circuit_layout,
        i_step,
        longest_symbol_length,
    )

end

function add_target_to_circuit_layout!(
    circuit_layout::Array{String},
    readout::Readout,
    i_step::Integer,
    longest_symbol_length::Integer,
)

    readout_symbols = get_display_symbols(readout)

    append_symbol_to_circuit_layout!(
        readout_symbols,
        get_connected_qubits(readout),
        circuit_layout,
        i_step,
        longest_symbol_length,
    )

end

function append_symbol_to_circuit_layout!(
    symbolsVec::Vector{String},
    connected_qubits::Vector{Int},
    circuit_layout::Array{String},
    i_step::Integer,
    longest_symbol_length::Integer,
)

    for (i_target, target) in enumerate(connected_qubits)
        symbol_length = length(symbolsVec[i_target])
        length_difference = longest_symbol_length - symbol_length
        num_left_dashes = 2 + floor(Int, length_difference / 2)
        num_right_dashes = 2 + ceil(Int, length_difference / 2)
        id_wire = 2 * (target - 1) + 1
        circuit_layout[id_wire, i_step+1] =
            '─'^num_left_dashes * "$(symbolsVec[i_target])" * '─'^num_right_dashes
    end
end

function get_split_circuit_layout(
    io::IO,
    circuit_layout::Array{String},
    padding_width::Integer,
)

    (display_height, display_width) = displaysize(io)
    useable_width = display_width - padding_width
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
            push!(
                split_layout,
                hcat(circuit_layout[:, 1], circuit_layout[:, first_gate_step:(i_step-1)]),
            )
            char_count = num_qubit_label_chars + num_chars_in_step
            first_gate_step = i_step
        end
        if i_step == num_steps
            push!(
                split_layout,
                hcat(circuit_layout[:, 1], circuit_layout[:, first_gate_step:i_step]),
            )
        end
    end
    return split_layout
end

"""
    simulate(circuit::QuantumCircuit)::Ket

Performs an ideal simulation of the `circuit` and returns the final quantum state (i.e. the
wave function). The simulator assumes that the initial state ``\\Psi`` corresponds to the
zeroth Fock basis, i.e.: `ψ = fock(0, 2^get_num_qubits(circuit))`. The zeroth Fock basis
corresponds to the initial state of most superconducting quantum processors, i.e.:
```math
|\\Psi\\rangle = |0\\rangle^{\\otimes n},
```
where ``n`` is the number of qubits.

!!! note
    The input `circuit` must not include `Readout` instructions. Use
        [`simulate_shots`](@ref) for the simulation of `circuits` with `Readout`
        instructions.

The simulation utilizes the approach described in Listing 5 of
[Suzuki *et. al.* (2021)](https://doi.org/10.22331/q-2021-10-06-559).

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H──
          
q[2]:─────
          


julia> push!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
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
function simulate(circuit::QuantumCircuit)::Ket
    hilbert_space_size = 2^get_num_qubits(circuit)
    # initial state 
    ψ = fock(0, hilbert_space_size)
    for instr in get_circuit_instructions(circuit)
        if instr isa Readout
            throw(
                ArgumentError(
                    "$(:simulate) cannot process a circuit containing readouts. Use simulate_shots() instead.",
                ),
            )
        end
        apply_instruction!(ψ, instr)
    end
    return ψ
end

"""
    simulate_shots(c::QuantumCircuit, shots_count::Int = 100)

Emulates a quantum computer by running a circuit for a given number of shots and returning
measurement results, as prescribed by the `Readout` instructions present in the circuit. 
The distribution of measured states depends on the coefficients of the resulting state
Ket.

# Examples
```jldoctest simulate_shots; filter = r"00|11"
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1), control_x(1, 2), readout(1, 1), readout(2, 2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────*────✲───────
            |            
q[2]:───────X─────────✲──


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

    # create a circuit w/o readouts, as simulate() cannot process them
    qubit_count = get_num_qubits(c)
    c_sim = QuantumCircuit(qubit_count = qubit_count)

    readout_qubits = Set{Int}()
    readout_bit_to_qubit_map = Dict{Int,Int}()
    max_classical_bit = 0

    for instr in get_circuit_instructions(c)
        targets = get_connected_qubits(instr)

        if instr isa Readout
            @assert length(targets) == 1 "Readouts should have a single target qubit. Received: $(length(targets))"

            target = targets[1]

            if target in readout_qubits
                throw(ArgumentError("repeated Readout on the same qubit is not allowed"))
            end

            destination = get_destination_bit(instr)
            @assert destination > 0 "destination bit must be > 0, received: $destination"
            if haskey(readout_bit_to_qubit_map, destination)
                throw(
                    ArgumentError(
                        "conflicting destination bits in readouts present in circuit",
                    ),
                )
            end

            push!(readout_qubits, target)
            max_classical_bit = maximum([max_classical_bit, destination])

            readout_bit_to_qubit_map[destination] = target
        else
            for target in targets
                if target in readout_qubits
                    throw(
                        ArgumentError(
                            "cannot simulate circuit if a Gate follows a Readout",
                        ),
                    )
                end
            end

            push!(c_sim, instr)
        end
    end

    @assert length(readout_bit_to_qubit_map) > 0 "Missing readouts in input circuit"
    @assert max_classical_bit > 0

    ψ = simulate(c_sim)
    amplitudes = adjoint.(ψ) .* ψ

    weights = Float32[]

    for a in amplitudes
        push!(weights, a)
    end

    ##preparing the labels
    labels = String[]
    for i in range(0, length = length(amplitudes))
        s = bitstring(i)
        n = length(s)
        s_trimed = s[(n-qubit_count+1):n]
        push!(labels, s_trimed)
    end

    data = StatsBase.sample(labels, StatsBase.Weights(weights), shots_count)

    histogram = Dict{String,Int}()

    for state_label in data
        if haskey(histogram, state_label)
            histogram[state_label] += 1
        else
            histogram[state_label] = 1
        end
    end

    remapped_histogram =
        remap_counts(histogram, readout_bit_to_qubit_map, max_classical_bit)

    output_data = Vector{String}()

    for (stateLabel, count) in remapped_histogram
        for ___ = 1:count
            push!(output_data, stateLabel)
        end
    end
    return output_data
end

function remap_counts(
    data::Dict{String,Int},
    readouts_bit_to_qubit_map::Dict{Int,Int},
    bit_count::Int,
)::Dict{String,Int}

    histogram = Dict{Tuple,Int}()

    for (state_label, count) in data
        state = Tuple(parse(Int, c) for c in state_label)

        bit_tuple = Tuple(
            haskey(readouts_bit_to_qubit_map, bit) ?
            state[readouts_bit_to_qubit_map[bit]] : 0 for bit = 1:bit_count
        )

        if haskey(histogram, bit_tuple)
            histogram[bit_tuple] += count
        else
            histogram[bit_tuple] = count
        end
    end

    remapped_data = Dict{String,Int}()

    for (state, count) in histogram
        remapped_data[string(state...)] = count
    end

    return remapped_data
end


"""
    get_measurement_probabilities(
        circuit::QuantumCircuit,
        [target_qubits::Vector{<:Integer}]
    )::AbstractVector{<:Real}

Returns a list of the measurement probabilities for the `target_qubits` in the `circuit`.

If no `target_qubits` are provided, the probabilities are computed for all the qubits.

The measurement probabilities are listed from the smallest to the largest computational
basis state. For instance, for a 2-qubit [`QuantumCircuit`](@ref), the probabilities are listed
for \$\\left|00\\right\\rangle\$, \$\\left|01\\right\\rangle\$, \$\\left|10\\right\\rangle\$, and \$\\left|11\\right\\rangle\$.
!!! note
    By convention, qubit 1 is the leftmost bit, followed by every subsequent qubit. 
    The notation \$\\left|10\\right\\rangle\$ indicates that qubit 1 is in state
    \$\\left|1\\right\\rangle\$ and qubit 2 in state \$\\left|0\\right\\rangle\$.

# Examples
The following example constructs a `QuantumCircuit` where the probability of measuring \$\\left|10\\right\\rangle\$
is 50% and the probability of measuring \$\\left|11\\right\\rangle\$ is also 50%:

```jldoctest get_circuit_measurement_probabilities
julia> circuit = QuantumCircuit(qubit_count = 2);

julia> push!(circuit, hadamard(1), sigma_x(2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H───────
               
q[2]:───────X──
               



julia> get_measurement_probabilities(circuit)
4-element Vector{Float64}:
 0.0
 0.4999999999999999
 0.0
 0.4999999999999999

```

For the same `circuit`, the probability of measuring qubit 2 and finding 1 is 100%:
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

function get_measurement_probabilities(
    circuit::QuantumCircuit,
    target_qubits::Vector{<:Integer},
)::AbstractVector{<:Real}

    ket = simulate(circuit)
    return get_measurement_probabilities(ket, target_qubits)
end

"""
    inv(circuit::QuantumCircuit)

Return a `QuantumCircuit` which is the inverse of the input `circuit`. 
Each gate is replaced by its corresponding inverse, and the order of gates is reversed.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, rotation_y(1, pi/4));

julia> push!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Ry(0.7854)────*──
                     |  
q[2]:────────────────X──
                        



julia> inv(c)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──*────Ry(-0.7854)──
       |                 
q[2]:──X─────────────────
                         



```
"""
function Base.inv(circuit::QuantumCircuit)

    inverse_gates = Vector{AbstractInstruction}([
        Base.inv(g) for g in reverse(get_circuit_instructions(circuit))
    ])

    return QuantumCircuit(
        qubit_count = get_num_qubits(circuit),
        instructions = inverse_gates,
        name = circuit.name,
    )
end

"""
    get_num_gates_per_type(
        circuit::QuantumCircuit
    )::AbstractDict{<: AbstractString, <:Integer}

Returns a dictionary listing the number of gates of each type found in the `circuit`.

The dictionary keys are the instruction symbols of the gates while the values are the number
of gates found.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1), hadamard(2));

julia> push!(c, control_x(1, 2));

julia> push!(c, hadamard(2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H─────────*───────
                 |       
q[2]:───────H────X────H──
                         



julia> get_num_gates_per_type(c)
Dict{String, Int64} with 2 entries:
  "h"  => 3
  "cx" => 1

```
"""
function get_num_gates_per_type(
    circuit::QuantumCircuit,
)::AbstractDict{<:AbstractString,<:Integer}
    gate_counts = Dict{String,Int}()
    for instr in get_circuit_instructions(circuit)
        instruction_symbol = get_instruction_symbol(instr)
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
julia> c = QuantumCircuit(qubit_count = 2);

julia> push!(c, hadamard(1), hadamard(2));

julia> push!(c, control_x(1, 2))
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H─────────*──
                 |  
q[2]:───────H────X──
                    



julia> get_num_gates(c)
3

```
"""
get_num_gates(circuit::QuantumCircuit)::Integer = length(get_circuit_instructions(circuit))

"""
    permute_qubits!(
        circuit::QuantumCircuit,
        qubit_mapping::AbstractDict{T,T}
    ) where T<:Integer

Modifies a `circuit` by moving the gates to other qubits based on a `qubit_mapping`.

The dictionary `qubit_mapping` contains key-value pairs describing how to update the target
qubits. The key indicates which target qubit to change while the associated value specifies
the new qubit. All the keys in the dictionary must be present as values and vice versa.

For instance, `Dict(1 => 2)` is not a valid `qubit_mapping`, but `Dict(1 => 2, 2 => 1)` is valid.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 3);

julia> push!(c, sigma_x(1), hadamard(2), sigma_y(3))
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X────────────
                    
q[2]:───────H───────
                    
q[3]:────────────Y──                    



julia> permute_qubits!(c, Dict(1 => 3, 3 => 1))

julia> show(c)
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:────────────Y──
                    
q[2]:───────H───────
                    
q[3]:──X────────────
                    


```
"""
function permute_qubits!(
    circuit::QuantumCircuit,
    qubit_mapping::AbstractDict{T,T},
) where {T<:Integer}

    assert_qubit_mapping_is_valid(qubit_mapping, get_num_qubits(circuit))
    unsafe_permute_qubits!(circuit, qubit_mapping)
end

function assert_qubit_mapping_is_valid(
    qubit_mapping::AbstractDict{T,T},
    qubit_count::Integer,
) where {T<:Integer}

    sorted_keys = sort(collect(keys(qubit_mapping)))
    sorted_values = sort(collect(values(qubit_mapping)))
    if sorted_keys != sorted_values
        throw(ErrorException("the qubit mapping is invalid"))
    end
    if maximum(sorted_keys) > qubit_count
        throw(
            ErrorException(
                "the qubit mapping has a key or value that exceeds the circuit qubitCount",
            ),
        )
    end
end

function unsafe_permute_qubits!(
    circuit::QuantumCircuit,
    qubit_mapping::AbstractDict{T,T},
) where {T<:Integer}

    instructions_list = get_circuit_instructions(circuit)
    for (i, instructions) in enumerate(instructions_list)
        moved_instruction = move_instruction(instructions, qubit_mapping)
        circuit.instructions[i] = moved_instruction
    end
end

"""
    permute_qubits(
        circuit::QuantumCircuit,
        qubit_mapping::AbstractDict{T,T}
    )::QuantumCircuit where {T<:Integer}

Returns a `QuantumCircuit` that is a copy of `circuit` but where the gates have been moved
to other qubits based on a `qubit_mapping`.

The dictionary `qubit_mapping` contains key-value pairs describing how to update the target
qubits. The key indicates which target qubit to change while the associated value specifies
the new qubit. All the keys in the dictionary must be present as values and vice versa.

For instance, `Dict(1=>2)` is not a valid `qubit_mapping`, but `Dict(1=>2, 2=>1)` is valid.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 3);

julia> push!(c, sigma_x(1), hadamard(2), sigma_y(3))
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X────────────
                    
q[2]:───────H───────
                    
q[3]:────────────Y──
                    



julia> permute_qubits(c, Dict(1 => 3, 3 => 1))
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:────────────Y──
                    
q[2]:───────H───────
                    
q[3]:──X────────────
                    



```
"""
function permute_qubits(
    circuit::QuantumCircuit,
    qubit_mapping::AbstractDict{T,T},
)::QuantumCircuit where {T<:Integer}

    circuit_copy = deepcopy(circuit)
    permute_qubits!(circuit_copy, qubit_mapping)
    return circuit_copy
end
