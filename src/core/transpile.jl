using Snowflurry

abstract type Transpiler end

"""
    transpile(transpiler::Transpiler, circuit::QuantumCircuit)::QuantumCircuit

Returns a transpiled copy of the `circuit`. The transpilation process depends on the
`transpiler`.

The following transpilers are available:
- [`SequentialTranspiler`](@ref)
- [`CompressSingleQubitGatesTranspiler`](@ref)
- [`CastSwapToCZGateTranspiler`](@ref)
- [`CastCXToCZGateTranspiler`](@ref)
- [`CastISwapToCZGateTranspiler`](@ref)
- [`CastToffoliToCXGateTranspiler`](@ref)
- [`CastRootZZToZ90AndCZGateTranspiler`](@ref)
- [`CastToPhaseShiftAndHalfRotationXTranspiler`](@ref)
- [`CastUniversalToRzRxRzTranspiler`](@ref)
- [`CastRxToRzAndHalfRotationXTranspiler`](@ref)
- [`SimplifyRxGatesTranspiler`](@ref)
- [`SwapQubitsForAdjacencyTranspiler`](@ref)
- [`SimplifyRzGatesTranspiler`](@ref)
- [`CompressRzGatesTranspiler`](@ref)
- [`RemoveSwapBySwappingGatesTranspiler`](@ref)
- [`SimplifyTrivialGatesTranspiler`](@ref)
- [`UnsupportedGatesTranspiler`](@ref)
- [`ReadoutsAreFinalInstructionsTranspiler`](@ref)
- [`CircuitContainsAReadoutTranspiler`](@ref)
- [`ReadoutsDoNotConflictTranspiler`](@ref)
- [`DecomposeSingleTargetSingleControlGatesTranspiler`](@ref)
- [`RejectNonNativeInstructionsTranspiler`](@ref)
- [`RejectGatesOnExcludedPositionsTranspiler`](@ref)
- [`RejectGatesOnExcludedConnectionsTranspiler`](@ref)

# Example

```jldoctest  
julia> transpiler = CastCXToCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [control_x(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──*──
       |
q[2]:──X──

julia> transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:───────*───────
            |
q[2]:──H────Z────H──

```
"""
transpile(t::Transpiler, ::QuantumCircuit)::QuantumCircuit =
    throw(NotImplementedError(:transpile, t))

"""
    SequentialTranspiler(Vector{<:Transpiler})
    
Composite transpiler object which is constructed from an array 
of `Transpiler` stages. Calling 
    `transpile(::SequentialTranspiler,::QuantumCircuit)`
will apply each stage in sequence to the input circuit and return
a transpiled output circuit. The input and output circuits perform the same operation on
an arbitrary state `Ket` (up to a global phase).

# Examples
```jldoctest
julia> transpiler = SequentialTranspiler([
                        CompressSingleQubitGatesTranspiler(),
                        CastToPhaseShiftAndHalfRotationXTranspiler()
                    ]);

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), hadamard(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X────H──
               
q[2]:──────────
               



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Z────X_90────Z_90────X_m90────Z──
                                                              
q[2]:───────────────────────────────────
                                                              



julia> circuit = QuantumCircuit(
                    qubit_count = 3,
                    instructions = [
                        sigma_x(1),
                        sigma_y(1),
                        control_x(2,3),
                        phase_shift(1,π/3)
                    ])
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X────Y─────────P(1.0472)──

q[2]:────────────*───────────────
                 |               
q[3]:────────────X───────────────
                                 



julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──P(-2.0944)───────
                        
q[2]:────────────────*──
                     |  
q[3]:────────────────X──
                        



```
"""
struct SequentialTranspiler <: Transpiler
    stages::Vector{<:Transpiler}

    function SequentialTranspiler(stages::Vector{<:Transpiler})
        @assert length(stages) > 0

        new(stages)
    end
end

function transpile(
    transpiler::SequentialTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit
    for stage in transpiler.stages
        circuit = transpile(stage, circuit)
    end

    return circuit
end

"""
    CompressSingleQubitGatesTranspiler

Transpiler stage which gathers all single-qubit gates sharing a common target in an input 
circuit and combines them into single `Universal` gates in a new circuit.
Gate ordering may differ when gates are applied to different qubits, 
but the input and output circuits perform the same operation on an arbitrary state `Ket`
(up to a global phase).

# Examples
```jldoctest
julia> transpiler = CompressSingleQubitGatesTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1), sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X────Y──
               
q[2]:──────────
               



julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──U(θ=0.0000,ϕ=3.1416,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                      



julia> compare_circuits(circuit,transpiled_circuit)
true

julia> circuit = QuantumCircuit(
                    qubit_count = 3,
                    instructions = [
                        sigma_x(1)
                        sigma_y(1)
                        control_x(2,3)
                        phase_shift(1,π/3)
                    ])
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X────Y─────────P(1.0472)──
                                 
q[2]:────────────*───────────────
                 |               
q[3]:────────────X───────────────
                                 



julia> transpiled_circuit=transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──U(θ=0.0000,ϕ=-2.0944,λ=0.0000)───────
                                            
q[2]:────────────────────────────────────*──
                                         |  
q[3]:────────────────────────────────────X──
                                            




julia> compare_circuits(circuit,transpiled_circuit)
true

```
"""
struct CompressSingleQubitGatesTranspiler <: Transpiler end

function rounding_safe_acos(theta::Real, threshold::Real = 1e-10)
    if 1.0 < abs(theta) < 1.0 + threshold
        theta = round(theta)
    end
    return acos(theta)
end

# convert a single-target gate to a Universal gate
function as_universal_gate(target::Integer, op::AbstractOperator)::Gate{Universal}
    @assert size(op) == (2, 2)

    matrix = get_matrix(op)

    #find global phase offset angle
    alpha = get_canonical_global_phase(matrix)

    #remove global offset
    matrix *= exp(-im * alpha)

    theta = (2 * rounding_safe_acos(real(matrix[1, 1])))

    if (isapprox(theta, 0.0, atol = 1e-6)) || (isapprox(theta, 2 * π, atol = 1e-6))
        lambda = 0.0
        phi = real(exp(-im * π / 2)log(matrix[2, 2] / cos(theta / 2)))
    else
        lambda = real(exp(-im * π / 2) * log(-matrix[1, 2] / sin(theta / 2)))
        phi = real(exp(-im * π / 2) * log(matrix[2, 1] / sin(theta / 2)))
    end

    # test if universal gate can be constructed from this operator
    @assert isapprox(
        real(matrix[2, 2]),
        real(exp(im * (lambda + phi)) * cos(theta / 2)),
        atol = 1e-6,
    )

    return universal(target, theta, phi, lambda)
end

# compress (combine) several single-target gates with a common target to a Universal gate
# does not assert gates having common target
function unsafe_compress_to_universal(gates::Vector{Gate}, target::Int)::Gate{Universal}
    combined_op = eye()

    for gate in gates
        symbol = get_gate_symbol(gate)
        @assert get_num_connected_qubits(symbol) == 1 (
            "Received gate with multiple targets: $(gate)"
        )
        targets = get_connected_qubits(gate)
        @assert length(targets) == 1 ("Received gate with multiple targets: $gate")
        @assert targets[1] == target ("Gates in array do not share common target")

        combined_op = get_operator(get_gate_symbol(gate)) * combined_op
    end

    return as_universal_gate(target, combined_op)
end

set_of_rz_gates = [Z90, ZM90, SigmaZ, Pi8, Pi8Dagger, PhaseShift, RotationZ]

is_multi_target(symbol::AbstractGateSymbol) = get_num_connected_qubits(symbol) > 1
is_multi_target(gate::Gate) = is_multi_target(get_gate_symbol(gate))
is_multi_target(readout::Readout) = false
is_multi_target(instr::AbstractInstruction) =
    throw(NotImplementedError(:is_multi_target, instr))

function is_not_rz_gate(::Gate{SymbolType})::Bool where {SymbolType<:AbstractGateSymbol}
    return !(SymbolType in set_of_rz_gates)
end

is_not_rz_gate(readout::Readout) = true
is_not_rz_gate(instr::AbstractInstruction) =
    throw(NotImplementedError(:is_not_rz_gate, instr))

is_multi_target_or_not_rz(instr::AbstractInstruction) =
    is_multi_target(instr) || is_not_rz_gate(instr)

is_readout(instr::AbstractInstruction) = typeof(instr) == Readout

is_multi_target_or_readout(instr::AbstractInstruction) =
    is_multi_target(instr) || is_readout(instr)

function find_and_compress_blocks(
    circuit::QuantumCircuit,
    is_boundary::Function,
    compression_function::Function,
)::QuantumCircuit

    instructions = get_circuit_instructions(circuit)

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output_circuit = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    # Split circuit into blocks of single-target gates that
    # share a common target, separated by boundaries. 
    # What constitutes a boundary is determined using 
    # the `is_boundary` input. 
    # Common-target gates inside a block can be combined, 
    # but not with gates in another block, as a boundary
    # is present between them. 
    # If first gate is a boundary, first block is left empty. 

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
    blocks_per_target = Dict{Int,Vector{Vector{Int}}}(Dict())

    #initialize empty blocks at all targets
    for target = 1:qubit_count
        blocks_per_target[target] = [[]]
    end

    ######################################################
    #
    #  boudaries is a Vector of Tuple{i_gate::Int,targets::Int}
    #  where:
    #       i_gate  : the gate's index in 'gates'
    #       targets : the targets of gate[i_gate]
    #               
    boundaries = Vector{Tuple{Int,Vector{Int}}}([])

    current_block = [1 for _ = 1:qubit_count]

    can_be_placed = Dict(target => [true] for target = 1:qubit_count)

    placed_instructions = [false for _ = 1:length(instructions)]

    for (i_instr, instr) in enumerate(instructions)
        targets = get_connected_qubits(instr)

        if is_boundary(instr)

            # add group boundary at each of those targets
            push!(boundaries, (i_instr, targets))

            for target in targets
                # create new empty group at those targets
                push!(blocks_per_target[target], [])

                # disallow placement until boundary is passed
                push!(can_be_placed[target], false)
            end

        else
            target = targets[1]

            # inside a group, common-target gates are put in blocks.
            # append gate to last block
            push!(blocks_per_target[target][end], i_instr)
        end
    end

    # reverse so pop! returns first boundary
    boundaries = reverse(boundaries)

    iteration_count = 0

    #build compressed circuit
    while true
        iteration_count += 1

        #place allowed blocks
        for target = 1:qubit_count

            block_index = current_block[target]

            if can_be_placed[target][block_index]

                block = blocks_per_target[target][block_index]

                instructions_block::Vector{Gate} =
                    [convert(Gate, instructions[i]) for i in block]

                if length(block) > 1
                    push!(output_circuit, compression_function(instructions_block, target))

                    for i_instr in block
                        placed_instructions[i_instr] = true
                    end
                elseif length(block) == 1
                    #no need to compress individual gate
                    push!(output_circuit, instructions_block[1])

                    placed_instructions[block[1]] = true
                end

                can_be_placed[target][block_index] = false
            end
        end

        if !isempty(boundaries)
            # pass boundary
            (i_instr, targets) = pop!(boundaries)

            push!(output_circuit, instructions[i_instr])
            placed_instructions[i_instr] = true

            #unlock next blocks for those targets (boundary passed)
            for target in targets
                current_block[target] += 1
                can_be_placed[target][current_block[target]] = true
            end

        end

        if all(placed_instructions)
            break
        end

        @assert iteration_count < length(instructions) + 1 ("Failed to construct output")
    end

    return output_circuit
end


function transpile(
    ::CompressSingleQubitGatesTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit
    return find_and_compress_blocks(
        circuit,
        is_multi_target_or_readout,
        unsafe_compress_to_universal,
    )
end

function cast_to_cz(gate::AbstractGateSymbol, _::Vector{Int})
    throw(NotImplementedError(:cast_to_cz, gate))
end

function cast_to_cz(::Swap, connected_qubits::Vector{Int})::AbstractVector{Gate}
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    return Vector{Gate}([
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

"""
    CastSwapToCZGateTranspiler

Transpiler stage which expands all Swap gates into `CZ` gates and single-qubit gates. The
input and output circuits perform the same operation on an arbitrary state `Ket`
(up to a global phase).

# Examples
```jldoctest
julia> transpiler = CastSwapToCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [swap(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──☒──
       |
q[2]:──☒──

julia> transpile(transpiler,circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:───────────*────Y_m90────────────*────Y_90─────────────*──────────
                |                     |                     |          
q[2]:──Y_m90────Z─────────────Y_90────Z────────────Y_m90────Z────Y_90──
                                              

```
"""
struct CastSwapToCZGateTranspiler <: Transpiler end

function transpile(::CastSwapToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in get_circuit_instructions(circuit)
        if instr isa Snowflurry.Gate{Swap}
            push!(
                output,
                cast_to_cz(get_gate_symbol(instr), get_connected_qubits(instr))...,
            )
        else
            push!(output, instr)
        end
    end

    return output
end

function cast_to_cz(::ControlX, connected_qubits::Vector{Int})::AbstractVector{Gate}
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    return Vector{Gate}([hadamard(q2), control_z(q1, q2), hadamard(q2)])
end

"""
    CastCXToCZGateTranspiler

Transpiler stage which expands all `CX` gates into `CZ` and `Hadamard` gates. The input and
output circuits perform the same operation on an arbitrary state `Ket` (up to a global
phase).

# Examples
```jldoctest
julia> transpiler = CastCXToCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [control_x(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──*──
       |
q[2]:──X──

julia> transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:───────*───────
            |
q[2]:──H────Z────H──
```
"""
struct CastCXToCZGateTranspiler <: Transpiler end

function transpile(::CastCXToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in get_circuit_instructions(circuit)
        if instr isa Snowflurry.Gate{ControlX}
            push!(
                output,
                cast_to_cz(get_gate_symbol(instr), get_connected_qubits(instr))...,
            )
        else
            push!(output, instr)
        end
    end

    return output
end

function cast_to_cz(::ISwap, connected_qubits::Vector{Int})::AbstractVector{Gate}
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    return Vector{Gate}([
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

function cast_to_cz(::ISwapDagger, connected_qubits::Vector{Int})::AbstractVector{Gate}
    @assert length(connected_qubits) == 2
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]

    return Vector{Gate}([
        y_minus_90(q1),
        x_minus_90(q2),
        control_z(q1, q2),
        y_minus_90(q1),
        x_90(q2),
        control_z(q1, q2),
        y_90(q1),
        x_90(q2),
    ])
end

"""
    CastISwapToCZGateTranspiler

Transpiler stage which expands all `ISwap` and `ISwapDagger` gates into `CZ` gates and
single-qubit gates. The input and output circuits perform the same operation on an arbitrary
state `Ket` (up to a global phase).

# Examples
```jldoctest
julia> transpiler = CastISwapToCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [iswap(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──x──
       |
q[2]:──x──

julia> transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Y_m90─────────────*────Y_90─────────────*────Y_90──────────
                         |                     |                  
q[2]:───────────X_m90────Z────────────X_m90────Z────────────X_90──
                                                                  

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [iswap_dagger(1, 2)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──x†──
       |   
q[2]:──x†──

julia> transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Y_m90─────────────*────Y_m90────────────*────Y_90──────────
                         |                     |                  
q[2]:───────────X_m90────Z─────────────X_90────Z────────────X_90──

```
"""
struct CastISwapToCZGateTranspiler <: Transpiler end

function transpile(::CastISwapToCZGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in get_circuit_instructions(circuit)
        if instr isa Union{Snowflurry.Gate{ISwap},Snowflurry.Gate{ISwapDagger}}
            push!(
                output,
                cast_to_cz(get_gate_symbol(instr), get_connected_qubits(instr))...,
            )
        else
            push!(output, instr)
        end
    end

    return output
end

function cast_to_cx(gate::Toffoli, connected_qubits::Vector{Int})::AbstractVector{Gate}
    @assert length(connected_qubits) == 3
    q1 = connected_qubits[1]
    q2 = connected_qubits[2]
    q3 = connected_qubits[3]

    h(q) = hadamard(q)
    cnot(q1, q2) = control_x(q1, q2)
    t(q) = pi_8(q)
    t_dag(q) = pi_8_dagger(q)

    return Vector{Gate}([
        h(q3),
        cnot(q2, q3),
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

"""
    CastToffoliToCXGateTranspiler

Transpiler stage which expands all Toffoli gates into `CX` gates and single-qubit gates. The
input and output circuits perform the same operation on an arbitrary state `Ket` (up to a
global phase).

# Examples
```jldoctest
julia> transpiler = CastToffoliToCXGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 3, instructions = [toffoli(1, 2, 3)])
Quantum Circuit Object:
   qubit_count: 3
   bit_count: 3
q[1]:──*──
       |
q[2]:──*──
       |
q[3]:──X──

julia> transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──────────────────*────────────────────*──────────────*─────────T──────────*──
                       |                    |              |                    |  
q[2]:───────*──────────|─────────*──────────|────T─────────X──────────────T†────X──
            |          |         |          |                                      
q[3]:──H────X────T†────X────T────X────T†────X─────────T─────────H──────────────────
                                                                                   

```
"""
struct CastToffoliToCXGateTranspiler <: Transpiler end

function transpile(::CastToffoliToCXGateTranspiler, circuit::QuantumCircuit)::QuantumCircuit
    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in get_circuit_instructions(circuit)
        if instr isa Snowflurry.Gate{Toffoli}
            push!(
                output,
                cast_to_cx(get_gate_symbol(instr), get_connected_qubits(instr))...,
            )
        else
            push!(output, instr)
        end
    end

    return output
end

"""
    CastRootZZToZ90AndCZGateTranspiler

Transpiler stage which converts all `RootZZ` and `RootZZDagger` gates into `Z90` 
(or `ZM90`) gates and a `ControlZ` gate. The input and output circuits
perform the same operation on an arbitrary state `Ket` (up to a global phase).

# Examples
```jldoctest
julia> transpiler = CastRootZZToZ90AndCZGateTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [root_zz(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──√ZZ──
        |
q[2]:──√ZZ──

julia> transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──Z_90────────────*──
                       |
q[2]:──────────Z_90────Z──

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [root_zz_dagger(1, 2)])
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──√ZZ†──
        |
q[2]:──√ZZ†──

julia> transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──Z_m90─────────────*──
                         |
q[2]:───────────Z_m90────Z──
```
"""
struct CastRootZZToZ90AndCZGateTranspiler <: Transpiler end

function transpile(
    ::CastRootZZToZ90AndCZGateTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit
    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in get_circuit_instructions(circuit)
        if instr isa Snowflurry.Gate{RootZZ}
            (target_1, target_2) = get_connected_qubits(instr)
            push!(output, z_90(target_1), z_90(target_2), control_z(target_1, target_2))
        elseif instr isa Snowflurry.Gate{RootZZDagger}
            (target_1, target_2) = get_connected_qubits(instr)
            push!(
                output,
                z_minus_90(target_1),
                z_minus_90(target_2),
                control_z(target_1, target_2),
            )
        else
            push!(output, instr)
        end
    end

    return output
end

"""
    CastToPhaseShiftAndHalfRotationXTranspiler,

Transpiler stage which converts all single-qubit gates in the input circuit into
combinations of `PhaseShift` and `RotationX` with angle π/2 in the output circuit. For any
gate in the input circuit, the number of gates in the output varies between zero and 5. The
input and output circuits perform the same operation on an arbitrary state `Ket` (up to a
global phase).

# Fields
- `atol::Real` -- Absolute tolerance for the comparison of rotation angles (default = 1e-6).

# Examples
```jldoctest
julia> transpiler = CastToPhaseShiftAndHalfRotationXTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X──
          
q[2]:─────
          



julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Z────X_90────Z────X_m90──
                                                 
q[2]:───────────────────────────
                                                 



julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_y(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Y──
          
q[2]:─────
          



julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──X_90────Z────X_m90──

q[2]:──────────────────────
                                           



julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [universal(1, 0., 0., 0.)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──U(θ=0.0000,ϕ=0.0000,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                      



julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:
     
q[2]:
     



julia> compare_circuits(circuit, transpiled_circuit)
true

```
"""
struct CastToPhaseShiftAndHalfRotationXTranspiler <: Transpiler
    atol::Real
end

CastToPhaseShiftAndHalfRotationXTranspiler() =
    CastToPhaseShiftAndHalfRotationXTranspiler(1e-6)

function simplify_rz_gate(gate::Gate{PhaseShift}; atol = 1e-6)::Union{Gate,Nothing}

    target = get_connected_qubits(gate)[1]
    phase_angle = get_gate_symbol(gate).phi

    phase_angle = phase_angle % (2 * π)

    if isapprox(phase_angle, π / 2, atol = atol) ||
       isapprox(phase_angle, -3 * π / 2, atol = atol)
        return z_90(target)

    elseif isapprox(abs(phase_angle), π, atol = atol)
        return sigma_z(target)

    elseif isapprox(phase_angle, -π / 2, atol = atol) ||
           isapprox(phase_angle, 3 * π / 2, atol = atol)
        return z_minus_90(target)

    elseif isapprox(phase_angle, π / 4, atol = atol)
        return pi_8(target)

    elseif isapprox(phase_angle, -π / 4, atol = atol)
        return pi_8_dagger(target)

    elseif isapprox(phase_angle, 0.0, atol = atol)
        return nothing

    else
        return phase_shift(target, phase_angle)

    end
end

function simplify_rx_gate(gate::Gate{RotationX}; atol = 1e-6)::Union{Gate,Nothing}

    target = get_connected_qubits(gate)[1]
    theta = get_gate_symbol(gate).theta

    if isapprox(theta, π / 2, atol = atol)
        return x_90(target)

    elseif isapprox(abs(theta), π, atol = atol)
        return sigma_x(target)

    elseif isapprox(theta, -π / 2, atol = atol)
        return x_minus_90(target)

    elseif isapprox(theta, 0.0, atol = atol)
        return nothing

    else
        return rotation_x(target, theta)

    end
end


function cast_to_phase_shift_and_half_rotation_x(gate::Universal, target::Int; atol = 1e-6)
    params = get_gate_parameters(gate)

    theta = params["theta"]
    phi = params["phi"]
    lambda = params["lambda"]

    gate_array = Vector{Gate}([])

    if !(isapprox(lambda, 0.0, atol = atol))
        push!(gate_array, simplify_rz_gate(phase_shift(target, lambda); atol = atol))
    end

    if !(isapprox(theta, 0.0, atol = atol))
        push!(gate_array, x_90(target))
        push!(gate_array, simplify_rz_gate(phase_shift(target, theta); atol = atol))
        push!(gate_array, x_minus_90(target))
    end

    if !(isapprox(phi, 0.0, atol = atol))
        push!(gate_array, simplify_rz_gate(phase_shift(target, phi); atol = atol))
    end

    return gate_array
end

function transpile(
    transpiler_stage::CastToPhaseShiftAndHalfRotationXTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    instructions = get_circuit_instructions(circuit)

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output_circuit = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    atol = transpiler_stage.atol

    for instr in instructions

        targets = get_connected_qubits(instr)

        if length(targets) > 1 || instr isa Readout
            push!(output_circuit, instr)
        else
            if !(instr isa Snowflurry.Gate{Universal} || instr isa Readout)
                instr = get_gate_symbol(
                    as_universal_gate(targets[1], get_operator(get_gate_symbol(instr))),
                )
            else
                instr = get_gate_symbol(instr)
            end

            gate_array =
                cast_to_phase_shift_and_half_rotation_x(instr, targets[1]; atol = atol)
            push!(output_circuit, gate_array...)
        end
    end

    return output_circuit
end

# Cast a Universal gate as U=Rz(β)Rx(γ)Rz(δ)
# See: Nielsen and Chuang, Quantum Computation and Quantum Information, p175.
function cast_to_rz_rx_rz(gate::Universal, target::Int)::Vector{Gate}
    params = get_gate_parameters(gate)

    γ = params["theta"]
    β = params["phi"] + π / 2
    δ = params["lambda"] - π / 2

    gate_array = Vector{Gate}([])

    push!(gate_array, phase_shift(target, δ))

    push!(gate_array, rotation_x(target, γ))

    push!(gate_array, phase_shift(target, β))

    return gate_array
end

# Decompose a Universal gate as U = exp(im*α)AXBXC.
# See: Nielsen and Chuang, "Quantum Computation and Quantum Information", p175.
function decompose_universal_to_A_B_C_gates(
    gate::Universal,
    target::Int,
)::Tuple{Real,Gate,Gate,Gate}
    params = get_gate_parameters(gate)

    γ = params["theta"]
    β = params["phi"]
    δ = params["lambda"]

    A = rotation_z(β) * rotation_y(γ / 2.0)

    B = rotation_y(-γ / 2.0) * rotation_z(-(δ + β) / 2.0)

    C = rotation_z(target, (δ - β) / 2.0)

    universal_op = get_operator(gate)

    X = sigma_x()
    decomposition_op = A * X * B * X * get_operator(get_gate_symbol(C))

    @assert compare_operators(universal_op, decomposition_op)

    α = Snowflurry.get_canonical_global_phase(get_matrix(decomposition_op))

    return α, as_universal_gate(target, A), as_universal_gate(target, B), C
end

"""
    CastUniversalToRzRxRzTranspiler

Transpiler stage which finds `Universal` gates in an input circuit and casts them into a
sequence of `PhaseShift` (P), `RotationX` (Rx) and `PhaseShift` (P) gates in a new circuit.
The input and output circuits perform the same operation on an arbitrary state `Ket` (up to
a global phase).

# Examples
```jldoctest
julia> transpiler = CastUniversalToRzRxRzTranspiler();

julia> circuit = QuantumCircuit(
                    qubit_count = 2,
                    instructions = [universal(1, π/2, π/4, π/8)]
                )
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──U(θ=1.5708,ϕ=0.7854,λ=0.3927)──
                                      
q[2]:─────────────────────────────────
                                      

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──P(-1.1781)────Rx(1.5708)────P(2.3562)──
                                              
q[2]:─────────────────────────────────────────
                                              

julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [universal(1, 0, π/4, 0)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──U(θ=0.0000,ϕ=0.7854,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                      

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──P(-1.5708)────Rx(0.0000)────P(2.3562)──
                                              
q[2]:─────────────────────────────────────────
                                              

julia> compare_circuits(circuit,transpiled_circuit)
true

```
"""
struct CastUniversalToRzRxRzTranspiler <: Transpiler end

function transpile(
    ::CastUniversalToRzRxRzTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    instructions = get_circuit_instructions(circuit)

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output_circuit = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in instructions

        targets = get_connected_qubits(instr)

        if length(targets) > 1 || instr isa Readout
            push!(output_circuit, instr)
        else
            if !(instr isa Snowflurry.Gate{Universal})
                instr = get_gate_symbol(
                    as_universal_gate(targets[1], get_operator(get_gate_symbol(instr))),
                )
            else
                instr = get_gate_symbol(instr)
            end

            gate_array = cast_to_rz_rx_rz(instr, targets[1])
            push!(output_circuit, gate_array...)
        end
    end

    return output_circuit
end

function cast_rx_to_rz_and_half_rotation_x(gate::Gate{RotationX})::Vector{Gate}
    target = get_connected_qubits(gate)[1]

    theta = get_gate_symbol(gate).theta

    gate_array = Vector{Gate}([])

    push!(gate_array, z_90(target))
    push!(gate_array, x_90(target))
    push!(gate_array, phase_shift(target, theta))
    push!(gate_array, x_minus_90(target))
    push!(gate_array, z_minus_90(target))

    return gate_array
end

"""
    CastRxToRzAndHalfRotationXTranspiler

Transpiler stage which finds `RotationX(θ)` gates in an input circuit and converts (casts) 
them into a sequence of gates (`Z90`, `X90`, `PhaseShift(θ)`, `XM90`, and `ZM90`) in a new
circuit. The input and output circuits perform the same operation on an arbitrary state
`Ket` (up to a global phase).

# Examples
```jldoctest
julia> transpiler=CastRxToRzAndHalfRotationXTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [rotation_x(1,π/8)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Rx(0.3927)──
                   
q[2]:──────────────
                   

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Z_90────X_90────P(0.3927)────X_m90────Z_m90──
                                                    
q[2]:───────────────────────────────────────────────
                                                    

julia> compare_circuits(circuit, transpiled_circuit)
true

```
"""
struct CastRxToRzAndHalfRotationXTranspiler <: Transpiler end


function transpile(
    ::CastRxToRzAndHalfRotationXTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    instructions = get_circuit_instructions(circuit)

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output_circuit = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in instructions

        if instr isa Snowflurry.Gate{RotationX}
            gate_array = cast_rx_to_rz_and_half_rotation_x(instr)
            push!(output_circuit, gate_array...)
        else
            push!(output_circuit, instr)
        end
    end

    return output_circuit
end

"""
    SimplifyRxGatesTranspiler

Transpiler stage which finds `RotationX` gates in an input circuit and, based on their 
angle theta, casts them to one of the right-angle `RotationX` gates 
(`SigmaX`, `X90`, or `XM90`). In the case where `theta≈0.`, the gate is removed.
The input and output circuits perform the same operation on an arbitrary state `Ket`
(up to a global phase).

# Fields
- `atol::Real` -- Absolute tolerance for the comparison of rotation angles (default = 1e-6).

# Examples
```jldoctest
julia> transpiler = SimplifyRxGatesTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [rotation_x(1, pi/2)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Rx(1.5708)──
                   
q[2]:──────────────
                   

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X_90──
             
q[2]:────────
             

julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [rotation_x(1, pi)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Rx(3.1416)──
                   
q[2]:──────────────
                   


julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X──
          
q[2]:─────
          

julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [rotation_x(1, 0.)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Rx(0.0000)──
                   
q[2]:──────────────
                   


julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:
     
q[2]:
     



julia> compare_circuits(circuit, transpiled_circuit)
true

```
"""
struct SimplifyRxGatesTranspiler <: Transpiler
    atol::Real
end

SimplifyRxGatesTranspiler() = SimplifyRxGatesTranspiler(1e-6)


function transpile(
    transpiler_stage::SimplifyRxGatesTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    atol = transpiler_stage.atol

    for instr in get_circuit_instructions(circuit)
        if instr isa Snowflurry.Gate{RotationX}
            new_gate = simplify_rx_gate(instr, atol = atol)

            if !isnothing(new_gate)
                push!(output, new_gate)
            end
        else
            push!(output, instr)
        end
    end

    return output
end

"""
    SwapQubitsForAdjacencyTranspiler

Transpiler stage which adds `Swap` gates around multi-qubit gates so that the 
final `Operator` acts on adjacent qubits. The input and output circuits
perform the same operation on an arbitrary state `Ket` (up to a global phase).

# Fields
- `connectivity::AbstractConnectivity` -- Connectivity for the placement of `Swap` gates.

# Examples
```jldoctest
julia> transpiler = SwapQubitsForAdjacencyTranspiler(LineConnectivity(6));

julia> circuit = QuantumCircuit(qubit_count = 6, instructions = [toffoli(4, 6, 1)])
Quantum Circuit Object:
   qubit_count: 6 
   bit_count: 6 
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
          




julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 6 
   bit_count: 6 
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
                                                            



julia> compare_circuits(circuit, transpiled_circuit)
true

```
"""
struct SwapQubitsForAdjacencyTranspiler <: Transpiler
    connectivity::AbstractConnectivity
end

function remap_qubits_to_adjacent(
    connected_qubits::Vector{Int},
    connectivity::AbstractConnectivity,
)::Tuple{Vector{Int},Vector{Int},Vector{Vector{Int}}}

    min_qubit = minimum(connected_qubits)

    distances =
        [get_qubits_distance(min_qubit, pos, connectivity) for pos in connected_qubits]

    sorting_order = sortperm(distances)

    # this contains an array of consecutive elements,
    # in the same unsorted order as the input,
    # meaning: sortperm(connected_qubits)==sortperm(mapped_indices)
    mapped_indices = sortperm(sorting_order)

    excluded = Vector{Int}([])

    # create paths so that connected_qubits become adjacent on this connectivity
    paths = [[connected_qubits[sorting_order[1]]]]
    for pos in connected_qubits[sorting_order[2:end]]
        path = path_search(min_qubit, pos, connectivity, excluded)
        @assert length(path) > 0 "cannot find path on connectivity given excluded positions"
        push!(paths, path[1:end-1])

        # avoid collisions between assigned destinations and future path searches
        if min_qubit != path[end-1]
            push!(excluded, min_qubit)
            min_qubit = path[end-1]
        end
    end

    adjacent_mapping = [path[end] for path in paths]
    paths = [path[1:end-1] for path in paths]

    # reorder in same unsorted order as input
    adjacent_mapping = adjacent_mapping[mapped_indices]
    paths = paths[mapped_indices]

    return (adjacent_mapping, sorting_order, paths)
end

function remap_connections_using_swaps(
    gates_block::Vector{<:Gate},
    adjacent_mapping::Vector{Int},
    paths::Vector{Vector{Int}},
)::Vector{Gate}

    for (current_qubit_num, path) in zip(adjacent_mapping, paths)

        while !isempty(path)
            next_pos = pop!(path)

            # surround current gates_block with swap gates 
            # to bring one step closer
            gates_block = vcat(
                swap(current_qubit_num, next_pos),
                gates_block,
                swap(current_qubit_num, next_pos),
            )

            current_qubit_num = next_pos
        end
    end

    return gates_block
end


function transpile(
    transpiler::SwapQubitsForAdjacencyTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    instructions = get_circuit_instructions(circuit)

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output_circuit = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in instructions

        connected_qubits = get_connected_qubits(instr)

        if length(connected_qubits) > 1

            (adjacent_mapping, sorting_order, paths) =
                remap_qubits_to_adjacent(connected_qubits, transpiler.connectivity)

            mapping_dict = Dict([
                old_number => new_number for
                (old_number, new_number) in zip(connected_qubits, adjacent_mapping)
            ])

            gates_block = [move_instruction(instr, mapping_dict)]

            @assert get_connected_qubits(gates_block[1]) == adjacent_mapping (
                "Failed to construct gate: $(typeof((gates_block[1])))"
            )

            # leaving first (minimum) qubit unchanged,
            # add swaps starting from the farthest qubit
            adjacent_mapping = adjacent_mapping[reverse(sorting_order[2:end])]
            paths = paths[reverse(sorting_order[2:end])]

            gates_block =
                remap_connections_using_swaps(gates_block, adjacent_mapping, paths)

            maximum_qubit_required = max(instr.connected_qubits...)

            for gate in gates_block
                maximum_qubit_required =
                    max(maximum_qubit_required, gate.connected_qubits...)
            end

            if maximum_qubit_required > output_circuit.qubit_count
                output_circuit = Snowflurry.update_circuit_qubit_count(
                    output_circuit,
                    maximum_qubit_required,
                )
            end

            push!(output_circuit, gates_block...)
        else
            # no effect for single-target gate
            push!(output_circuit, instr)
        end
    end

    return output_circuit
end

"""
    SimplifyRzGatesTranspiler

Transpiler stage which finds `PhaseShift` gates in an input circuit and, based on their 
phase angle phi, casts them to one of the right-angle `RotationZ` gates (`SigmaZ`, `Z90`,
`ZM90`, `Pi8` or `Pi8Dagger`). In the case where `phi≈0.`, the  gate is removed. The input
and output circuits perform the same operation on an arbitrary state `Ket` (up to a global
phase). The tolerance  used for `Base.isapprox()` in each case can be set by passing an
optional argument to the `Transpiler`, e.g:
`transpiler=SimplifyRzGatesTranspiler(1.0e-10)`

# Fields
- `atol::Real` -- Absolute tolerance for the comparison of rotation angles (default = 1e-6).

# Examples
```jldoctest
julia> transpiler = SimplifyRzGatesTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [phase_shift(1, pi/2)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──P(1.5708)──
                  
q[2]:─────────────
                  

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Z_90──
             
q[2]:────────
             

julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [phase_shift(1, pi)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──P(3.1416)──
                  
q[2]:─────────────
                  

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Z──
          
q[2]:─────
          

julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [phase_shift(1, 0.)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──P(0.0000)──
                  
q[2]:─────────────
                  

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:
     
q[2]:
     



julia> compare_circuits(circuit, transpiled_circuit)
true

```
"""
struct SimplifyRzGatesTranspiler <: Transpiler
    atol::Real
end

SimplifyRzGatesTranspiler() = SimplifyRzGatesTranspiler(1e-6)


function transpile(
    transpiler_stage::SimplifyRzGatesTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    atol = transpiler_stage.atol

    for instr in get_circuit_instructions(circuit)
        if instr isa Snowflurry.Gate{PhaseShift}
            new_gate = simplify_rz_gate(instr, atol = atol)
            if !isnothing(new_gate)
                push!(output, new_gate)
            end
        else
            push!(output, instr)
        end
    end

    return output
end

"""
    CompressRzGatesTranspiler

Transpiler stage which gathers all Rz-type gates sharing a common target in an input 
circuit and combines them into a single PhaseShift gate in a new circuit.
Gates ordering may differ when gates are applied to different qubits, 
but the input and output circuits perform the same operation on an arbitrary state `Ket`
(up to a global phase).

# Examples
```jldoctest
julia> transpiler = CompressRzGatesTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [sigma_z(1), z_90(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──Z────Z_90──
                  
q[2]:─────────────
                  

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──P(-1.5708)──
                   
q[2]:──────────────
                   

julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(
                    qubit_count = 3,
                    instructions = [sigma_z(1), pi_8(1), control_x(2,3), z_minus_90(1)]
                )
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──Z────T─────────Z_m90──
                             
q[2]:────────────*───────────
                 |           
q[3]:────────────X───────────
                             

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──P(2.3562)───────
                       
q[2]:───────────────*──
                    |  
q[3]:───────────────X──
                       

julia> compare_circuits(circuit, transpiled_circuit)
true

```
"""
struct CompressRzGatesTranspiler <: Transpiler end

# construct a PhaseShift gate from an input Operator
function as_phase_shift_gate(target::Integer, op::AbstractOperator)::Gate{PhaseShift}
    @assert size(op) == (2, 2) ("Received multi-target Operator: $op")

    matrix = get_matrix(op)

    @assert matrix[1, 2] ≈ ComplexF64(0.0) (
        "Failed to build a PhaseShift gate from input Operator: $op"
    )
    @assert matrix[2, 1] ≈ ComplexF64(0.0) (
        "Failed to build a PhaseShift gate from input Operator: $op"
    )

    #find global phase offset angle
    alpha = atan(imag(matrix[1, 1]), real(matrix[1, 1]))

    #remove global offset
    matrix *= exp(-im * alpha)

    #find relative phase offset angle
    phi = atan(imag(matrix[2, 2]), real(matrix[2, 2]))

    return phase_shift(target, phi)
end

# compress (combine) several Rz-type gates with a common target to a PhaseShift gate
# Warning: does not assert gates having common target
function unsafe_compress_to_rz(gates::Vector{Gate}, target::Int)::Gate{PhaseShift}
    combined_op = eye()

    for gate in gates
        combined_op = get_operator(get_gate_symbol(gate)) * combined_op
    end

    return as_phase_shift_gate(target, combined_op)
end


function transpile(::CompressRzGatesTranspiler, circuit::QuantumCircuit)::QuantumCircuit

    if length(get_circuit_instructions(circuit)) == 1
        # no compression needed for individual gate
        return circuit
    end

    return find_and_compress_blocks(
        circuit,
        is_multi_target_or_not_rz,
        unsafe_compress_to_rz,
    )
end

"""
    RemoveSwapBySwappingGatesTranspiler

Transipler stage which removes the `Swap` gates from the `circuit` assuming all-to-all
connectivity.

!!! warning "The initial state must be the ground state!"
    This transpiler stage assumes that the input state is ``|0\\rangle^{\\otimes N}``,
    where ``N`` is the number of qubits. The stage should not be used on sub-circuits
    where the input state is not ``|0\\rangle^{\\otimes N}``.

This transpiler stage eliminates `Swap` gates by moving the gates preceding each `Swap`
gate.

# Examples
```jldoctest
julia> transpiler = RemoveSwapBySwappingGatesTranspiler();

julia> circuit = QuantumCircuit(
                    qubit_count = 2,
                    instructions = [hadamard(1), swap(1, 2), sigma_x(2)]
                )
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────☒───────
            |       
q[2]:───────☒────X──
                    



julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──────────
               
q[2]:──H────X──
               



```
"""
struct RemoveSwapBySwappingGatesTranspiler <: Transpiler end


function transpile(
    ::RemoveSwapBySwappingGatesTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit
    instructions = get_circuit_instructions(circuit)
    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output_circuit = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )
    qubit_mapping = Dict{Int,Int}()
    reverse_transpiled_instructions = Vector{Gate}([])

    for instr in reverse(instructions)
        if instr isa Snowflurry.Gate{Swap}
            update_qubit_mapping!(qubit_mapping, get_connected_qubits(instr))
        else
            moved_instr = move_instruction(instr, qubit_mapping)
            push!(reverse_transpiled_instructions, moved_instr)
        end
    end
    push!(output_circuit, reverse(reverse_transpiled_instructions)...)
    return output_circuit
end

function update_qubit_mapping!(qubit_mapping::Dict{Int,Int}, connected_qubits::Vector{Int})
    outlet_qubit_1 = 0
    outlet_qubit_2 = 0

    if haskey(qubit_mapping, connected_qubits[1])
        outlet_qubit_2 = qubit_mapping[connected_qubits[1]]
        pop!(qubit_mapping, connected_qubits[1])
    else
        outlet_qubit_2 = connected_qubits[1]
    end

    if haskey(qubit_mapping, connected_qubits[2])
        outlet_qubit_1 = qubit_mapping[connected_qubits[2]]
        pop!(qubit_mapping, connected_qubits[2])
    else
        outlet_qubit_1 = connected_qubits[2]
    end

    qubit_mapping[connected_qubits[1]] = outlet_qubit_1
    qubit_mapping[connected_qubits[2]] = outlet_qubit_2
end

"""
    SimplifyTrivialGatesTranspiler

Transpiler stage which removes gates that have no effect on the state `Ket` (e.g.
`Identity`) and parameterized gates with null parameters (e.g. `rotation_x(target, 0.)`).
The input and output circuits perform the same operation on an arbitrary state `Ket`
(up to a global phase). The tolerance used for `Base.isapprox()` in each case can be set by
passing an optional argument to the transpiler (e.g.
`transpiler=SimplifyTrivialGatesTranspiler(1.0e-10)`).

# Fields
- `atol::Real` -- Absolute tolerance for the comparison of rotation angles (default = 1e-6).

# Examples
```jldoctest
julia> transpiler = SimplifyTrivialGatesTranspiler();

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [identity_gate(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──I──
          
q[2]:─────
          
julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:
     
q[2]:      

julia> compare_circuits(circuit, transpiled_circuit)
true


julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [phase_shift(1, 0.)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──P(0.0000)──
                  
q[2]:─────────────
                  

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:
     
q[2]:      

julia> compare_circuits(circuit, transpiled_circuit)
true

julia> circuit = QuantumCircuit(qubit_count = 2, instructions = [universal(1, 0., 0., 0.)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──U(θ=0.0000,ϕ=0.0000,λ=0.0000)──
                                      
q[2]:─────────────────────────────────
                                             
julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:
     
q[2]:      

julia> compare_circuits(circuit, transpiled_circuit)
true

```
"""
struct SimplifyTrivialGatesTranspiler <: Transpiler
    atol::Real
end

SimplifyTrivialGatesTranspiler() = SimplifyTrivialGatesTranspiler(1e-6)

function is_trivial_gate(gate::Gate; atol = 1e-6)::Bool

    symbol = get_gate_symbol(gate)

    params = get_gate_parameters(symbol)

    if symbol isa Identity
        return true
    elseif symbol isa Universal
        if isapprox(params["theta"], 0.0; atol = atol) &&
           isapprox(params["phi"], 0.0; atol = atol) &&
           isapprox(params["lambda"], 0.0; atol = atol)
            return true
        end
    elseif symbol isa Rotation
        if isapprox(params["theta"], 0.0; atol = atol) &&
           isapprox(params["phi"], 0.0; atol = atol)
            return true
        end
    elseif symbol isa RotationX || symbol isa RotationY
        if isapprox(params["theta"], 0.0; atol = atol)
            return true
        end
    elseif symbol isa PhaseShift
        if isapprox(params["lambda"], 0.0; atol = atol)
            return true
        end
    end

    return false
end


function transpile(
    transpiler_stage::SimplifyTrivialGatesTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    atol = transpiler_stage.atol

    for instr in get_circuit_instructions(circuit)
        if (instr isa Readout) || ~is_trivial_gate(instr; atol = atol)
            push!(output, instr)
        end
    end

    return output
end

"""
    UnsupportedGatesTranspiler

Transpiler stage which throws a `NotImplementedError` if a `Controlled` gate that operates
on more than two qubits is found.

# Examples
```jldoctest
julia> transpiler = UnsupportedGatesTranspiler();

julia> circuit = QuantumCircuit(qubit_count=2, instructions = [control_z(1, 2)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──*──
       |  
q[2]:──Z──
          

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──*──
       |  
q[2]:──Z──
          

julia> invalid_circuit = QuantumCircuit(
               qubit_count = 4,
               instructions = [controlled(hadamard(2), [1, 3])],
           )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:──*──
       |  
q[2]:──H──
       |  
q[3]:──*──
          
q[4]:─────
          

julia> transpiled_circuit = transpile(transpiler, invalid_circuit)
ERROR: NotImplementedError{Gate{Controlled{Snowflurry.Hadamard}}}(:Transpiler, Gate Object: Controlled{Snowflurry.Hadamard}
[...]
```
"""
struct UnsupportedGatesTranspiler <: Transpiler end


function transpile(::UnsupportedGatesTranspiler, circuit::QuantumCircuit)::QuantumCircuit

    for instr in get_circuit_instructions(circuit)
        if !(instr isa Readout) && get_gate_symbol(instr) isa Controlled
            if length(get_connected_qubits(instr)) != 2
                throw(NotImplementedError(:Transpiler, instr))
            end
        end
    end

    return circuit
end

"""
    ReadoutsAreFinalInstructionsTranspiler

Transpiler stage which ensures that each `Readout` instruction is the last operation 
on each qubit where readouts are present. It also verifies that repeated readouts 
on the same qubit do not occur. An error is thrown if these verifications fail. 
This transpiler stage leaves the `QuantumCircuit` unchanged.

# Examples
```jldoctest
julia> transpiler = ReadoutsAreFinalInstructionsTranspiler();

julia> circuit = QuantumCircuit(qubit_count=2, instructions = [hadamard(1), readout(1,1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────✲──
               
q[2]:──────────
               

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────✲──
               
q[2]:──────────
               

julia> circuit = QuantumCircuit(
                    qubit_count=2,
                    instructions = [hadamard(1), readout(1,1), sigma_x(1)]
                )
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────✲────X──
                    
q[2]:───────────────
                    

julia> transpiled_circuit = transpile(transpiler, circuit)
ERROR: AssertionError: Cannot perform `Gate` following `Readout` on qubit: 1
[...]

julia> circuit = QuantumCircuit(qubit_count=2, instructions = [readout(1,1), readout(1,2)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──✲────✲──
               
q[2]:──────────
               

julia> transpiled_circuit = transpile(transpiler, circuit)
ERROR: AssertionError: Found multiple `Readouts` on qubit: 1
[...]
```
"""
struct ReadoutsAreFinalInstructionsTranspiler <: Transpiler end


function transpile(
    ::ReadoutsAreFinalInstructionsTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    assert_readouts_are_last_instr(circuit)

    return circuit
end

function assert_readouts_are_last_instr(circuit::QuantumCircuit)
    instructions = get_circuit_instructions(circuit)

    readouts_present_on_qubits = Set{Int}()

    for instr in instructions
        if typeof(instr) == Readout
            target_qubit = get_connected_qubits(instr)[1]

            #repeated readouts are not allowed
            @assert !(target_qubit in readouts_present_on_qubits) "Found multiple `Readouts` on qubit: $target_qubit"

            push!(readouts_present_on_qubits, target_qubit)

        else
            target_qubits = get_connected_qubits(instr)

            for target_qubit in target_qubits
                # Gates following readouts are not allowed
                @assert !(target_qubit in readouts_present_on_qubits) "Cannot perform `Gate` following `Readout` on qubit: $target_qubit"
            end
        end
    end

end

"""
    CircuitContainsAReadoutTranspiler

A transpiler stage which ensures that at least one `Readout` instruction is present in the
`QuantumCircuit`. Otherwise, an error is thrown. This transpiler stage leaves the
`QuantumCircuit` unchanged.

# Examples
```jldoctest
julia> transpiler = CircuitContainsAReadoutTranspiler();

julia> circuit = QuantumCircuit(qubit_count=2, instructions = [hadamard(1), readout(1,1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────✲──
               
q[2]:──────────
               

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────✲──
               
q[2]:──────────
               

julia> circuit = QuantumCircuit(qubit_count=2, instructions = [hadamard(1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H──
          
q[2]:─────
          

julia> transpiled_circuit = transpile(transpiler, circuit)
ERROR: ArgumentError: QuantumCircuit is missing a `Readout`. Would not return any result.
[...]
```
"""
struct CircuitContainsAReadoutTranspiler <: Transpiler end


function transpile(
    ::CircuitContainsAReadoutTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    for instr in get_circuit_instructions(circuit)
        if instr isa Readout
            return circuit
        end
    end

    throw(
        ArgumentError(
            "QuantumCircuit is missing a `Readout`. Would not return any result.",
        ),
    )
end

"""
    ReadoutsDoNotConflictTranspiler

Transpiler stage which ensures that each `Readout` instruction present in the
`QuantumCircuit` does not have conflicting destination bits, Otherwise, an error is thrown. 
This transpiler stage leaves the `QuantumCircuit` unchanged.

# Examples
```jldoctest
julia> transpiler = ReadoutsDoNotConflictTranspiler();

julia> circuit = QuantumCircuit(qubit_count=2, instructions = [hadamard(1), readout(1,1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────✲──
               
q[2]:──────────
               

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────✲──
               
q[2]:──────────
               

julia> circuit = QuantumCircuit(qubit_count=2, instructions = [readout(1,1), readout(2,1)])
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──✲───────
               
q[2]:───────✲──
               

julia> transpiled_circuit = transpile(transpiler, circuit)
ERROR: ArgumentError: `Readouts` in `QuantumCircuit` have conflicting destination bit: 1
[...]
```
"""
struct ReadoutsDoNotConflictTranspiler <: Transpiler end


function transpile(
    ::ReadoutsDoNotConflictTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    readout_destination_bits = Set{Int}()

    for instr in get_circuit_instructions(circuit)
        if instr isa Readout
            bit = get_destination_bit(instr)

            if bit in readout_destination_bits
                throw(
                    ArgumentError(
                        "`Readouts` in `QuantumCircuit` have conflicting destination bit: $bit",
                    ),
                )
            end
            push!(readout_destination_bits, bit)
        end
    end

    return circuit
end

"""
    DecomposeSingleTargetSingleControlGatesTranspiler

Transpiler stage which finds single-control, single-target `Controlled` gates in an input
circuit and casts them into a sequence of `RotationZ` (Rz), `ControlX`, `Universal` (U) and
`PhaseShift` (P) gates in a new, equivalent circuit.
For reference, see Nielsen and Chuang, "Quantum Computation and Quantum Information",
p. 180. The input and output circuits perform the same operation on an arbitrary state `Ket`
(up to a global phase).
!!! note
    If a global phase is applied by the kernel of the `Controlled` gate on the target 
    qubit, this decomposition preserves it.

For instance, `rotation_z(pi)` and `phase_shift(pi)` kernels will yield results with
a phase offset.
# Examples
```jldoctest
julia> transpiler = DecomposeSingleTargetSingleControlGatesTranspiler();

julia> circuit = QuantumCircuit(
                    qubit_count = 2,
                    instructions = [sigma_x(1), controlled(rotation_z(2, pi), [1])]
                )
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X────────*───────
                |       
q[2]:───────Rz(3.1416)──
                        
julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X───────────────────*──────────────────────────────────────*───────────────────────────────────
                           |                                      |                                   
q[2]:───────Rz(-1.5708)────X────U(θ=0.0000,ϕ=-1.5708,λ=0.0000)────X────U(θ=0.0000,ϕ=3.1416,λ=0.0000)──
                                                                                                      
julia> compare_circuits(circuit, transpiled_circuit)
true

julia> simulate(transpiled_circuit)
4-element Ket{ComplexF64}:
0.0 + 0.0im
-0.0 + 0.0im
0.7071067811865477 - 0.7071067811865474im
0.0 + 0.0im

julia> circuit = QuantumCircuit(
                    qubit_count = 2,
                    instructions = [sigma_x(1), controlled(phase_shift(2, pi), [1])]
                )
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X────────*──────
                |      
q[2]:───────P(3.1416)──
                       

julia> transpiled_circuit = transpile(transpiler, circuit)
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X───────────────────*──────────────────────────────────────*─────────────────────────────────────P(1.5708)──
                           |                                      |                                                
q[2]:───────Rz(-1.5708)────X────U(θ=0.0000,ϕ=-1.5708,λ=0.0000)────X────U(θ=0.0000,ϕ=3.1416,λ=0.0000)───────────────
                                                                                                                   

julia> compare_circuits(circuit,transpiled_circuit)
true

julia> simulate(circuit)
4-element Ket{ComplexF64}:
0.0 + 0.0im
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im

```
"""
struct DecomposeSingleTargetSingleControlGatesTranspiler <: Transpiler end


function transpile(
    ::DecomposeSingleTargetSingleControlGatesTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit
    qubit_count = get_num_qubits(circuit)
    bit_count = get_num_bits(circuit)
    output = QuantumCircuit(
        qubit_count = qubit_count,
        bit_count = bit_count,
        name = get_name(circuit),
    )

    for instr in get_circuit_instructions(circuit)
        if instr isa Readout
            push!(output, instr)
            continue
        end

        gate = get_gate_symbol(instr)
        if gate isa Controlled
            kernel = get_kernel(gate)

            connected_qubits = get_connected_qubits(instr)
            if length(connected_qubits) != 2
                # this transpiler stage only handles single-target single-control ControlledGates
                push!(output, instr)
                continue
            end

            control = connected_qubits[1]
            target = connected_qubits[2]

            # optimized transpilation stages are implemented for Controlled{SigmaX} and Controlled{SigmaX}
            if typeof(kernel) == SigmaZ
                push!(output, control_z(control, target))
                continue
            end

            if typeof(kernel) == SigmaX
                push!(output, control_x(control, target))
                continue
            end

            op = get_operator(kernel)

            # store existing global phase, which is cancelled by as_universal_gate()
            α_0 = get_canonical_global_phase(get_matrix(op))
            universal_equivalent = as_universal_gate(target, op)

            (α_d, A, B, C) = decompose_universal_to_A_B_C_gates(
                get_gate_symbol(universal_equivalent),
                target,
            )

            α = -α_0 + α_d

            push!(output, C, control_x(control, target), B, control_x(control, target), A)

            if abs(α) > sqrt(eps(typeof(α)))
                push!(output, phase_shift(control, -α))
            end
        else
            push!(output, instr)
        end
    end

    return output
end

"""
    RejectNonNativeInstructionsTranspiler

Transpiler stage which throws a `DomainError` if a non-native `Instruction` is found in the
`circuit`. The `circuit` remains unchanged if no error is thrown.

See [`is_native_instruction`](@ref) for additional information about native instructions.

# Fields
- connectivity::AbstractConnectivity -- Connectivity which specifies the connections on
                                        which two-qubit gates can be applied.
- native_gates::Vector{DataType} -- List of native gates. The gates that are native to the
                                    Anyon QPUs are used by default.

# Examples
```jldoctest
julia> connectivity = LineConnectivity(4)
LineConnectivity{4}
1──2──3──4


julia> default_transpiler = RejectNonNativeInstructionsTranspiler(connectivity);


julia> invalid_circuit = QuantumCircuit(
           qubit_count = 4,
           instructions = [sigma_x(4), control_z(1, 3)],
           )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:───────*──
            |  
q[2]:───────|──
            |  
q[3]:───────Z──
               
q[4]:──X───────
               

julia> transpile(default_transpiler, invalid_circuit)
ERROR: DomainError with LineConnectivity{4}
1──2──3──4
[...]


julia> valid_circuit = QuantumCircuit(
           qubit_count = 4,
           instructions = [sigma_x(4), control_z(1, 2)],
           )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:───────*──
            |  
q[2]:───────Z──
               
q[3]:──────────
               
q[4]:──X───────
               

julia> transpiled_circuit = transpile(default_transpiler, valid_circuit)
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:───────*──
            |  
q[2]:───────Z──
               
q[3]:──────────
               
q[4]:──X───────


julia> custom_circuit = QuantumCircuit(
                  qubit_count = 4,
                  instructions = [control_x(2, 3)],
                  )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:─────
          
q[2]:──*──
       |  
q[3]:──X──
          
q[4]:─────
          

julia> transpile(default_transpiler, custom_circuit)
ERROR: DomainError with LineConnectivity{4}
1──2──3──4
[...]


julia> custom_transpiler = RejectNonNativeInstructionsTranspiler(
            connectivity,
            [Snowflurry.ControlX]
        );


julia> transpiled_circuit = transpile(custom_transpiler, custom_circuit)
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:─────
          
q[2]:──*──
       |  
q[3]:──X──
          
q[4]:─────
          

```
"""
struct RejectNonNativeInstructionsTranspiler <: Transpiler
    connectivity::AbstractConnectivity
    native_gates::Vector{DataType}

    function RejectNonNativeInstructionsTranspiler(
        connectivity::GeometricConnectivity,
        native_gates::Vector{DataType} = set_of_native_gates,
    )

        return new(connectivity, native_gates)
    end

    function RejectNonNativeInstructionsTranspiler(
        connectivity::AbstractConnectivity,
        ::Vector{DataType} = set_of_native_gates,
    )

        throw(NotImplementedError(:RejectNonNativeInstructionsTranspiler, connectivity))
    end
end


function transpile(
    transpiler::RejectNonNativeInstructionsTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    (passed, message) =
        is_native_circuit(circuit, transpiler.connectivity, transpiler.native_gates)

    if !passed
        throw(DomainError(transpiler.connectivity, message))
    end

    return circuit
end

"""
   RejectGatesOnExcludedPositionsTranspiler

Transpiler stage which throws a `DomainError` if an `Instruction` in the `circuit` operates
on an excluded qubit. The excluded qubits are specified with the parameter
`excluded_positions` in certain `AbstractConnectivity` objects. The `circuit` remains
unchanged if no error is thrown.

# Fields
- connectivity::AbstractConnectivity -- Connectivity where the `excluded_positions` are
                                        specified.

# Examples
```jldoctest
julia> excluded_positions = [2];

julia> connectivity = LineConnectivity(4, excluded_positions)
LineConnectivity{4}
1──2──3──4
excluded positions: [2]


julia> transpiler = RejectGatesOnExcludedPositionsTranspiler(connectivity);

julia> invalid_circuit = QuantumCircuit(
               qubit_count = 4,
               instructions = [sigma_x(4), control_z(1, 2)],
           )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:───────*──
            |  
q[2]:───────Z──
               
q[3]:──────────
               
q[4]:──X───────
               



julia> transpile(transpiler, invalid_circuit)
ERROR: DomainError with LineConnectivity{4}
1──2──3──4
excluded positions: [2]
:
the Gate{Snowflurry.ControlZ} on qubits [1, 2] cannot be applied since qubit 2 is unavailable
[...]

julia> valid_circuit = QuantumCircuit(
               qubit_count = 4,
               instructions = [sigma_x(1), control_z(3, 4)],
           )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:──X───────
               
q[2]:──────────
               
q[3]:───────*──
            |  
q[4]:───────Z──
               



julia> transpiled_circuit = transpile(transpiler, valid_circuit)
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:──X───────
               
q[2]:──────────
               
q[3]:───────*──
            |  
q[4]:───────Z──
               



```
"""
struct RejectGatesOnExcludedPositionsTranspiler <: Transpiler
    connectivity::AbstractConnectivity
end


function transpile(
    transpiler::RejectGatesOnExcludedPositionsTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    (found_invalid_gates, message) =
        are_gates_at_excluded_positions(transpiler.connectivity, circuit)

    if found_invalid_gates
        throw(DomainError(transpiler.connectivity, message))
    end

    return circuit
end

function are_gates_at_excluded_positions(
    connectivity::AllToAllConnectivity,
    circuit::QuantumCircuit,
)::Tuple{Bool,String}

    return (false, "")
end

function are_gates_at_excluded_positions(
    connectivity::Union{LineConnectivity,LatticeConnectivity},
    circuit::QuantumCircuit,
)::Tuple{Bool,String}

    excluded_positions = get_excluded_positions(connectivity)
    for instruction in get_circuit_instructions(circuit)
        qubits = get_connected_qubits(instruction)
        for qubit in qubits
            if qubit in excluded_positions
                instruction_name = "$(typeof(instruction))"
                message =
                    "the $instruction_name on qubits $qubits cannot be applied " *
                    "since qubit $qubit is unavailable"
                return (true, message)
            end
        end
    end

    return (false, "")
end

"""
    RejectGatesOnExcludedConnectionsTranspiler

Transpiler stage which throws a `DomainError` if an `Instruction` in the `circuit` operates
on an excluded connection. The excluded connections are specified with the parameter
`excluded_connections` in certain `AbstractConnectivity` objects. The function returns the
same `circuit` if no error is thrown.

# Fields
- connectivity::AbstractConnectivity -- Connectivity where the `excluded_connections` are
                                        specified.

# Examples
```jldoctest
julia> excluded_positions = Int[];

julia> excluded_connections = [(2, 3)];

julia> connectivity = LineConnectivity(4, excluded_positions, excluded_connections)
LineConnectivity{4}
1──2──3──4
excluded connections: [(2, 3)]


julia> transpiler = RejectGatesOnExcludedConnectionsTranspiler(connectivity);

julia> invalid_circuit = QuantumCircuit(
                      qubit_count = 4,
                      instructions = [sigma_x(4), control_z(3, 2)],
                  )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:──────────
               
q[2]:───────Z──
            |  
q[3]:───────*──
               
q[4]:──X───────
               



julia> transpile(transpiler, invalid_circuit)
ERROR: DomainError with LineConnectivity{4}
1──2──3──4
excluded connections: [(2, 3)]
:
the Gate{Snowflurry.ControlZ} on qubits [3, 2] cannot be applied since connection (2, 3) is unavailable
[...]

julia> valid_circuit = QuantumCircuit(
                      qubit_count = 4,
                      instructions = [sigma_x(1), control_z(3, 4)],
                  )
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:──X───────
               
q[2]:──────────
               
q[3]:───────*──
            |  
q[4]:───────Z──
               



julia> transpiled_circuit = transpile(transpiler, valid_circuit)
Quantum Circuit Object:
   qubit_count: 4 
   bit_count: 4 
q[1]:──X───────
               
q[2]:──────────
               
q[3]:───────*──
            |  
q[4]:───────Z──
               


```
"""
struct RejectGatesOnExcludedConnectionsTranspiler <: Transpiler
    connectivity::AbstractConnectivity
end


function transpile(
    transpiler::RejectGatesOnExcludedConnectionsTranspiler,
    circuit::QuantumCircuit,
)::QuantumCircuit

    (found_invalid_gates, message) =
        are_gates_at_excluded_connections(transpiler.connectivity, circuit)

    if found_invalid_gates
        throw(DomainError(transpiler.connectivity, message))
    end

    return circuit
end

are_gates_at_excluded_connections(
    ::AllToAllConnectivity,
    ::QuantumCircuit,
)::Tuple{Bool,String} = (false, "")

function are_gates_at_excluded_connections(
    connectivity::Union{LineConnectivity,LatticeConnectivity},
    circuit::QuantumCircuit,
)::Tuple{Bool,String}

    excluded_connections = get_excluded_connections(connectivity)
    for instruction in get_circuit_instructions(circuit)
        qubits = get_connected_qubits(instruction)

        if length(qubits) == 2
            candidate_connection = Tuple{Int,Int}(sort(qubits))
            if candidate_connection ∈ excluded_connections
                instruction_name = "$(typeof(instruction))"
                message =
                    "the $instruction_name on qubits $qubits cannot be applied " *
                    "since connection $candidate_connection is unavailable"
                return (true, message)
            end
        elseif length(qubits) > 2
            throw(
                DomainError(
                    are_gates_at_excluded_connections,
                    "not implemented for gates with more than 2 qubits",
                ),
            )
        end
    end

    return (false, "")
end
