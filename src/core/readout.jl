struct Readout <: AbstractInstruction
    connected_qubit::Int
end

readout(qubit::Int) = Readout(qubit)

function get_connected_qubits(readout::Readout)::AbstractVector{Int}
    return Vector{Int}([readout.connected_qubit])
end

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

    return readout(qubit)
end
