using AbstractAlgebra: GFElem, Generic.MatSpaceElem, GF, zero_matrix, nrows,
    identity_matrix, lift

const GFInt = GFElem{Int}
const GFMatrix = MatSpaceElem{GFInt}

"""
    PauliGroupElement

A Pauli group element which is represented using the approach of
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).

The [`get_pauli`](@ref) functions should be used to generate `PauliGroupElement` objects.
"""
struct PauliGroupElement
    u::GFMatrix
    delta::GFInt
    epsilon::GFInt
end

"""
    get_pauli(circuit::QuantumCircuit; imaginary_exponent::Integer=0,
        negative_exponent::Integer=0)::PauliGroupElement

Returns a `PauliGroupElement` given a `circuit` containing Pauli gates.

A Pauli group element corresponds to ``i^\\delta (-1)^\\epsilon \\sigma_a``, where
``\\delta`` and ``\\epsilon`` are set by specifying `imaginary_exponent` and
`negative_exponent`, respectively. The exponents must be 0 or 1. Their default value is 0.
As for ``\\sigma_a``, it is a tensor product of Pauli operators. The Pauli operators are
specified in the `circuit`.

# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count=2);

julia> push!(circuit, sigma_x(1), sigma_y(2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X───────
               
q[2]:───────Y──
               



julia> get_pauli(circuit, imaginary_exponent=1, negative_exponent=1)
Pauli Group Element:
-1.0im*X(1)*Y(2)



```

If multiple Pauli gates are applied to the same qubit in the `circuit`, the gates are
multiplied with the first gate in the `circuit` being the rightmost gate in the
multiplication.

```jldoctest
julia> circuit = QuantumCircuit(qubit_count=1);

julia> push!(circuit, sigma_x(1), sigma_z(1))
Quantum Circuit Object:
   qubit_count: 1 
q[1]:──X────Z──
               



julia> get_pauli(circuit)
Pauli Group Element:
1.0im*Y(1)



```
"""
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

"""
    get_pauli(gate::AbstractGate, num_qubits::Integer; imaginary_exponent::Integer=0,
        negative_exponent::Integer=0)::PauliGroupElement

Returns a `PauliGroupElement` given a `gate` and the number of qubits.

A Pauli group element corresponds to ``i^\\delta (-1)^\\epsilon \\sigma_a``, where
``\\delta`` and ``\\epsilon`` are set by specifying `imaginary_exponent` and
`negative_exponent`, respectively. The exponents must be 0 or 1. Their default value is 0.
As for ``\\sigma_a``, it is a tensor product of Pauli operators. In this variant of the
`get_pauli` function, a single Pauli operator is set by providing a `gate`. The number of
qubits is specified by `num_qubits`.

# Examples
```jldoctest
julia> gate = sigma_x(2);

julia> num_qubits = 3;

julia> get_pauli(gate, num_qubits)
Pauli Group Element:
1.0*X(2)



```
"""
function get_pauli(gate::AbstractGate, num_qubits::Integer; imaginary_exponent::Integer=0,
    negative_exponent::Integer=0)::PauliGroupElement

    target_qubit = get_connected_qubits(gate)[1]
    if target_qubit > num_qubits
        throw(ErrorException("the target qubit is not in the circuit"))
    end
    assert_exponents_are_in_the_field(imaginary_exponent, negative_exponent)
    return unsafe_get_pauli(gate, num_qubits, GF(2)(imaginary_exponent),
        GF(2)(negative_exponent))
end

function unsafe_get_pauli(gate::Identity, num_qubits::Integer,
    imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    
    u = zero_matrix(GF(2), 2*num_qubits, 1)
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

function unsafe_get_pauli(gate::SigmaX, num_qubits::Integer,
    imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    
    target_qubit = get_connected_qubits(gate)[1]
    u = zero_matrix(GF(2), 2*num_qubits, 1)
    u[num_qubits+target_qubit, 1] = 1
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

function unsafe_get_pauli(gate::SigmaY, num_qubits::Integer,
        imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    target_qubit = get_connected_qubits(gate)[1]
    u = zero_matrix(GF(2), 2*num_qubits, 1)
    u[target_qubit, 1] = 1
    u[num_qubits+target_qubit, 1] = 1
    negative_exponent += imaginary_exponent+1
    imaginary_exponent += 1
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

function unsafe_get_pauli(gate::SigmaZ, num_qubits::Integer,
    imaginary_exponent::GFInt, negative_exponent::GFInt)::PauliGroupElement
    
    target_qubit = get_connected_qubits(gate)[1]
    u = zero_matrix(GF(2), 2*num_qubits, 1)
    u[target_qubit, 1] = 1
    return PauliGroupElement(u, imaginary_exponent, negative_exponent)
end

"""
    Base.:*(p1::PauliGroupElement, p2::PauliGroupElement)::PauliGroupElement

Returns the product of two `PauliGroupElement` objects.

The `PauliGroupElement` objects must be associated with the same number of qubits.

# Examples
```jldoctest
julia> pauli_z = get_pauli(sigma_z(1), 1)
Pauli Group Element:
1.0*Z(1)



julia> pauli_y = get_pauli(sigma_y(1), 1)
Pauli Group Element:
1.0*Y(1)



julia> pauli_z*pauli_y
Pauli Group Element:
-1.0im*X(1)



```
"""
function Base.:*(p1::PauliGroupElement, p2::PauliGroupElement)::PauliGroupElement

    new_delta = p1.delta+p2.delta
    if nrows(p1.u) != nrows(p2.u)
        throw(ErrorException("the Pauli group elements must be associated with the "
        *"same number of qubits"))
    end
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

struct PauliCircuit
    circuit::QuantumCircuit
    imaginary_exponent::Int
    negative_exponent::Int
end

function convert_to_pauli_circuit(pauli::PauliGroupElement)::PauliCircuit
    u = pauli.u
    num_qubits = Int(nrows(u)/2)
    circuit = QuantumCircuit(qubit_count=num_qubits)
    imaginary_exponent = pauli.delta
    negative_exponent = pauli.epsilon

    for i_qubit = 1:num_qubits
        u1 = u[i_qubit, 1]
        u2 = u[i_qubit+num_qubits, 1]
        if u1 == GF(2)(0)
            if u2 == GF(2)(1)
                push!(circuit, sigma_x(i_qubit))
            end
        else
            if u2 == GF(2)(0)
                push!(circuit, sigma_z(i_qubit))
            else
                push!(circuit, sigma_y(i_qubit))
                negative_exponent += imaginary_exponent
                imaginary_exponent += 1
            end
        end
    end
    return PauliCircuit(circuit, lift(imaginary_exponent), lift(negative_exponent))
end


"""
    get_quantum_circuit(pauli::PauliGroupElement)::QuantumCircuit

Returns the Pauli gates of a `PauliGroupElement` as a `QuantumCircuit`.

# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count=2);

julia> push!(circuit, sigma_x(1), sigma_y(2))
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X───────
               
q[2]:───────Y──
               



julia> pauli = get_pauli(circuit, imaginary_exponent=1, negative_exponent=1)
Pauli Group Element:
-1.0im*X(1)*Y(2)



julia> get_quantum_circuit(pauli)
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X───────
               
q[2]:───────Y──
               



```
"""
function get_quantum_circuit(pauli::PauliGroupElement)::QuantumCircuit
    displayable_pauli = convert_to_pauli_circuit(pauli)
    return displayable_pauli.circuit
end

"""
    get_negative_exponent(pauli::PauliGroupElement)::Int

Returns the negative exponent of a `PauliGroupElement`.

# Examples
```jldoctest
julia> gate = sigma_x(2);

julia> num_qubits = 3;

julia> pauli = get_pauli(gate, num_qubits, negative_exponent=1)
Pauli Group Element:
-1.0*X(2)



julia> get_negative_exponent(pauli)
1

```
"""
function get_negative_exponent(pauli::PauliGroupElement)::Int
    displayable_pauli = convert_to_pauli_circuit(pauli)
    return displayable_pauli.negative_exponent
end

"""
    get_imaginary_exponent(pauli::PauliGroupElement)::Int

Returns the imaginary exponent of a `PauliGroupElement`.

# Examples
```jldoctest
julia> gate = sigma_x(2);

julia> num_qubits = 3;

julia> pauli = get_pauli(gate, num_qubits, imaginary_exponent=1)
Pauli Group Element:
1.0im*X(2)



julia> get_imaginary_exponent(pauli)
1

```
"""
function get_imaginary_exponent(pauli::PauliGroupElement)::Int
    displayable_pauli = convert_to_pauli_circuit(pauli)
    return displayable_pauli.imaginary_exponent
end

function Base.show(io::IO, pauli::PauliGroupElement)
    println(io, "Pauli Group Element:")
    displayable_pauli = convert_to_pauli_circuit(pauli)
    if displayable_pauli.negative_exponent == 1
        print(io, "-")
    end
    print(io, "1.0")
    if displayable_pauli.imaginary_exponent == 1
        print(io, "im")
    end
    for gate in get_circuit_gates(displayable_pauli.circuit)
        print_pauli_gate(io, gate)
    end
    println(io)
    println(io)
end

function print_pauli_gate(io::IO, gate::SigmaX)
    target = get_connected_qubits(gate)[1]
    print(io, "*X($(target))")
end

function print_pauli_gate(io::IO, gate::SigmaY)
    target = get_connected_qubits(gate)[1]
    print(io, "*Y($(target))")
end

function print_pauli_gate(io::IO, gate::SigmaZ)
    target = get_connected_qubits(gate)[1]
    print(io, "*Z($(target))")
end
