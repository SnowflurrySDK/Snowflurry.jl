
struct Readout <: AbstractInstruction
    connected_qubit::Int
end

Base.inv(readout::Readout) = readout

function get_connected_qubits(readout::Readout)::AbstractVector{Int}
    return Vector{Int}([readout.connected_qubit])
end

function move_instruction(
    readout::Readout,
    qubit_mapping::AbstractDict{T,T},
)::AbstractInstruction where {T<:Integer}

    connected_qubits = get_connected_qubits(readout)

    @assert len(connected_qubits) == 1 "a Readout can only be single-qubit"

    qubit = connected_qubits[1]

    if haskey(qubit_mapping, qubit)
        qubit = qubit_mapping[qubit]
    end

    return Readout(qubit)
end
