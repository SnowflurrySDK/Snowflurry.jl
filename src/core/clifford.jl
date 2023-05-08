using AbstractAlgebra: GFElem, Generic.MatSpaceElem, GF, zero_matrix, nrows, identity_matrix

const GFInt = GFElem{Int}
const GFMatrix = MatSpaceElem{GFInt}

"""
    PauliGroupElement(u::gfp_mat, delta::Int, epsilon::Int)
A Pauli group element which is represented using the approach of
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).
"""
struct PauliGroupElement
    u::GFMatrix
    delta::GFInt
    epsilon::GFInt
end

function get_pauli(circuit::QuantumCircuit; imaginary_exponent::Integer=0,
    negative_exponent::Integer=0)::PauliGroupElement

    assert_exponents_are_in_the_field(imaginary_exponent, negative_exponent)
    num_qubits = get_num_qubits(circuit)
    pauli = unsafe_get_pauli(Identity(1), num_qubits, GF(2)(imaginary_exponent),
        GF(2)(negative_exponent))
    
    for gate in get_circuit_gates(circuit)
        new_pauli = unsafe_get_pauli(gate, num_qubits, GF(2)(0), GF(2)(0))
        pauli = new_pauli*pauli
    end
    return pauli
end

function assert_exponents_are_in_the_field(imaginary_exponent::Integer,
    negative_exponent::Integer)

    if imaginary_exponent > 1 || imaginary_exponent < 0
        throw(ErrorException("the imaginary exponent must be 0 or 1"))
    end
    if negative_exponent > 1 || negative_exponent < 0
        throw(ErrorException("the negative exponent must be 0 or 1"))
    end
end

function get_pauli(gate::AbstractGate, qubit_count::Integer; imaginary_exponent::Integer=0,
    negative_exponent::Integer=0)::PauliGroupElement

    target_qubit = get_connected_qubits(gate)[1]
    if target_qubit > qubit_count
        throw(ErrorException("the target qubit is not in the circuit"))
    end
    assert_exponents_are_in_the_field(imaginary_exponent, negative_exponent)
    return unsafe_get_pauli(gate, qubit_count, GF(2)(imaginary_exponent),
        GF(2)(negative_exponent))
end

function unsafe_get_pauli(gate::Identity, qubit_count::Integer,
    imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    
    u = zero_matrix(GF(2), 2*qubit_count, 1)
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

function unsafe_get_pauli(gate::SigmaX, qubit_count::Integer,
    imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    
    target_qubit = get_connected_qubits(gate)[1]
    u = zero_matrix(GF(2), 2*qubit_count, 1)
    u[2*target_qubit, 1] = 1
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

function unsafe_get_pauli(gate::SigmaY, qubit_count::Integer,
        imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    target_qubit = get_connected_qubits(gate)[1]
    first_index = 2*target_qubit-1
    u = zero_matrix(GF(2), 2*qubit_count, 1)
    u[first_index, 1] = 1
    u[first_index+1, 1] = 1
    negative_exponent += imaginary_exponent+1
    imaginary_exponent += 1
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

function unsafe_get_pauli(gate::SigmaZ, qubit_count::Integer,
    imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    
    target_qubit = get_connected_qubits(gate)[1]
    u = zero_matrix(GF(2), 2*qubit_count, 1)
    u[2*target_qubit-1, 1] = 1
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

function Base.:*(p1::PauliGroupElement, p2::PauliGroupElement)::PauliGroupElement

    new_delta = p1.delta+p2.delta
    new_u = p1.u+p2.u
    twice_num_qubits = nrows(new_u)
    num_qubits = Int(twice_num_qubits/2)
    capital_u = zero_matrix(GF(2), twice_num_qubits, twice_num_qubits)
    capital_u[1:num_qubits, num_qubits+1:twice_num_qubits] =
        identity_matrix(GF(2), num_qubits)
    new_epsilon = p1.epsilon+p2.epsilon+p1.delta*p2.delta+transpose(p2.u)*capital_u*p1.u
    return PauliGroupElement(new_u, new_delta, new_epsilon[1,1])
end

function Base.:(==)(lhs::PauliGroupElement, rhs::PauliGroupElement)::Bool
    if lhs.delta != rhs.delta
        return false
    elseif lhs.epsilon != rhs.epsilon
        return false
    elseif lhs.u != rhs.u
        return false
    else
        return true
    end
end

function get_quantum_circuit(pauli::PauliGroupElement)::QuantumCircuit
    u = pauli.u
    num_qubits = Int(nrows(u)/2)
    circuit = QuantumCircuit(qubit_count=num_qubits)
    for i_qubit = 1:num_qubits
        u_for_qubit = u[2*i_qubit-1:2*i_qubit, 1]
        if u_for_qubit == GF(2)[0; 1]
            push!(circuit, sigma_x(i_qubit))
        elseif u_for_qubit == GF(2)[1; 1]
            push!(circuit, sigma_y(i_qubit))
        elseif u_for_qubit == GF(2)[1; 0]
            push!(circuit, sigma_z(i_qubit))
        end
    end
    return circuit
end
