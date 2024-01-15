"""
    Readout <: AbstractInstruction

`Readout` is an implementation of an `AbstractInstruction` that specifies 
an explicit measurement on a particular qubit, and the destination bit in 
the classical result registry (classical bit).
It is built using the `readout(qubit::Int, bit::Int)` helper function, where 
the first argument is the target qubit, and the second is the destination classical bit.

# Examples
```jldoctest
julia> r = readout(1, 2)
Explicit Readout object:
   connected_qubit: 1 
   destination_bit: 2 

```
"""
struct Readout <: AbstractInstruction
    connected_qubit::Int
    destination_bit::Int
end

"""
    readout(qubit::Int, bit::Int)

Return a `Readout` `AbstractInstruction`, which performs a 
readout on the target `qubit`, and places the result in the destination `bit`.

"""
readout(qubit::Int, bit::Int) = Readout(qubit, bit)

function Base.show(io::IO, r::Readout)
    println(io, "Explicit Readout object:")
    println(io, "   connected_qubit: $(get_connected_qubits(r)[1]) ")
    println(io, "   destination_bit: $(get_destination_bit(r)) ")
end

function get_connected_qubits(readout::Readout)::AbstractVector{Int}
    return Vector{Int}([readout.connected_qubit])
end

get_destination_bit(readout::Readout)::Int = readout.destination_bit

function move_instruction(
    original_readout::Readout,
    qubit_mapping::AbstractDict{T,T},
)::AbstractInstruction where {T<:Integer}

    connected_qubits = get_connected_qubits(original_readout)

    @assert length(connected_qubits) == 1 "a Readout can only be single-qubit"

    qubit = connected_qubits[1]

    if haskey(qubit_mapping, qubit)
        qubit = qubit_mapping[qubit]
    end

    return readout(qubit, get_destination_bit(original_readout))
end
