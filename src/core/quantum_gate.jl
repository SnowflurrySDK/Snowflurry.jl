"""
    AbstractGateSymbol

A `GateSymbol` is an instantiation of an `AbstractGateSymbol`, which, when used inside a `Gate` (specifing placement) can be added to a `QuantumCircuit` to apply an operator to one or more `target` qubits.
`AbstractGateSymbol` is useful to dispatch all `GateSymbols` to default implementation of functions such as get_connected_qubits(). 
Those functions are then specialized for `GateSymbols` requiring a different implementation. 

`AbstractGateSymbol` is an abstract type, which means that it cannot be instantiated. 
Instead, each concrete type of `GateSymbols` is a struct which is a subtype of `AbstractGateSymbol`.
Each descendant of `AbstractGateSymbol` must implement at least the following methods:

- `get_operator(gate::AbstractGateSymbol, T::Type{<:Complex}=ComplexF64})::AbstractOperator`
- `get_num_connected_qubits(gate::AbstractGateSymbol)::Integer`

# Examples
A struct must be defined for each new `GateSymbol` type, such as the following X_45 `GateSymbol` which
applies a 45° rotation about the X axis:

```jldoctest gate_struct
julia> struct X45 <: AbstractGateSymbol
       end;
```

We need to define how many connected qubits our new `GateSymbol` has.
```jldoctest gate_struct
julia> Snowflurry.get_num_connected_qubits(::X45) = 1

```

A `Gate` constructor must be defined as:
```jldoctest gate_struct
julia> x_45(target::Integer) = Gate(X45(), [target]);
```

along with an `Operator` constructor, with default precision `ComplexF64`, defined as:
```jldoctest gate_struct
julia> x_45(T::Type{<:Complex}=ComplexF64)=rotation_x(π/4, T);

```

To simulate the effect of the gate in a `QuantumCircuit` or when applied to a `Ket`,
the function `get_operator` must be extended.
```jldoctest gate_struct
julia> Snowflurry.get_operator(gate::X45, T::Type{<:Complex}=ComplexF64) = rotation_x(π/4, T);

```

The gate inverse can also be specified by extending the `inv` function.
```jldoctest gate_struct
julia> Base.inv(::X45) = Snowflurry.RotationX(-π/4);

```

An instance of the `X_45` `Gate` can now be created, along with its inverse:
```jldoctest gate_struct
julia> x_45_gate = x_45(1)
Gate Object: X45
Connected_qubits	: [1]
Operator:
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.9238795325112867 + 0.0im    0.0 - 0.3826834323650898im
0.0 - 0.3826834323650898im    0.9238795325112867 + 0.0im


julia> inv(x_45_gate)
Gate Object: Snowflurry.RotationX
Parameters: 
theta	: -0.7853981633974483

Connected_qubits	: [1]
Operator:
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.9238795325112867 + 0.0im    -0.0 + 0.3826834323650898im
-0.0 + 0.3826834323650898im    0.9238795325112867 + 0.0im


```

To enable printout of a `QuantumCircuit` containing our new `GateSymbol` type, a display symbol 
must be defined as follows.
```jldoctest gate_struct
julia> Snowflurry.gates_display_symbols[X45]=["X45"];

```

If this `Gate` is to be sent as an instruction to a hardware QPU, 
an instruction `String` must be defined.
```jldoctest gate_struct
julia> Snowflurry.gates_instruction_symbols[X45]="x45";

```

A circuit containing this `Gate` can now be constructed:
```jldoctest gate_struct
julia> circuit=QuantumCircuit(qubit_count=2,gates=[x_45_gate])
Quantum Circuit Object:
   qubit_count: 2
q[1]:──X45──

q[2]:───────

```

In addition, a `Controlled{X45}` gate can be constructed using:
```jldoctest gate_struct
julia> control=1; target=2;

julia> controlled(x_45(target),[control])
Gate Object: Controlled{X45}
Connected_qubits	: [1, 2]
Operator:
(4, 4)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.9238795325112867 + 0.0im    0.0 - 0.3826834323650898im
0.0 + 0.0im    0.0 + 0.0im    0.0 - 0.3826834323650898im    0.9238795325112867 + 0.0im

```


"""
abstract type AbstractGateSymbol end

abstract type AbstractControlledGateSymbol <: AbstractGateSymbol end

get_gate_parameters(gate::AbstractGateSymbol)=Dict{String,Real}()

# TODO(#293): Change default to throw not implemented
get_num_connected_qubits(gate::AbstractGateSymbol) = 1 # default value


"""
    Gate

An object that specifies an `AbstractGateSymbol` and its placement inside a `QuantumCircuit`. The placement is the same as the target qubits on which the gate operates.

# Examples
```jldoctest
julia> gate = iswap(1, 2)
Gate Object: Snowflurry.ISwap
Connected_qubits	: [1, 2]
Operator:
(4, 4)-element Snowflurry.SwapLikeOperator:
Underlying data ComplexF64:
Equivalent DenseOperator:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im
```


```jldoctest
julia> gate = universal(3, pi/2, -pi/2, pi/2)
Gate Object: Snowflurry.Universal
Parameters:
theta	: 1.5707963267948966
phi	: -1.5707963267948966
lambda	: 1.5707963267948966

Connected_qubits	: [3]
Operator:
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.7071067811865476 + 0.0im    -4.329780281177466e-17 - 0.7071067811865475im
4.329780281177466e-17 - 0.7071067811865475im    0.7071067811865476 + 0.0im
```
"""
struct Gate{SymbolType<:AbstractGateSymbol}
    symbol::SymbolType
    connected_qubits::Vector{Int}

    function Gate(symbol::SymbolType, connected_qubits::Vector{Int}) where SymbolType <: AbstractGateSymbol
        if length(connected_qubits) != get_num_connected_qubits(symbol)
            throw(DomainError(connected_qubits, "connected qubits must match the number of qubits of the symbol"))
        end

        if length(connected_qubits) != length(unique(connected_qubits))
            throw(DomainError(connected_qubits, "connected qubits qubits must be unique"))
        end

        return new{SymbolType}(symbol, connected_qubits)
    end
end

function Base.show(io::IO, gate::Gate)
    targets = get_connected_qubits(gate)

    parameters = get_gate_parameters(get_gate_symbol(gate))

    if isempty(parameters)
        show_gate(io, typeof(get_gate_symbol(gate)), targets, get_operator(get_gate_symbol(gate)))
    else
        show_gate(io, typeof(get_gate_symbol(gate)), targets, get_operator(get_gate_symbol(gate)), parameters)
    end
end

function get_gate_symbol(gate::Gate)::AbstractGateSymbol
    return gate.symbol
end

function get_connected_qubits(gate::Gate)::AbstractVector{Int}
    return gate.connected_qubits
end

function Base.inv(gate::Gate)::Gate
    return Gate(inv(get_gate_symbol(gate)), get_connected_qubits(gate))
end

function get_control_qubits(gate::Gate{<:AbstractControlledGateSymbol})
    connected_qubits = get_connected_qubits(gate)
    num_control_qubits = get_num_control_qubits(get_gate_symbol(gate))
    return Vector(view(connected_qubits, 1:num_control_qubits))
end

function get_target_qubits(gate::Gate{<:AbstractControlledGateSymbol})
    connected_qubits = get_connected_qubits(gate)
    num_control_qubits = get_num_control_qubits(get_gate_symbol(gate))
    return Vector(view(connected_qubits, (num_control_qubits+1):length(connected_qubits)))
end

"""
    Controlled{G<:AbstractGateSymbol}<:AbstractGateSymbol

The `Controlled` object allows the construction of a controlled `AbstractGateSymbol` using an `Operator` 
(the `kernel`) and the corresponding number of control qubits. A helper function, `controlled`
can be used to easily create both controlled `AbstractGateSymbol`s and controlled `Gate`s.
The `apply_gate` will call into the optimized routine, and if no such routine is present, it will fall-back
to casting the operator into the equivalent `DenseOperator` and applying the created operator.

# Examples

We can use the `controlled` function to create a controlled-Hadamard gate

```jldoctest controlled_hadamard
julia> controlled_hadamard=controlled(hadamard(2),[1])
Gate Object: Controlled{Snowflurry.Hadamard}
Connected_qubits	: [1, 2]
Operator:
(4, 4)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.7071067811865475 + 0.0im    0.7071067811865475 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.7071067811865475 + 0.0im    -0.7071067811865475 + 0.0im

```

It can then be used in a `QuantumCircuit` as any other `Gate`, and its display symbol is 
inherited from the display symbol of the single-target `Hadamard` `Gate`:

```jldoctest controlled_hadamard
julia> circuit=QuantumCircuit(qubit_count=2,gates=[controlled_hadamard])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──*──
       |  
q[2]:──H──
          
```

In general, a `Controlled` with an arbitraty number of targets and controls can be 
constructed. For instance, the following constructs the equivalent of a `Toffoli` `Gate`, 
but as a `ConnectedGate{SigmaX}`, with `control_qubits=[1,2]` and `target_qubit=[3]`:

```jldoctest 
julia> toffoli_as_controlled_gate=controlled(sigma_x(3),[1,2])
Gate Object: Controlled{Snowflurry.SigmaX}
Connected_qubits	: [1, 2, 3]
Operator:
(8, 8)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
```


"""
struct Controlled{GateType<:AbstractGateSymbol} <: AbstractControlledGateSymbol
    kernel::GateType
    num_control_qubits::Int

    function Controlled(
        kernel::AbstractGateSymbol,
        num_control_qubits::Int=1,
        )

        @assert !(kernel isa Controlled) "Recursive construction of Controlled{Controlled} is not allowed"

        new{typeof(kernel)}(kernel,num_control_qubits)
    end

end

controlled(symbol::AbstractGateSymbol, num_control_qubits::Int) = Controlled(symbol, num_control_qubits)

function controlled(gate::Gate, control_qubits::Vector{Int}) 
    symbol = get_gate_symbol(gate)
    controlled_symbol = controlled(symbol, length(control_qubits))

    target_qubits = get_connected_qubits(gate)
    connected_qubits = vcat(control_qubits, target_qubits)
    return Gate(controlled_symbol, connected_qubits)
end

function get_num_target_qubits(controlled_symbol::Controlled)::Int
    return get_num_connected_qubits(controlled_symbol.kernel)
end

function get_num_control_qubits(controlled_symbol::Controlled)::Int
    return controlled_symbol.num_control_qubits
end

function get_num_connected_qubits(controlled_symbol::Controlled)::Int
    return get_num_control_qubits(controlled_symbol) + get_num_target_qubits(controlled_symbol)
end

function get_operator(gate::Controlled, T::Type{<:Complex}=ComplexF64) 

    num_connected_qubits = get_num_connected_qubits(gate)
    num_kernel_qubits = get_num_target_qubits(gate)
    
    op=get_matrix(eye(2^num_connected_qubits))
    
    op[end-(2^num_kernel_qubits)+1:end,end-(2^num_kernel_qubits)+1:end]=
        get_matrix(get_operator(gate.kernel))

    return DenseOperator(convert(Matrix{T},op))
end

get_gate_parameters(gate::Controlled)=get_gate_parameters(gate.kernel)

"""
    move_gate(gate::Gate,
        qubit_mapping::AbstractDict{<:Integer,<:Integer})::AbstractGateSymbol

Returns a copy of `gate` where the qubits on which the `gate` acts have been updated based
on `qubit_mapping`.

The dictionary `qubit_mapping` contains key-value pairs describing how to update the target
qubits. The key indicates which target qubit to change while the associated value specifies
the new qubit.

# Examples
```jldoctest
julia> gate = sigma_x(1)
Gate Object: Snowflurry.SigmaX
Connected_qubits	: [1]
Operator:
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


julia> move_gate(gate, Dict(1=>2))
Gate Object: Snowflurry.SigmaX
Connected_qubits	: [2]
Operator:
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


```
"""
function move_gate(gate::Gate,
    qubit_mapping::AbstractDict{T,T}
    )::Gate where {T<:Integer}

    old_connected_qubits = get_connected_qubits(gate)
    new_connected_qubits = deepcopy(old_connected_qubits)

    for (i_qubit, old_qubit) in enumerate(old_connected_qubits)
        if haskey(qubit_mapping, old_qubit)
            new_connected_qubits[i_qubit] = qubit_mapping[old_qubit]
        end
    end

    return Gate(get_gate_symbol(gate), new_connected_qubits)
end

struct NotImplementedError{ArgsT} <: Exception
    name::Symbol
    args::ArgsT
end

"""
    apply_gate!(state::Ket, gate::Gate)

Update the `state` by applying a `gate` to it.

# Examples
```jldoctest
julia> ψ_0 = fock(0, 2)
2-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im


julia> apply_gate!(ψ_0, sigma_x(1))
2-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im

```
"""
function apply_gate!(state::Ket, gate::Gate)
    qubit_count = get_num_qubits(state)
    
    connected_qubits=get_connected_qubits(gate)

    if any(t -> t>qubit_count ,connected_qubits)
        throw(DomainError(connected_qubits,
            "Not enough qubits in the Ket for the targets in gate"))
    end

    type_in_ket=eltype(state.data)

    operator=get_operator(get_gate_symbol(gate),type_in_ket)

    apply_operator!(state,operator,connected_qubits)
end

function apply_gate!(state::Ket, gate::Gate{Controlled{T}}) where T<:AbstractGateSymbol
    qubit_count = get_num_qubits(state)
    
    connected_qubits=get_connected_qubits(gate)

    if any(t -> t>qubit_count ,connected_qubits)
        throw(DomainError(connected_qubits,
            "Not enough qubits in the Ket for the targets in gate"))
    end

    apply_controlled_gate_operator!(
        state,
        get_operator(get_gate_symbol(gate)),
        DenseOperator(get_operator(get_gate_symbol(gate).kernel)),
        connected_qubits)
end

# specialization of a Swap-like gates without using the gate's operator (it is hard-coded).
# `phase` argument adds a phase offset to swapped coefficients. 
# adapted from https://github.com/qulacs/qulacs, method SWAP_gate_parallel_unroll()
function apply_operator!(
    state::Ket,
    op::SwapLikeOperator,
    connected_qubits::Vector{<:Integer}
    )
    qubit_count = get_num_qubits(state)

    control_qubit=connected_qubits[1]
    target_qubit=connected_qubits[2]
    
    (target_qubit_index_0,
        target_qubit_index_1,
        mask_0,
        mask_1,
        low_mask, 
        mid_mask, 
        high_mask,
        loop_dim)=create_masks_dual_targets(qubit_count,control_qubit,target_qubit)

    mask = mask_0 + mask_1


    min_qubit_index = minimum([target_qubit_index_0, target_qubit_index_1])
    max_qubit_index = maximum([target_qubit_index_0, target_qubit_index_1])
    
    min_qubit_mask = UInt64(1) << min_qubit_index
    max_qubit_mask = UInt64(1) << (max_qubit_index - 1)
    low_mask = min_qubit_mask - 1
    mid_mask = (max_qubit_mask - 1) ⊻ low_mask # bitwise XOR
    high_mask = ~(max_qubit_mask - 1)

    
    min_qubit_index = minimum([target_qubit_index_0, target_qubit_index_1])
    max_qubit_index = maximum([target_qubit_index_0, target_qubit_index_1])
    
    min_qubit_mask = UInt64(1) << min_qubit_index
    max_qubit_mask = UInt64(1) << (max_qubit_index - 1)
    low_mask = min_qubit_mask - 1
    mid_mask = (max_qubit_mask - 1) ⊻ low_mask # bitwise XOR
    high_mask = ~(max_qubit_mask - 1)

    if (target_qubit_index_0 == 0 || target_qubit_index_1 == 0)
        for state_index in UnitRange{UInt64}(0,loop_dim-1)
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,mask_0)
            basis_index_1 = basis_index_0 ⊻ mask # bitwise XOR

            @inbounds temp = state.data[basis_index_0+1]
            @inbounds state.data[basis_index_0+1] = state.data[basis_index_1+1]*op.phase
            @inbounds state.data[basis_index_1+1] = temp*op.phase
        end
    else
        for state_index in StepRange{UInt64}(0,2,loop_dim-1)    
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,mask_0)
            basis_index_1 = basis_index_0 ⊻ mask # bitwise XOR

            @inbounds temp0 = state.data[basis_index_0+1]
            @inbounds temp1 = state.data[basis_index_0+2]
            @inbounds state.data[basis_index_0+1] = state.data[basis_index_1+1]*op.phase
            @inbounds state.data[basis_index_0+2] = state.data[basis_index_1+2]*op.phase
            @inbounds state.data[basis_index_1+1] = temp0*op.phase
            @inbounds state.data[basis_index_1+2] = temp1*op.phase
        end
    end

    return state
end

# optimized application of ControlX gate on state Ket.  
# adapted from https://github.com/qulacs/qulacs, method CNOT_gate_parallel_unroll()
function apply_control_x!(state::Ket,control_qubit::Int,target_qubit::Int)
    qubit_count = get_num_qubits(state)

    (target_qubit_index_0,
        target_qubit_index_1,
        mask_0,
        mask_1,
        low_mask, 
        mid_mask, 
        high_mask,
        loop_dim)=create_masks_dual_targets(qubit_count,control_qubit,target_qubit)

    control_qubit_index=target_qubit_index_0
    target_qubit_index =target_qubit_index_1

    control_mask=mask_0
    target_mask=mask_1

    if target_qubit_index == 0
        # swap neighboring two basis
        for state_index in UnitRange{UInt64}(0,loop_dim-1)
            basis_index = ((state_index & mid_mask) << 1) +
                ((state_index & high_mask) << 2) + control_mask
            @inbounds temp = state.data[basis_index+1]
            @inbounds state.data[basis_index+1] = state.data[basis_index+2]
            @inbounds state.data[basis_index+2] = temp
        end
    elseif (control_qubit_index == 0)
        # no neighboring swap
        for state_index in UnitRange{UInt64}(0,loop_dim-1)
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,control_mask)
            basis_index_1 = basis_index_0 + target_mask

            @inbounds temp = state.data[basis_index_0+1]
            @inbounds state.data[basis_index_0+1] = state.data[basis_index_1+1]
            @inbounds state.data[basis_index_1+1] = temp
        end
    else
        # a,a+1 is swapped to a^m, a^m+1, respectively
        for state_index in StepRange{UInt64}(0,2,loop_dim-1)
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,control_mask)
            basis_index_1 = basis_index_0 + target_mask

            @inbounds temp0 = state.data[basis_index_0+1]
            @inbounds temp1 = state.data[basis_index_0+2]
            @inbounds state.data[basis_index_0+1] = state.data[basis_index_1+1]
            @inbounds state.data[basis_index_0+2] = state.data[basis_index_1+2]
            @inbounds state.data[basis_index_1+1] = temp0
            @inbounds state.data[basis_index_1+2] = temp1
        end
    end

    return state
end

# optimized application of ControlZ gate on state Ket.  
# adapted from https://github.com/qulacs/qulacs, method CZ_gate_parallel_unroll()
function apply_control_z!(state::Ket,control_qubit::Int,target_qubit::Int)
    qubit_count = get_num_qubits(state)

    (target_qubit_index_0,
        target_qubit_index_1,
        mask_0,
        mask_1,
        low_mask, 
        mid_mask, 
        high_mask,
        loop_dim)=create_masks_dual_targets(qubit_count,control_qubit,target_qubit)

    control_qubit_index=target_qubit_index_0

    control_mask=mask_0
    target_mask=mask_1

    if target_qubit_index_1 == 0 || control_qubit_index == 0
        for state_index in UnitRange{UInt64}(0,loop_dim-1)
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,control_mask)
            basis_index = basis_index_0+target_mask

            @inbounds state.data[basis_index+1] *= -1
        end
    else
        for state_index in StepRange{UInt64}(0,2,loop_dim-1)
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,control_mask)
            basis_index = basis_index_0+target_mask

            @inbounds state.data[basis_index+1] *= -1
            @inbounds state.data[basis_index+2] *= -1
        end
    end

    return state
end

# optimized application of Toffoli gate on state Ket.  
# adapted from https://github.com/qulacs/qulacs, 
# method multi_qubit_control_single_qubit_dense_matrix_gate_unroll()
function apply_toffoli!(state::Ket,control_qubits::Vector{Int},target_qubit::Int)
    qubit_count = get_num_qubits(state)

    dim=UInt64(2^qubit_count)

    @assert length(control_qubits)==2 ("Received $(length(control_qubits)) control qubits instead of 2.")

    # the bitwise implementation assumes target numbering starting at 0,
    # with first qubit on the rightmost side
    target_qubit_index=UInt64(qubit_count-target_qubit)
    
    control_qubit_index_list=Vector{UInt64}([qubit_count-t for t in reverse(control_qubits)])
    control_qubit_index_count=UInt64(2)
    
    sort_array=Vector{UInt64}(undef, control_qubit_index_count+1)
    mask_array=Vector{UInt64}(undef, control_qubit_index_count+1)

    create_shift_mask_list_from_list_and_value_buf!(
        control_qubit_index_list,
        control_qubit_index_count, 
        target_qubit_index, 
        sort_array,
        mask_array
    )

    target_mask = (UInt64(1) << target_qubit_index)

    control_mask=create_control_mask(
        control_qubit_index_list::Vector{UInt64}, 
        control_qubit_index_count::UInt64)

    insert_index_list_count = control_qubit_index_count + 1
    loop_dim = dim >> insert_index_list_count

    if target_qubit_index == 0
        for state_index in UnitRange{UInt64}(UInt64(0),loop_dim-1)
            basis_0 = state_index
            for cursor in 1:Int(insert_index_list_count)
                basis_0 = (basis_0 & mask_array[cursor]) +
                          ((basis_0 & (~mask_array[cursor])) << 1)
            end
            basis_0 += control_mask;

            @inbounds temp = state.data[basis_0+1]
            @inbounds state.data[basis_0+1] = state.data[basis_0+2]
            @inbounds state.data[basis_0+2] = temp
        end

    elseif (sort_array[1] == 0)
        for state_index in UnitRange{UInt64}(UInt64(0),loop_dim-1)
            basis_0 = state_index
            for cursor in 1:Int(insert_index_list_count)
                basis_0 = (basis_0 & mask_array[cursor]) +
                          ((basis_0 & (~mask_array[cursor])) << 1)
            end
            basis_0 += control_mask
            basis_1 = basis_0 + target_mask

            @inbounds temp = state.data[basis_0+1]
            @inbounds state.data[basis_0+1] = state.data[basis_1+1]
            @inbounds state.data[basis_1+1] = temp
        end

    else
        for state_index in StepRange{UInt64}(0,2,loop_dim-1)
            # create base index
            basis_0 = state_index
            for cursor in 1:Int(insert_index_list_count)
                basis_0 = (basis_0 & mask_array[cursor]) +
                          ((basis_0 & (~mask_array[cursor])) << 1)
            end
            basis_0 += control_mask
            basis_1 = basis_0 + target_mask
            
            @inbounds temp0 = state.data[basis_0+1]
            @inbounds temp1 = state.data[basis_0+2]
            @inbounds state.data[basis_0+1] = state.data[basis_1+1]
            @inbounds state.data[basis_0+2] = state.data[basis_1+2]
            @inbounds state.data[basis_1+1] = temp0
            @inbounds state.data[basis_1+2] = temp1        
        end
    end

    return state
end

# specialization for single-target single-control dense gate
# adapted from https://github.com/qulacs/qulacs, method single_qubit_control_single_qubit_dense_matrix_gate_unroll()
function apply_controlled_gate_operator!(
    state::Ket,
    full_operator::DenseOperator{4},
    kernel::DenseOperator{2},
    connected_qubits::Vector{Int}
    )

    @assert length(connected_qubits)==2 ("Received too many connected_qubits for"
        *" this operator: exected 2, got $(length(connected_qubits))")

    control_qubit=connected_qubits[1]
    target_qubit=connected_qubits[2]
    
    qubit_count = get_num_qubits(state)

    (target_qubit_index_0,
        target_qubit_index_1,
        mask_0,
        mask_1,
        low_mask, 
        mid_mask, 
        high_mask,
        loop_dim)=create_masks_dual_targets(qubit_count,control_qubit,target_qubit)

    control_qubit_index=target_qubit_index_0
    target_qubit_index =target_qubit_index_1

    control_mask=mask_0
    target_mask=mask_1

    matrix=kernel.data

    if (target_qubit_index == 0)
        for state_index in UnitRange{UInt64}(0,loop_dim-1)
            basis_index=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,control_mask)

            # fetch values
            @inbounds cval0 = state.data[basis_index+1]
            @inbounds cval1 = state.data[basis_index+2]

            # set values
            @inbounds state.data[basis_index+1] = matrix[1] * cval0 + matrix[3] * cval1
            @inbounds state.data[basis_index+2] = matrix[2] * cval0 + matrix[4] * cval1
        end
    
    elseif (control_qubit_index == 0) 
        for state_index in UnitRange{UInt64}(0,loop_dim-1)
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,control_mask)
            basis_index_1 = basis_index_0 + target_mask

            # fetch values
            @inbounds cval0 = state.data[basis_index_0+1]
            @inbounds cval1 = state.data[basis_index_1+1]

            # set values
            @inbounds state.data[basis_index_0+1] = matrix[1] * cval0 + matrix[3] * cval1
            @inbounds state.data[basis_index_1+1] = matrix[2] * cval0 + matrix[4] * cval1
        end

    else
        for state_index in StepRange{UInt64}(0,2,loop_dim-1)
            basis_index_0=get_basis_index_0(state_index,low_mask,mid_mask,high_mask,control_mask)
            basis_index_1 = basis_index_0 + target_mask

            # fetch values
            @inbounds cval0 = state.data[basis_index_0+1]
            @inbounds cval1 = state.data[basis_index_1+1]
            @inbounds cval2 = state.data[basis_index_0+2]
            @inbounds cval3 = state.data[basis_index_1+2]

            # set values
            @inbounds state.data[basis_index_0+1] = matrix[1] * cval0 + matrix[3] * cval1
            @inbounds state.data[basis_index_1+1] = matrix[2] * cval0 + matrix[4] * cval1
            @inbounds state.data[basis_index_0+2] = matrix[1] * cval2 + matrix[3] * cval3
            @inbounds state.data[basis_index_1+2] = matrix[2] * cval2 + matrix[4] * cval3
        end
    end

    return state
end

# fall-back to apply_operator! using the equivalent dense full_operator
apply_controlled_gate_operator!(
    state::Ket,
    full_operator::DenseOperator,
    kernel::DenseOperator,
    connected_qubits::Vector{Int}
    ) = apply_operator!(state,full_operator,connected_qubits)

apply_controlled_gate_operator!(
    state::Ket,
    full_operator::DenseOperator,
    kernel::AbstractOperator,
    connected_qubits::Vector{Int}
    ) = throw(NotImplementedError(:apply_controlled_gate_operator!,kernel))

# specialization for single target dense gate (size N=2, for N=2^target_count)
# adapted from https://github.com/qulacs/qulacs, method single_qubit_dense_matrix_gate_parallel_unroll()
function apply_operator!(
    state::Ket,
    operator::DenseOperator{2},
    connected_qubit::Vector{<:Integer})

    qubit_count = get_num_qubits(state)

    dim=2^qubit_count

    # the bitwise implementation assumes target numbering starting at 0,
    # with first qubit on the rightmost side
    target_qubit_index=qubit_count-connected_qubit[1] 
    
    loop_dim = div(dim,2);
    mask = (UInt64(1) << target_qubit_index);
    mask_low = mask - 1;
    mask_high = ~mask_low;
    
    matrix=operator.data

    for state_index in UnitRange{UInt64}(0,loop_dim-1)
        basis_0 =(state_index & mask_low) + ((state_index & mask_high) << 1)
        basis_1 = basis_0 + mask

        # fetch values
        @inbounds cval_0 = state.data[basis_0+1];
        @inbounds cval_1 = state.data[basis_1+1];

        @inbounds state.data[basis_0+1] = matrix[1] * cval_0 + matrix[3] * cval_1;
        @inbounds state.data[basis_1+1] = matrix[2] * cval_0 + matrix[4] * cval_1;
    end

    return state
end

function apply_operator!(
    state::Ket,
    operator::SparseOperator,
    connected_qubit::Vector{<:Integer})
    @warn "apply_operator! is not implemented for SparseOperator. Try using DenseOperator instead."
end

# specialization for multiple target dense gate (size N>=4, for N=2^target_count)
# adapted from https://github.com/qulacs/qulacs, method multi_qubit_dense_matrix_gate_parallel()
function apply_operator!(
    state::Ket,
    operator::DenseOperator{N},
    connected_qubits::Vector{<:Integer}) where N 

    qubit_count = get_num_qubits(state)

    dim=2^qubit_count
    
    type_in_ket=eltype(state.data)

    # the bitwise implementation assumes target numbering starting at 0,
    # with first qubit on the rightmost side
    target_qubit_index_list=Vector{UInt64}([qubit_count-t for t in reverse(connected_qubits)])
    target_qubit_index_count=UInt64(length(connected_qubits))
    
    sort_array=Vector{UInt64}(undef, target_qubit_index_count)
    mask_array=Vector{UInt64}(undef, target_qubit_index_count)

    create_shift_mask_list_from_list_buf!(target_qubit_index_list, sort_array, mask_array);

    # matrix dim, mask, buffer
    matrix_dim = UInt64(1) << target_qubit_index_count;
    matrix_mask_list=create_matrix_mask_list( 
        target_qubit_index_list, 
        target_qubit_index_count,
        matrix_dim
        )

    # loop variables
    loop_dim = dim >> target_qubit_index_count;

    buffer_list = Vector{type_in_ket}(undef,matrix_dim)
    
    start_index =0
    end_index =loop_dim;

    matrix=operator.data

    for state_index in start_index:(end_index-1)
       # create base index
       basis_0 = UInt64(state_index);

        for cursor in 0:(target_qubit_index_count-1)
            basis_0=(basis_0 & mask_array[cursor+1]) +
             ((basis_0 & (~mask_array[cursor+1])) << 1)
        end

        # compute matrix-vector multiply
        for y in 0:(matrix_dim-1)
            @inbounds buffer_list[y+1] = 0
            for x in 0:matrix_dim-1
                @inbounds buffer_list[y+1] += matrix[Int(x * matrix_dim + y +1)] *
                 state.data[Int(basis_0 ⊻ matrix_mask_list[x+1] +1)]
            end
        end

        # set result
        for y in  0:(matrix_dim-1)
            @inbounds state.data[Int(basis_0 ⊻ matrix_mask_list[y+1]+1)] = buffer_list[y+1];
        end

    end

    return state
end


# specialization for single target diagonal gate (size N=2, for N=2^target_count)
# adapted from https://github.com/qulacs/qulacs, method single_qubit_diagonal_matrix_gate_parallel_unroll()
function apply_operator!(
    state::Ket,
    operator::DiagonalOperator{2},
    connected_qubit::Vector{<:Integer})

    qubit_count = get_num_qubits(state)

    dim=2^qubit_count

    # the bitwise implementation assumes target numbering starting at 0,
    # with first qubit on the rightmost side
    target_qubit_index=qubit_count-connected_qubit[1] 
    
    diagonal_in_matrix=operator.data

    if target_qubit_index==0
        for state_index in StepRange(0,2,dim-1)
            @inbounds state.data[state_index+1] *= diagonal_in_matrix[1];
            @inbounds state.data[state_index+2] *= diagonal_in_matrix[2];
        end 
    else
        mask = UInt64(1) << target_qubit_index;
        for state_index in StepRange(0,2,dim-1)
            bitval = UInt64((state_index & mask) != 0)
            @inbounds state.data[state_index + 1] *= diagonal_in_matrix[bitval+1];
            @inbounds state.data[state_index + 2] *= diagonal_in_matrix[bitval+1];
        end
    end

    return state
end

#specialization for N target diagonal gates (size N>2, for N=2^target_count)
# adapted from https://github.com/qulacs/qulacs, method multi_qubit_diagonal_matrix_gate
function apply_operator!(
    state::Ket,
    operator::DiagonalOperator{N},
    connected_qubits::Vector{<:Integer}) where {N} 

    qubit_count = get_num_qubits(state)

    dim=2^qubit_count
    
    # the bitwise implementation assumes target numbering starting at 0,
    # with first qubit on the rightmost side
    target_qubit_index_list=Vector{UInt64}([qubit_count-t for t in reverse(connected_qubits)])
    target_qubit_index_count=UInt64(log2(N))
    
    diagonal_in_matrix=operator.data
    
    matrix_dim = UInt64(1) << target_qubit_index_count

    matrix_mask_list=create_matrix_mask_list(
        target_qubit_index_list, 
        target_qubit_index_count,
        matrix_dim
    )

    sorted_targets=Vector{UInt64}(undef, target_qubit_index_count)
    mask_array=Vector{UInt64}(undef, target_qubit_index_count)

    create_shift_mask_list_from_list_buf!(target_qubit_index_list, sorted_targets, mask_array)
        
    # loop variables
    loop_dim = dim >> target_qubit_index_count

    for state_index in 0:(loop_dim-1)
        # create base index
        basis_0 = UInt64(state_index);
        for cursor in UnitRange{UInt64}(UInt64(0),target_qubit_index_count-1)
            insert_index = sorted_targets[cursor+1]
            basis_0=insert_zero_to_basis_index(basis_0, UInt64(1) << insert_index, insert_index)
        end

        # compute matrix-vector multiply
        for y in 0:(matrix_dim-1)
            @inbounds state.data[(basis_0 ⊻ matrix_mask_list[y+1])+1] *= diagonal_in_matrix[y+1];
        end

    end

    return state
end

# specialization for single target anti-diagonal gate (size N=2^target_count=2)
# adapted from https://github.com/qulacs/qulacs, method Y_gate_parallel_unroll
function apply_operator!(
    state::Ket,
    operator::AntiDiagonalOperator{2},
    connected_qubit::Vector{<:Integer})

    qubit_count = get_num_qubits(state)

    dim=2^qubit_count

    # the bitwise implementation assumes target numbering starting at 0,
    # with first qubit on the rightmost side
    target_qubit_index=qubit_count-connected_qubit[1]
    
    anti_diagonal=operator.data

    loop_dim = div(dim, 2);
    mask = (UInt64(1) << target_qubit_index);
    mask_low = mask - 1;
    mask_high = ~mask_low;
    
    if target_qubit_index==0 # (qubit_count-1)
        for basis_index in StepRange(0,2,dim-2)
            @inbounds temp = state.data[basis_index+1]
            @inbounds state.data[basis_index+1] = anti_diagonal[1]*state.data[basis_index + 2]
            @inbounds state.data[basis_index+2] = anti_diagonal[2]*temp
        end
    else
        for state_index in StepRange{UInt64}(0,2,loop_dim-1)
            basis_index_0 =(state_index & mask_low) + ((state_index & mask_high) << 1)
            basis_index_1 = basis_index_0 + mask

            @inbounds temp0 = state.data[basis_index_0+1];
            @inbounds temp1 = state.data[basis_index_0 + 2];
            @inbounds state.data[basis_index_0+1] = anti_diagonal[1]*state.data[basis_index_1+1];
            @inbounds state.data[basis_index_0+2] = anti_diagonal[1]*state.data[basis_index_1 + 2];
            @inbounds state.data[basis_index_1+1] = anti_diagonal[2]*temp0;
            @inbounds state.data[basis_index_1+2] = anti_diagonal[2]*temp1;
        end
    end

    return state
end

# IdentityOperator leaves the state Ket unchanged
apply_operator!(state::Ket,op::IdentityOperator,connected_qubits::Vector{<:Integer})=state

# Insert 0 to qubit_index-th bit of basis_index. basis_mask must be 1 << qubit_index.
function insert_zero_to_basis_index(basis_index::UInt64, basis_mask::UInt64, qubit_index::UInt64)
    temp_basis = (basis_index >> qubit_index) << (qubit_index + 1)
    return temp_basis + basis_index % basis_mask
end

function create_matrix_mask_list(qubit_index_list::Vector{UInt64},qubit_index_count::UInt64,matrix_dim::UInt64)
    mask_list=zeros(UInt64,matrix_dim)

    for cursor in 0:(matrix_dim-1)
        for bit_cursor in 0:(qubit_index_count-1)
            if Bool((cursor >> bit_cursor) % 2)
                bit_index = qubit_index_list[bit_cursor+1]
                mask_list[cursor+1] ⊻= (UInt64(1) << bit_index) # ⊻ is binary XOR
            end
        end
    end

    return mask_list
end

function create_shift_mask_list_from_list_buf!(
    target_qubit_index_list::Vector{UInt64},
    dst_array::Vector{UInt64},
    dst_mask::Vector{UInt64}
    )
    #copy using mutation, not assignment, so dst_array still points to array in caller's scope
    for (i,target) in enumerate(target_qubit_index_list)
        dst_array[i]=target 
    end

    #sort the copy, so the initial array can be used in the original order
    sort!(dst_array)

    for (i,target) in enumerate(dst_array)
        dst_mask[i]=(1<<target)-1 
    end

end

function create_shift_mask_list_from_list_and_value_buf!(
    control_qubit_index_list::Vector{UInt64},
    control_qubit_index_count::UInt64, 
    target_qubit::UInt64, 
    dst_array::Vector{UInt64},
    dst_mask::Vector{UInt64}
    )

    #copy using mutation, not assignment, so dst_array still points to array in caller's scope
    for (i,control) in enumerate(control_qubit_index_list)
        dst_array[i]=control 
    end

    dst_array[control_qubit_index_count+1] = target_qubit

    #sort the copy, so the initial array can be used in the original order
    sort!(dst_array)

    for (i,target) in enumerate(dst_array)
        dst_mask[i]=(UInt64(1)<<target)-1 
    end
end

# adapted from https://github.com/qulacs/qulacs, method create_control_mask()
# unlike the qulacs implementation, Snowflurry always assumes the 
# control must be in state 1 to trigger the operator
function create_control_mask(
    qubit_index_list::Vector{UInt64}, 
    size::UInt64)

    mask = UInt64(0)
    
    for cursor in 1:size
        mask⊻=(UInt64(1) << qubit_index_list[cursor])
    end

    return mask;
end

function create_masks_dual_targets(qubit_count::Int,control_qubit::Int,target_qubit::Int)
    dim=2^qubit_count
    loop_dim = div(dim,4)

    # the bitwise implementation assumes target numbering starting at 0,
    # with first qubit on the rightmost side
    target_qubit_index_1=qubit_count-target_qubit 
    target_qubit_index_0=qubit_count-control_qubit 

    mask_0 = UInt64(1) << target_qubit_index_0
    mask_1 = UInt64(1) << target_qubit_index_1

    min_qubit_index = minimum([target_qubit_index_0, target_qubit_index_1])
    max_qubit_index = maximum([target_qubit_index_0, target_qubit_index_1])

    min_qubit_mask = UInt64(1) << min_qubit_index
    max_qubit_mask = UInt64(1) << (max_qubit_index - 1)

    low_mask = min_qubit_mask - 1
    mid_mask = (max_qubit_mask - 1) ⊻ low_mask # bitwise XOR
    high_mask = ~(max_qubit_mask - 1)

    return (target_qubit_index_0,
        target_qubit_index_1,
        mask_0,
        mask_1,
        low_mask, 
        mid_mask, 
        high_mask,
        loop_dim)
end

function get_basis_index_0(state_index::UInt64,low_mask::UInt64,mid_mask::UInt64,high_mask::UInt64,mask_0::UInt64)::UInt64
    return (state_index & low_mask) + 
        ((state_index & mid_mask) << 1) +
        ((state_index & high_mask) << 2) + mask_0
end

# Single Qubit Gates
"""
    sigma_x()

Return the Pauli-X `AntiDiagonalOperator`, which is defined as:
```math
\\sigma_x = \\begin{bmatrix}
    0 & 1 \\\\
    1 & 0
    \\end{bmatrix}.
```
"""
sigma_x(T::Type{<:Complex}=ComplexF64)=AntiDiagonalOperator(T[1.0, 1.0])

"""
    sigma_y()

Return the Pauli-Y `Operator`, which is defined as:
```math
\\sigma_y = \\begin{bmatrix}
    0 & -i \\\\
    i & 0
    \\end{bmatrix}.
```
"""
sigma_y(T::Type{<:Complex}=ComplexF64)=AntiDiagonalOperator(T[-im, im])

"""
    sigma_z()

Return the Pauli-Z `Operator`, which is defined as:
```math
\\sigma_z = \\begin{bmatrix}
    1 & 0 \\\\
    0 & -1
    \\end{bmatrix}.
```
"""
sigma_z(T::Type{<:Complex}=ComplexF64) = DiagonalOperator(T[1.0, -1.0])

"""
    sigma_p()

Return the spin-\$\\frac{1}{2}\$ raising `Operator`, which is defined as:
```math
\\sigma_+ = \\begin{bmatrix}
    0 & 1 \\\\
    0 & 0
    \\end{bmatrix}.
```
"""
sigma_p(T::Type{<:Complex}=ComplexF64) = T(0.5)*(sigma_x(T)+im*sigma_y(T))

"""
    sigma_m()

Return the spin-\$\\frac{1}{2}\$ lowering `Operator`, which is defined as:
```math
\\sigma_- = \\begin{bmatrix}
    0 & 0 \\\\
    1 & 0
    \\end{bmatrix}.
```
"""
sigma_m(T::Type{<:Complex}=ComplexF64) = T(0.5)*(sigma_x(T)-im*sigma_y(T))

"""
    hadamard()

Return the Hadamard `Operator`, which is defined as:
```math
H = \\frac{1}{\\sqrt{2}}\\begin{bmatrix}
    1 & 1 \\\\
    1 & -1
    \\end{bmatrix}.
```
"""
hadamard(T::Type{<:Complex}=ComplexF64) = DenseOperator(T(1.0 / sqrt(2.0)) * T[[1.0, 1.0] [1.0, -1.0]])

"""
    pi_8()

Return the `Operator` for the π/8 gate, which is defined as:
```math
T = \\begin{bmatrix}
    1 & 0 \\\\
    0 & e^{i\\frac{\\pi}{4}}
    \\end{bmatrix}.
```
"""
pi_8(T::Type{<:Complex}=ComplexF64) = DiagonalOperator(T[1.,exp(im*pi/4.0)])

"""
    pi_8_dagger()

Return the adjoint `DiagonalOperator` of the π/8 gate, which is defined as:
```math
T^\\dagger = \\begin{bmatrix}
    1 & 0 \\\\
    0 & e^{-i\\frac{\\pi}{4}}
    \\end{bmatrix}.
```
"""
pi_8_dagger(T::Type{<:Complex}=ComplexF64) = DiagonalOperator(T[1.0, exp(-im*pi/4.0)])

"""
    eye(),
    eye(size::Integer)

Return the identity matrix as a `DenseOperator`, which is defined as:
```math
I = \\begin{bmatrix}
    1 & 0 \\\\
    0 & 1
    \\end{bmatrix}.
```

Calling eye(size) will produce an identity matrix `DenseOperator` 
of dimensions (size,size).

# Examples
```jldoctest
julia> eye()
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im

julia> eye(4)
(4, 4)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im

```

"""
eye(T::Type{<:Complex}=ComplexF64) = DenseOperator(Matrix{T}(1.0I, 2, 2))
eye(size::Integer, T::Type{<:Complex}=ComplexF64) = DenseOperator(Matrix{T}(1.0I, size, size))



"""
    x_90()

Return the `Operator` which applies a π/2 rotation about the X axis.

The `Operator` is defined as:
```math
R_x\\left(\\frac{\\pi}{2}\\right) = \\frac{1}{\\sqrt{2}}\\begin{bmatrix}
    1 & -i \\\\
    -i & 1
    \\end{bmatrix}.
```
"""
x_90(T::Type{<:Complex}=ComplexF64) = rotation(pi/2, 0,T)

"""
    x_minus_90()

Return the `Operator` which applies a -π/2 rotation about the X axis.

The `Operator` is defined as:
```math
R_x\\left(-\\frac{\\pi}{2}\\right) = \\frac{1}{\\sqrt{2}}\\begin{bmatrix}
    1 & i \\\\
    i & 1
    \\end{bmatrix}.
```
"""
x_minus_90(T::Type{<:Complex}=ComplexF64) = rotation(-pi/2, 0,T)

"""
    y_90()

Return the `Operator` which applies a π/2 rotation about the Y axis.

The `Operator` is defined as:
```math
R_y\\left(\\frac{\\pi}{2}\\right) = \\frac{1}{\\sqrt{2}}\\begin{bmatrix}
    1 & -1 \\\\
    1 & 1
    \\end{bmatrix}.
```
"""
y_90(T::Type{<:Complex}=ComplexF64) = rotation(pi/2, pi/2,T)

"""
    y_minus_90()

Return the `Operator` which applies a -π/2 rotation about the Y axis.

The `Operator` is defined as:
```math
R_y\\left(-\\frac{\\pi}{2}\\right) = \\frac{1}{\\sqrt{2}}\\begin{bmatrix}
    1 & 1 \\\\
    -1 & 1
    \\end{bmatrix}.
```
"""
y_minus_90(T::Type{<:Complex}=ComplexF64) = rotation(-pi/2, pi/2,T)

"""
    z_90()

Return the `Operator` which applies a π/2 rotation about the Z axis.

The `Operator` is defined as:
```math
R_z\\left(\\frac{\\pi}{2}\\right) = \\begin{bmatrix}
    1 & 0 \\\\
    0 & i
    \\end{bmatrix}.
```
"""
z_90(T::Type{<:Complex}=ComplexF64) = phase_shift(pi/2, T)

"""
    z_minus_90()

Return the `Operator` which applies a -π/2 rotation about the Z axis.

The `Operator` is defined as:
```math
R_z\\left(-\\frac{\\pi}{2}\\right) = \\begin{bmatrix}
    1 & 0 \\\\
    0 & -i
    \\end{bmatrix}.
```
"""
z_minus_90(T::Type{<:Complex}=ComplexF64) = phase_shift(-pi/2, T)

"""
    rotation(theta, phi)

Return the `Operator` which applies a rotation `theta` about the cos(`phi`)X+sin(`phi`)Y axis.

The `Operator` is defined as:
```math
R(\\theta, \\phi) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -i e^{-i\\phi} \\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    -i e^{i\\phi} \\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
"""
rotation(theta::Real, phi::Real,T::Type{<:Complex}=ComplexF64) = DenseOperator(
    T[cos(theta/2) -im*exp(-im*phi)*sin(theta/2);
     -im*exp(im*phi)*sin(theta/2) cos(theta/2)]
)

"""
    rotation_x(theta)

Return the `Operator` which applies a rotation `theta` about the X axis.

The `Operator` is defined as:
```math
R_x(\\theta) = \\begin{bmatrix}
\\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
    -i\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
-i\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
"""   
rotation_x(theta::Real,T::Type{<:Complex}=ComplexF64) = rotation(theta, 0,T)

"""
    rotation_y(theta)

Return the `Operator` that applies a rotation `theta` about the Y axis of the `target` qubit.

The `Operator` is defined as:
```math
R_y(\\theta) = \\begin{bmatrix}
\\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
    -\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
rotation_y(theta::Real,T::Type{<:Complex}=ComplexF64) = rotation(theta, pi/2,T)

"""
    phase_shift(phi)

Return the `DiagonalOperator` that applies a phase shift `phi`.

The `DiagonalOperator` is defined as:
```math
P(\\phi) = \\begin{bmatrix}
    1 & 0 \\\\[0.5em]      
    0 & e^{i\\phi}
\\end{bmatrix}.
```
""" 
phase_shift(phi,T::Type{<:Complex}=ComplexF64) = DiagonalOperator(T[1.,exp(im*phi)])

"""
    universal(theta, phi, lambda)

Return the `Operator` which performs a rotation about the angles `theta`, `phi`, and `lambda`.
See: https://qiskit.org/textbook/ch-states/single-qubit-gates.html#generalU

The `Operator` is defined as:
```math
U(\\theta, \\phi, \\lambda) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -e^{i\\lambda}\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    e^{i\\phi}\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        e^{i\\left(\\phi+\\lambda\\right)}\\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
universal(theta::Real, phi::Real, lambda::Real,T::Type{<:Complex}=ComplexF64) = DenseOperator(
    T[cos(theta/2) -exp(im*lambda)*sin(theta/2)
     exp(im*phi)*sin(theta/2) exp(im*(phi+lambda))*cos(theta/2)]
)

"""
    control_x()

Return the controlled-X (or controlled NOT) `Operator`, which is defined as:
```math
CX = CNOT = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 \\\\
    0 & 0 & 0 & 1 \\\\
    0 & 0 & 1 & 0
    \\end{bmatrix}.
```
"""
control_x(T::Type{<:Complex}=ComplexF64) = DenseOperator(
    T[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0] [
            0.0,
            0.0,
            1.0,
            0.0,
    ]],
)

"""
    control_z()

Return the controlled-Z `Operator`, which is defined as:
```math
CZ = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 \\\\
    0 & 0 & 1 & 0 \\\\
    0 & 0 & 0 & -1
    \\end{bmatrix}.
```
"""
control_z(T::Type{<:Complex}=ComplexF64) = DenseOperator(
    T[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [
            0.0,
            0.0,
            0.0,
            -1.0,
    ]]
)

"""
    iswap()

Return the imaginary swap `Operator`, which is defined as:
```math
iSWAP = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 0 & i & 0 \\\\
    0 & i & 0 & 0 \\\\
    0 & 0 & 0 & 1
    \\end{bmatrix}.
```
"""
iswap(T::Type{<:Complex}=ComplexF64) = SwapLikeOperator(T(im))

"""
    swap()

Return the swap `Operator`, which is defined as:
```math
iSWAP = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 0 & 1 & 0 \\\\
    0 & 1 & 0 & 0 \\\\
    0 & 0 & 0 & 1
    \\end{bmatrix}.
```
"""
swap(T::Type{<:Complex}=ComplexF64) = SwapLikeOperator(T(1.0))

"""
    toffoli()

Return the Toffoli `Operator`, which is defined as:
```math
CCX = CCNOT = \\begin{bmatrix}
    1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\\\
    0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\\\
    0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 \\\\
    0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 \\\\
    0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\\\
    0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 \\\\
    0 & 0 & 0 & 0 & 0 & 0 & 1 & 0
    \\end{bmatrix}.
```
"""
toffoli(T::Type{<:Complex}=ComplexF64) = DenseOperator(
    T[1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0
    0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0
    0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0
    0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0
    0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0]
)

"""
    iswap_dagger()

Return the adjoint of the imaginary swap `Operator`, which is defined as:
```math
iSWAP^\\dagger = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 0 & -i & 0 \\\\
    0 & -i & 0 & 0 \\\\
    0 & 0 & 0 & 1
    \\end{bmatrix}.
```
"""
iswap_dagger(T::Type{<:Complex}=ComplexF64) = SwapLikeOperator(T(-im))

"""
    sigma_x(target)

Return the Pauli-X `Gate`, which applies the [`sigma_x()`](@ref) `AntiDiagonalOperator` to the target qubit.
"""
sigma_x(target::Integer) = Gate(SigmaX(), [target])

struct SigmaX <: AbstractGateSymbol end

"""
    get_operator(gate::Gate)

Returns the `Operator` which is associated to a `Gate`.

# Examples
```jldoctest
julia> x = sigma_x(1);

julia> get_operator(get_gate_symbol(x))
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


```
"""
get_operator(::SigmaX,T::Type{<:Complex}=ComplexF64) = sigma_x(T)

"""
    sigma_y(target)

Return the Pauli-Y `Gate`, which applies the [`sigma_y()`](@ref) `Operator` to the target qubit.
"""
sigma_y(target::Integer) = Gate(SigmaY(), [target])

struct SigmaY <: AbstractGateSymbol end

get_operator(::SigmaY,T::Type{<:Complex}=ComplexF64) = sigma_y(T)


"""
    sigma_z(target)

Return the Pauli-Z `Gate`, which applies the [`sigma_z()`](@ref) `Operator` to the target qubit.
"""
sigma_z(target::Integer) = Gate(SigmaZ(), [target])

struct SigmaZ <: AbstractGateSymbol end

get_operator(::SigmaZ,T::Type{<:Complex}=ComplexF64) = sigma_z(T)

"""
    hadamard(target)

Return the Hadamard `Gate`, which applies the [`hadamard()`](@ref) `Operator` to the `target` qubit.
"""
hadamard(target::Integer) = Gate(Hadamard(), [target])

struct Hadamard <: AbstractGateSymbol end

get_operator(::Hadamard,T::Type{<:Complex}=ComplexF64) = hadamard(T)

"""
    pi_8(target)

Return a π/8 `Gate` (also known as a ``T`` `Gate`), which applies the [`pi_8()`](@ref) `DiagonalOperator` to the `target` qubit.
"""
pi_8(target::Integer) = Gate(Pi8(), [target])

struct Pi8 <: AbstractGateSymbol end

get_operator(::Pi8,T::Type{<:Complex}=ComplexF64) = pi_8(T)

Base.inv(::Pi8) = Pi8Dagger()


"""
    pi_8_dagger(target)

Return an adjoint π/8 `Gate` (also known as a ``T^\\dagger`` `Gate`), which applies the [`pi_8_dagger()`](@ref) `Operator` to the `target` qubit.
"""
pi_8_dagger(target::Integer) = Gate(Pi8Dagger(), [target])

struct Pi8Dagger <: AbstractGateSymbol end

get_operator(::Pi8Dagger,T::Type{<:Complex}=ComplexF64) = pi_8_dagger(T)

Base.inv(::Pi8Dagger) = Pi8()


"""
    x_90(target)

Return a `Gate` that applies a 90° rotation about the X axis as defined by the [`x_90()`](@ref) `Operator`.
"""
x_90(target::Integer) = Gate(X90(), [target])

struct X90 <: AbstractGateSymbol end

get_operator(::X90, T::Type{<:Complex}=ComplexF64) = x_90(T)

Base.inv(::X90) = XM90()

"""
    x_minus_90(target)

Return a `Gate` that applies a -90° rotation about the X axis as defined by the [`x_minus_90()`](@ref) `Operator`.
"""
x_minus_90(target::Integer) = Gate(XM90(), [target])

struct XM90 <: AbstractGateSymbol end

get_operator(::XM90, T::Type{<:Complex}=ComplexF64) = x_minus_90(T)

Base.inv(::XM90) = X90()

"""
    y_90(target)

Return a `Gate` that applies a 90° rotation about the Y axis as defined by the [`y_90()`](@ref) `Operator`.
"""
y_90(target::Integer) = Gate(Y90(), [target])

struct Y90 <: AbstractGateSymbol end

get_operator(::Y90, T::Type{<:Complex}=ComplexF64) = y_90(T)

Base.inv(::Y90) = YM90()

"""
    y_minus_90(target)

Return a `Gate` that applies a -90° rotation about the Y axis as defined by the [`y_minus_90()`](@ref) `Operator`.
"""
y_minus_90(target::Integer) = Gate(YM90(), [target])

struct YM90 <: AbstractGateSymbol end

get_operator(::YM90, T::Type{<:Complex}=ComplexF64) = y_minus_90(T)

Base.inv(::YM90) = Y90()

"""
    z_90(target)

Return a `Gate` that applies a 90° rotation about the Z axis as defined by the [`z_90()`](@ref) `Operator`.
"""
z_90(target::Integer) = Gate(Z90(), [target])

struct Z90 <: AbstractGateSymbol end

get_operator(::Z90, T::Type{<:Complex}=ComplexF64) = z_90(T)

Base.inv(::Z90) = ZM90()

"""
    z_minus_90(target)

Return a `Gate` that applies a -90° rotation about the Z axis as defined by the [`z_minus_90()`](@ref) `Operator`.
"""
z_minus_90(target::Integer) = Gate(ZM90(), [target])

struct ZM90 <: AbstractGateSymbol end

get_operator(::ZM90, T::Type{<:Complex}=ComplexF64) = z_minus_90(T)

Base.inv(::ZM90) = Z90()


"""
    rotation(target, theta, phi)

Return a gate that applies a rotation `theta` to the `target` qubit about the cos(`phi`)X+sin(`phi`)Y axis.

The corresponding `Operator` is [`rotation(theta, phi)`](@ref).
"""
rotation(target::Integer, theta::Real, phi::Real) = Gate(Rotation(theta, phi), [target])

struct Rotation <: AbstractGateSymbol
    theta::Real
    phi::Real
end

get_operator(gate::Rotation, T::Type{<:Complex}=ComplexF64) = rotation(gate.theta,gate.phi,T)

Base.inv(gate::Rotation) = Rotation(-gate.theta, gate.phi)

get_gate_parameters(gate::Rotation)=Dict(
    "theta" =>gate.theta,
    "phi"   =>gate.phi,
)

########################################################################


    """
    rotation_x(target, theta)

Return a `Gate` that applies a rotation `theta` about the X axis of the `target` qubit.

The corresponding `Operator` is [`rotation_x(theta)`](@ref).
"""    
rotation_x(target::Integer, theta::Real) = Gate(RotationX(theta), [target])

struct RotationX <: AbstractGateSymbol
    theta::Real
end

get_operator(gate::RotationX, T::Type{<:Complex}=ComplexF64) = rotation_x(gate.theta,T)

Base.inv(gate::RotationX) = RotationX(-gate.theta)

get_gate_parameters(gate::RotationX)=Dict("theta" =>gate.theta)

    """
    rotation_y(target, theta)

Return a `Gate` that applies a rotation `theta` about the Y axis of the `target` qubit.

The corresponding `Operator` is [`rotation_y(theta)`](@ref).
""" 
rotation_y(target::Integer, theta::Real) = Gate(RotationY(theta), [target])

struct RotationY <: AbstractGateSymbol
    theta::Real
end

get_operator(gate::RotationY, T::Type{<:Complex}=ComplexF64) = rotation_y(gate.theta,T)

Base.inv(gate::RotationY) = RotationY(-gate.theta)

get_gate_parameters(gate::RotationY)=Dict("theta" =>gate.theta)

"""
    phase_shift(target, phi)

Return a `Gate` that applies a phase shift `phi` to the `target` qubit as defined by the [`phase_shift(phi)`](@ref) `DiagonalOperator`.
""" 
phase_shift(target::Integer, phi::Real) = Gate(PhaseShift(phi), [target])

struct PhaseShift <: AbstractGateSymbol
    phi::Real
end

get_operator(gate::PhaseShift,T::Type{<:Complex}=ComplexF64) = phase_shift(gate.phi,T)

Base.inv(gate::PhaseShift) = PhaseShift(-gate.phi)

get_gate_parameters(gate::PhaseShift)=Dict("lambda" =>gate.phi)

"""
    universal(target, theta, phi, lambda)

Return a gate which rotates the `target` qubit given the angles `theta`, `phi`, and `lambda`.
See: https://qiskit.org/textbook/ch-states/single-qubit-gates.html#generalU

The corresponding `Operator` is [`universal(theta, phi, lambda)`](@ref).
""" 
universal(target::Integer, theta::Real, phi::Real, lambda::Real) = Gate(Universal(theta, phi, lambda), [target])

struct Universal <: AbstractGateSymbol
    theta::Real
    phi::Real
    lambda::Real
end

get_operator(gate::Universal, T::Type{<:Complex}=ComplexF64) = universal(gate.theta, gate.phi, gate.lambda,T)

Base.inv(gate::Universal) = Universal(-gate.theta,-gate.lambda, -gate.phi)

get_gate_parameters(gate::Universal)=Dict(
    "theta" =>gate.theta,
    "phi"   =>gate.phi,
    "lambda"=>gate.lambda
)

# two qubit gates

"""
    control_z(control_qubit, target_qubit)

Return a controlled-Z gate given a `control_qubit` and a `target_qubit`.

The corresponding `Operator` is [`control_z()`](@ref).
""" 
function control_z(control_qubit, target_qubit)
    ensure_target_qubits_are_different([control_qubit, target_qubit])
    return Gate(ControlZ(), [control_qubit,target_qubit])
end

function ensure_target_qubits_are_different(target::Array)
    num_targets = length(target)
    if num_targets > 1
        previous_target = target[1]
        for i = 2:num_targets
            current_target = target[i]
            if previous_target == current_target
                throw(DomainError(current_target,
                    "The gate uses qubit $current_target more than once!"))
            end
        end
    end
end

struct ControlZ <: AbstractControlledGateSymbol end

get_operator(gate::ControlZ, T::Type{<:Complex}=ComplexF64) = control_z(T)

get_num_connected_qubits(::ControlZ) = 2
get_num_control_qubits(::ControlZ) = 1
get_num_target_qubits(::ControlZ) = 1

"""
    control_x(control_qubit, target_qubit)

Return a controlled-X gate (also known as a controlled NOT gate) given a `control_qubit` and a `target_qubit`.

The corresponding `Operator` is [`control_x()`](@ref).
""" 
function control_x(control_qubit::Integer, target_qubit::Integer)
    ensure_target_qubits_are_different([control_qubit, target_qubit])
    return Gate(ControlX(), [control_qubit, target_qubit])
end

struct ControlX <: AbstractControlledGateSymbol end

get_operator(gate::ControlX, T::Type{<:Complex}=ComplexF64) = control_x(T)

get_num_connected_qubits(::ControlX) = 2
get_num_control_qubits(::ControlX) = 1
get_num_target_qubits(::ControlX) = 1

"""
    iswap(qubit_1, qubit_2)

Return the imaginary swap `Gate` which applies the imaginary swap `Operator` to `qubit_1` and `qubit_2.`

The corresponding `Operator` is [`iswap()`](@ref).
""" 
function iswap(qubit_1, qubit_2)
    ensure_target_qubits_are_different([qubit_1, qubit_2])
    return Gate(ISwap(), [qubit_1, qubit_2])
end

struct ISwap <: AbstractGateSymbol end

get_operator(gate::ISwap, T::Type{<:Complex}=ComplexF64) = iswap(T)

get_num_connected_qubits(::ISwap) = 2

Base.inv(::ISwap) = ISwapDagger()

"""
    swap(qubit_1, qubit_2)

Return the swap `Gate` which applies the swap `Operator` to `qubit_1` and `qubit_2.`

The corresponding `Operator` is [`swap()`](@ref).
""" 
function swap(qubit_1, qubit_2)
    ensure_target_qubits_are_different([qubit_1, qubit_2])
    return Gate(Swap(), [qubit_1, qubit_2])
end

struct Swap <: AbstractGateSymbol end

get_operator(::Swap, T::Type{<:Complex}=ComplexF64) = swap(T)

get_num_connected_qubits(::Swap) = 2

"""
    toffoli(control_qubit_1, control_qubit_2, target_qubit)

Return a Toffoli gate (also known as a CCNOT gate) given two control qubits and a `target_qubit`.

The corresponding `Operator` is [`toffoli()`](@ref).
"""
function toffoli(
        control_qubit_1::Integer, 
        control_qubit_2::Integer, 
        target_qubit::Integer
    )
    ensure_target_qubits_are_different(
        [control_qubit_1, control_qubit_2, target_qubit]
    )
    return Gate(Toffoli(), [control_qubit_1, control_qubit_2, target_qubit])
end

struct Toffoli <: AbstractControlledGateSymbol end

get_operator(gate::Toffoli, T::Type{<:Complex}=ComplexF64) = toffoli(T)

get_num_connected_qubits(::Toffoli) = 3
get_num_control_qubits(::Toffoli) = 2
get_num_target_qubits(::Toffoli) = 1

# optimized application of ControlX, ControlZ or Toffoli gate without calling operator 
# (it is hard-coded in apply_control_x!, apply_control_z! or apply_toffoli!, respectively)
function apply_gate!(state::Ket, gate::Union{Gate{ControlX},Gate{ControlZ},Gate{Toffoli}})
    qubit_count = get_num_qubits(state)
    
    connected_qubits=get_connected_qubits(gate)

    if any(t -> t>qubit_count ,connected_qubits)
        throw(DomainError(connected_qubits,
            "Not enough qubits in the Ket for the targets in gate"))
    end

    control_qubits=get_control_qubits(gate)

    target_qubits=get_target_qubits(gate)
    @assert length(target_qubits)==1

    if typeof(get_gate_symbol(gate))==ControlX
        @assert length(control_qubits)==1
        apply_control_x!(state,control_qubits[1],target_qubits[1])
    elseif typeof(get_gate_symbol(gate))==ControlZ
        @assert length(control_qubits)==1
        apply_control_z!(state,control_qubits[1],target_qubits[1])
    else
        @assert length(control_qubits)==2
        apply_toffoli!(state,control_qubits,target_qubits[1])
    end
end

"""
    iswap_dagger(qubit_1, qubit_2)

Return the adjoint imaginary swap `Gate` which applies the adjoint imaginary swap `Operator` to `qubit_1` and `qubit_2.`

The corresponding `Operator` is [`iswap_dagger()`](@ref).
""" 
function iswap_dagger(qubit_1::Integer, qubit_2::Integer)
    ensure_target_qubits_are_different([qubit_1, qubit_2])
    return Gate(ISwapDagger(), [qubit_1, qubit_2])
end

struct ISwapDagger <: AbstractGateSymbol end

get_operator(gate::ISwapDagger, T::Type{<:Complex}=ComplexF64) = iswap_dagger(T)

Base.inv(::ISwapDagger) = ISwap()

get_num_connected_qubits(::ISwapDagger) = 2


"""
    identity_gate(target)

Return the Identity `Gate`, which applies the [`identity_gate()`](@ref) `IdentityOperator` to the target qubit.
"""
identity_gate(target::Integer) = Gate(Identity(), [target])

struct Identity <: AbstractGateSymbol end

get_operator(gate::Identity,T::Type{<:Complex}=ComplexF64) = IdentityOperator{2,T}()


"""
    Base.:*(M::Gate, x::Ket)

Return a `Ket` which results from applying `Gate` `M` to `Ket` `x`.

# Examples
```jldoctest
julia> ψ_0 = fock(0, 2)
2-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im


julia> ψ_1 = sigma_x(1)*ψ_0
2-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im


```
"""
Base.:*(M::Gate, x::Ket) = get_transformed_state(x, M) 

function get_transformed_state(state::Ket, gate::Gate)
    transformed_state = deepcopy(state)
    apply_gate!(transformed_state, gate)
    return transformed_state
end

"""
    inv(gate::AbstractGateSymbol)

Return a `Gate` which is the inverse of the input `gate`.

# Examples
```jldoctest
julia> u = universal(1, -pi/2, pi/3, pi/4)
Gate Object: Snowflurry.Universal
Parameters: 
theta	: -1.5707963267948966
phi	: 1.0471975511965976
lambda	: 0.7853981633974483

Connected_qubits	: [1]
Operator:
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.7071067811865476 + 0.0im    0.5 + 0.4999999999999999im
-0.3535533905932738 - 0.6123724356957945im    -0.18301270189221924 + 0.6830127018922194im


julia> inv(u)
Gate Object: Snowflurry.Universal
Parameters: 
theta	: 1.5707963267948966
phi	: -0.7853981633974483
lambda	: -1.0471975511965976

Connected_qubits	: [1]
Operator:
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.7071067811865476 + 0.0im    -0.3535533905932738 + 0.6123724356957945im
0.5 - 0.4999999999999999im    -0.18301270189221924 - 0.6830127018922194im


```
"""
function Base.inv(symbol::AbstractGateSymbol)
    if is_hermitian(get_operator(symbol))
        return symbol
    end
    throw(NotImplementedError(:inv, symbol))
end

function show_gate(
    io::IO, 
    gate_name::DataType, 
    targets::Vector{Int},
    op::AbstractOperator
    )
    
    println(io, "Gate Object: $gate_name")

    println(io, "Connected_qubits\t: $targets")

    println(io, "Operator:")
    show(io, "text/plain", op)
end

function show_gate(
    io::IO, 
    gate_name::DataType, 
    targets::Vector{Int},
    op::AbstractOperator, 
    parameters::Dict{String, <:Real}
    )
    println(io, "Gate Object: $(gate_name)")

    println(io, "Parameters: " )
    for (key,val) in parameters 
        println(io, key,"\t: ",val)
    end
    println(io)

    println(io, "Connected_qubits\t: $targets")

    println(io, "Operator:")
    show(io, "text/plain", op)
end
