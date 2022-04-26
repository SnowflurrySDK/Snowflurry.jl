function transpile(c::QuantumCircuit, native_gates::Vector{String})
    #assert single qubit pauli gates are included in the native_gates
    for gate in keys(PAULI_GATES)
        if !(gate in native_gates)
            throw(ErrorException("The native gates must include single qubit pauli gates"))
        end
    end
    return c
end