using Nemo: gfp_mat, MatElem, gfp_elem, GF, zero_matrix, nrows, ncols

"""
    CliffordOperator(c_bar::Nemo.gfp_mat, h_bar::Nemo.gfp_mat)

A Clifford operator which is represented using the approach of 
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).

The operator can be constructed using the ``\\bar{C}`` matrix and the ``\\bar{h}``
vector.
"""
struct CliffordOperator
    c_bar::gfp_mat
    h_bar::gfp_mat

    function CliffordOperator(c_bar::gfp_mat, h_bar::gfp_mat)
        @assert nrows(c_bar) == ncols(c_bar)
        @assert nrows(h_bar) == nrows(c_bar)
        @assert ncols(h_bar) == 1
        @assert mod(nrows(c_bar), 2) == 1
        @assert c_bar.base_ring == GF(2)
        @assert h_bar.base_ring == GF(2)
        new(c_bar, h_bar)
    end
end

"""
    get_clifford_operator(c::gfp_mat, h::gfp_mat)

Construct a Clifford operator using the matrix C and the vector h in the representation of 
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).
"""
function get_clifford_operator(c::gfp_mat, h::gfp_mat)
    c_bar = get_c_bar(c)
    h_bar = zero_matrix(GF(2), nrows(h)+1, 1)
    h_bar[1:nrows(h), 1] = deepcopy(h)
    CliffordOperator(c_bar, h_bar)
end

function get_c_bar(c::gfp_mat)
    n = Int(size(c, 1)/2)
    u = zero_matrix(GF(2), 2*n, 2*n)
    for i = 1:n
        u[i, i+n] = 1
    end

    d = get_diagonal(transpose(c)*u*c)
    c_bar = zero_matrix(GF(2), 2*n+1, 2*n+1)
    c_bar[1:2*n+1, 1:2*n] = vcat(c, transpose(d))
    c_bar[2*n+1, 2*n+1] = 1
    return c_bar
end

function get_diagonal(m::MatElem)
    shortest_dim = min(nrows(m), ncols(m))
    diagonal = zero_matrix(GF(2), shortest_dim, 1)
    for i = 1:shortest_dim
        diagonal[i, 1] = m[i, i]
    end
    return diagonal
end

function Base.:*(q2::CliffordOperator, q1::CliffordOperator)
    c_bar = q2.c_bar*q1.c_bar
    h_bar = get_h_bar_for_product(q2, q1)
    return CliffordOperator(c_bar, h_bar)
end

function get_h_bar_for_product(q2::CliffordOperator, q1::CliffordOperator)
    term_2 = transpose(q1.c_bar)*q2.h_bar
    u_bar = get_u_bar(q2)
    matrix_before_triangular = transpose(q2.c_bar)*u_bar*q2.c_bar
    triangular = get_strictly_lower_triangular(matrix_before_triangular)
    term_3 = get_diagonal(transpose(q1.c_bar)*triangular*q1.c_bar)
    h_bar = q1.h_bar+term_2+term_3
    return h_bar
end

function get_u_bar(q::CliffordOperator)
    n = Int((size(q.c_bar, 1)-1)/2)
    u_bar = zero_matrix(GF(2), 2*n+1, 2*n+1)
    for i = 1:n
        u_bar[i, i+n] = 1
    end
    u_bar[2*n+1,2*n+1] = 1
    return u_bar
end

function get_strictly_lower_triangular(m::gfp_mat)
    lower_triangular = deepcopy(m)
    for j in 1:size(lower_triangular, 1)
        for i in 1:j
        lower_triangular[i, j] = 0
        end
    end
    return lower_triangular
end

function Base.:inv(q::CliffordOperator)
    c_bar = inv(q.c_bar)
    h_bar = get_h_bar_for_inverse(q)
    return CliffordOperator(c_bar, h_bar)
end

function get_h_bar_for_inverse(q::CliffordOperator)
    term_1 = transpose(inv(q.c_bar))*q.h_bar
    u_bar = get_u_bar(q)
    mult = transpose(q.c_bar)*u_bar*q.c_bar
    triangular = get_strictly_lower_triangular(mult)
    term_2 = get_diagonal(transpose(inv(q.c_bar))*triangular*inv(q.c_bar))
    h_bar = term_1+term_2
    return h_bar
end

"""
    PauliGroupElement(u::gfp_mat, delta::Int, epsilon::Int)

A Pauli group element which is represented using the approach of 
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).
"""
struct PauliGroupElement
    u::gfp_mat
    delta::gfp_elem
    epsilon::gfp_elem

    PauliGroupElement(u::gfp_mat, delta::Int, epsilon::Int) =
        new(u, GF(2)(delta), GF(2)(epsilon))
end


"""
    get_pauli_group_element(operator::Operator)

Return the `PauliGroupElement` which is associated with the `operator`.
"""
function get_pauli_group_element(operator::Operator)
    num_qubits = Int(log2(size(operator.data, 1)))
    u_list = get_all_binary_vectors(2*num_qubits)
    
    for u in u_list
        pauli_tensor = get_pauli_tensor(u)
        for delta in 0:1
            for epsilon in 0:1
                if operator ≈ im^delta*(-1)^epsilon*pauli_tensor
                    return PauliGroupElement(u, delta, epsilon)
                end
            end
        end
    end
    throw(ErrorException("the operator is not a Pauli group element"))
end

function get_all_binary_vectors(vector_length)
    temp_vector = zero_matrix(GF(2), vector_length, 1)
    vector_list = []
    index = 1
    generate_all_binary_vectors!(temp_vector, vector_list, index)
    return vector_list
end

function generate_all_binary_vectors!(vector, vector_list, index)
    if index == length(vector)+1
        push!(vector_list, deepcopy(vector))
        return
    end

    vector[index, 1] = 0
    generate_all_binary_vectors!(vector, vector_list, index+1)

    vector[index, 1] = 1
    generate_all_binary_vectors!(vector, vector_list, index+1)
end

function get_pauli_tensor(a::gfp_mat)
    num_qubits = Int(length(a)/2)
    operator = get_pauli_operator(a[1], a[1+num_qubits])
    for i = 2:num_qubits
        index_v = a[i]
        index_w = a[i+num_qubits]
        new_operator = get_pauli_operator(index_v, index_w)
        operator = kron(operator, new_operator)
    end
    return operator
end

function get_pauli_operator(index_v, index_w)
    if index_v == 0
        if index_w == 0
            return eye()
        else
            return sigma_x()
        end
    else
        if index_w == 0
            return sigma_z()
        else
            return im*sigma_y()
        end
    end
end
