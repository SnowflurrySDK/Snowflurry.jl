using Nemo: gfp_mat, MatElem, gfp_elem, GF, zero_matrix, nrows, ncols, nullspace, rank,
    identity_matrix, swap_rows!, add_row!, matrix, solve_rational

"""
    CliffordOperator(c_bar::Nemo.gfp_mat, h_bar::Nemo.gfp_mat)

A Clifford operator which is represented using the approach of
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).

The operator can be constructed using the ``\\bar{C}`` matrix and the ``\\bar{h}`` vector.
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
        assert_clifford_operator_is_symplectic(c_bar)
        new(c_bar, h_bar)
    end
end

function assert_clifford_operator_is_symplectic(c_bar::gfp_mat)
    num_qubits = Int((nrows(c_bar)-1)/2)
    u = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    u[1:num_qubits, num_qubits+1:2*num_qubits] = identity_matrix(GF(2), num_qubits)
    p = u+transpose(u)
    c = c_bar[1:2*num_qubits, 1:2*num_qubits]
    if transpose(c)*p*c != p
        throw(ErrorException("the Clifford operator is not symplectic"))
    end
    diag = get_diagonal(transpose(c)*u*c)
    d = transpose(c_bar[2*num_qubits+1,1:2*num_qubits])
    if diag != d
        throw(ErrorException("the d vector is invalid for a Clifford operator"))
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
    u[1:n, n+1:2*n] = identity_matrix(GF(2), n)

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


"""
    get_random_clifford(num_qubits)

Construct a random `CliffordOperator` given the number of qubits.
"""
function get_random_clifford(num_qubits::Integer)
    h_vector = rand(GF(2), 2*num_qubits)
    h = matrix(GF(2), 2*num_qubits, 1, h_vector)
    c = get_random_c_matrix(num_qubits)
    return get_clifford_operator(c, h)
end

function get_random_c_matrix(num_qubits::Integer)
    c = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    c[:,1] = get_first_random_c_column(num_qubits)
    p = get_p_matrix(num_qubits)

    i = 2
    while i <= 2*num_qubits
        a_for_solver = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
        a = transpose(c[:,1:i-1])*p
        a_for_solver[1:i-1,:] = a
        b = zero_matrix(GF(2), 2*num_qubits, 1)
        if i-num_qubits > 0
            b[i-num_qubits,1] = 1
        end
        possible_x = solve_rational(a_for_solver, b)
        (nullity, null_basis) = nullspace(a)
        random_vector = rand(GF(2), nullity)
        random_x_part = matrix(GF(2), nullity, 1, random_vector)
        c[:,i] = possible_x+null_basis*random_x_part
        if rank(c[:,1:i]) == i
            i = i+1
        end
    end
    return c
end

function get_first_random_c_column(num_qubits::Integer)
    found_non_zero_vector = false
    c_0 = nothing
    while !found_non_zero_vector
        c_0 = rand(GF(2), 2*num_qubits)
        if 1 in c_0
            found_non_zero_vector = true
        end
    end
    return c_0
end

"""
    get_clifford_operator(operator::Operator)

If possible, return the [`CliffordOperator`](@ref) for the provided `operator`.
"""
function get_clifford_operator(operator::Operator)
    num_qubits = get_num_qubits(operator)
    system = MultiBodySystem(num_qubits, 2)
    c = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    h = zero_matrix(GF(2), 2*num_qubits, 1)
    for i = 1:num_qubits
        embedded_z = get_embed_operator(sigma_z(), i, system)
        z_operator = operator*embedded_z*adjoint(operator)
        z_pauli_element = get_pauli_group_element(z_operator)
        c[1:2*num_qubits, i] = z_pauli_element.u
        h[i, 1] = z_pauli_element.epsilon

        embedded_x = get_embed_operator(sigma_x(), i, system)
        x_operator = operator*embedded_x*adjoint(operator)
        x_pauli_element = get_pauli_group_element(x_operator)
        c[1:2*num_qubits, i+num_qubits] = x_pauli_element.u
        h[i+num_qubits, 1] = x_pauli_element.epsilon
    end
    return get_clifford_operator(c, h)
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

function get_all_binary_vectors(vector_length::Integer)
    temp_vector = zero_matrix(GF(2), vector_length, 1)
    vector_list = gfp_mat[]
    index = 1
    generate_all_binary_vectors!(temp_vector, vector_list, index)
    return vector_list
end

function generate_all_binary_vectors!(vector::gfp_mat, vector_list::AbstractVector{gfp_mat},
    index::Integer)
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

function get_pauli_operator(index_v::gfp_elem, index_w::gfp_elem)
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

"""
    push_clifford!(circuit::QuantumCircuit, clifford::CliffordOperator)

Given the Clifford operator, `clifford` or ``Q``, which performs the mapping
``X \\rightarrow QXQ^\\dagger``, where ``X`` is a Hermitian matrix, this function adds the
operator ``U=Q^\\dagger`` to the `circuit`. This ensures that
``\\langle\\Psi|QXQ^\\dagger|\\Psi\\rangle = \\langle\\Psi|U^\\dagger XU|\\Psi\\rangle``,
where ``|\\Psi\\rangle`` is a quantum state.

The Hadamard, phase, and controlled NOT gates for the `circuit` are generated using the
approach of [Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).
"""
function push_clifford!(circuit::QuantumCircuit, clifford::CliffordOperator)
    num_qubits = Int((nrows(clifford.c_bar)-1)/2)
    if circuit.qubit_count != num_qubits
        throw(ErrorException("the Clifford operation must have the same number "*
            "of qubits as the circuit"))
    end

    current_clifford = push_c_matrix_and_return_clifford!(circuit, clifford, num_qubits)
    push_h_matrix!(circuit, current_clifford, clifford)
end

function push_c_matrix_and_return_clifford!(circuit::QuantumCircuit,
    clifford::CliffordOperator, num_qubits::Integer)
    
    g_prime = clifford.c_bar[num_qubits+1:2*num_qubits, 1:num_qubits]
    nullity, null_basis = nullspace(g_prime)
    num_qubits = nrows(g_prime)
    r2 = get_r2_matrix(nullity, null_basis, num_qubits)
    r1 = get_r1_matrix(r2, g_prime, nullity)
    rcr = get_rcr_matrix(r1, r2, clifford)

    e11 = rcr[1:nullity, 1:nullity]
    r2_updater = zero_matrix(GF(2), num_qubits, num_qubits)
    r2_updater[1:nullity, 1:nullity] = inv(e11)
    r2_updater[nullity+1:num_qubits, nullity+1:num_qubits] =
        identity_matrix(GF(2), num_qubits-nullity)
    r2 = r2*r2_updater
    rcr = get_rcr_matrix(r1, r2, clifford)

    v1 = rcr[1:nullity, nullity+1:num_qubits]
    v2 = transpose(rcr[num_qubits+nullity+1:2*num_qubits,num_qubits+1:num_qubits+nullity])

    z1 = rcr[nullity+1:num_qubits, nullity+1:num_qubits]
    z2 = rcr[num_qubits+nullity+1:2*num_qubits, num_qubits+nullity+1:2*num_qubits]
    f11 = rcr[1:nullity, num_qubits+1:num_qubits+nullity]
    z3 = f11+v1*transpose(v2)

    top_right_c2 = get_top_right_c2_matrix(v1, z1, z3, nullity, num_qubits)
    top_right_c4 = get_top_right_c4_matrix(v2, z2, nullity, num_qubits)

    c_for_current_clifford = identity_matrix(GF(2), 2*num_qubits)
    h_for_current_clifford = zero_matrix(GF(2), 2*num_qubits, 1)
    current_clifford = get_clifford_operator(c_for_current_clifford, h_for_current_clifford)
    current_clifford =
        push_linear_transformation_and_return_clifford!(circuit, current_clifford, r1)
    current_clifford =
        push_phase_gates_and_return_clifford!(circuit, current_clifford, top_right_c2)
    current_clifford = push_hadamard_for_c3_and_return_clifford!(circuit, current_clifford,
        num_qubits-nullity)
    current_clifford =
        push_phase_gates_and_return_clifford!(circuit, current_clifford, top_right_c4)
    current_clifford = push_linear_transformation_and_return_clifford!(circuit,
        current_clifford, transpose(r2))
    return current_clifford
end

function get_r2_matrix(nullity::Integer, null_basis::gfp_mat, num_qubits::Integer)
    num_additional_columns = num_qubits-nullity
    additional_columns = zero_matrix(GF(2), num_qubits, num_additional_columns)
    r2 = hcat(null_basis, additional_columns)
    r2_rank = rank(r2)
    while r2_rank != num_qubits
        for j = nullity+1:num_qubits
            for i = 1:num_qubits
                r2[i, j] = rand(GF(2))
            end
        end
        r2_rank = rank(r2)
    end
    return r2
end

function get_r1_matrix(r2_matrix::gfp_mat, g_prime::gfp_mat, nullity::Integer)
    num_qubits = nrows(r2_matrix)
    prod = g_prime*r2_matrix
    additional_columns = zero_matrix(GF(2), num_qubits, nullity)
    r1 = hcat(additional_columns, prod[1:num_qubits, nullity+1:num_qubits])
    r1_rank = rank(r1)
    while r1_rank != num_qubits
        for j = 1:nullity
            for i = 1:num_qubits
                r1[i, j] = rand(GF(2))
            end
        end
        r1_rank = rank(r1)
    end
    return r1
end

function get_rcr_matrix(r1::gfp_mat, r2::gfp_mat, clifford::CliffordOperator)
    num_qubits = nrows(r1)
    r_left = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    r_left[1:num_qubits, 1:num_qubits] = transpose(r1)
    r_left[num_qubits+1:2*num_qubits, num_qubits+1:2*num_qubits] = inv(r1)
    r_right = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    r_right[1:num_qubits, 1:num_qubits] = r2
    r_right[num_qubits+1:2*num_qubits, num_qubits+1:2*num_qubits] = transpose(inv(r2))
    rcr = r_left*clifford.c_bar[1:2*num_qubits, 1:2*num_qubits]*r_right
    return rcr
end

function get_top_right_c2_matrix(v1::gfp_mat, z1::gfp_mat, z3::gfp_mat, nullity::Integer,
    num_qubits::Integer)
    
    top_right_c2 = zero_matrix(GF(2), num_qubits, num_qubits)
    top_right_c2[1:nullity, 1:nullity] = z3
    top_right_c2[1:nullity, nullity+1:num_qubits] = v1
    top_right_c2[nullity+1:num_qubits, 1:nullity] = transpose(v1)
    top_right_c2[nullity+1:num_qubits, nullity+1:num_qubits] = z1
    return top_right_c2
end

function get_c3_matrix(nullity::Integer, num_qubits::Integer)
    rank = num_qubits-nullity
    c3 = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    c3[1:nullity, 1:nullity] = identity_matrix(GF(2), nullity)
    c3[nullity+1:num_qubits, num_qubits+nullity+1:2*num_qubits] =
        identity_matrix(GF(2), rank)
    c3[num_qubits+1:num_qubits+nullity, num_qubits+1:num_qubits+nullity] =
        identity_matrix(GF(2), nullity)
    c3[num_qubits+nullity+1:2*num_qubits, nullity+1:num_qubits] =
        identity_matrix(GF(2), rank)
    return c3
end

function get_top_right_c4_matrix(v2::gfp_mat, z2::gfp_mat, nullity::Integer,
    num_qubits::Integer)
    
    top_right_c4 = zero_matrix(GF(2), num_qubits, num_qubits)
    top_right_c4[1:nullity, nullity+1:num_qubits] = v2
    top_right_c4[nullity+1:num_qubits, 1:nullity] = transpose(v2)
    top_right_c4[nullity+1:num_qubits, nullity+1:num_qubits] = z2
    return top_right_c4
end

function push_linear_transformation_and_return_clifford!(circuit::QuantumCircuit,
        current_clifford::CliffordOperator, r::gfp_mat)
    num_qubits = nrows(r)
    r_copy = deepcopy(r)
    for j_column = 1:num_qubits
        if r_copy[j_column, j_column] != 1
            add_swap_gate_for_linear_transformation!(circuit, r_copy, j_column)
        end
        add_control_x_gates_for_linear_transformation!(circuit, r_copy, j_column)
    end
    return get_clifford_for_linear_transformation(current_clifford, num_qubits, r)
end

function add_swap_gate_for_linear_transformation!(circuit::QuantumCircuit, r::gfp_mat,
    j_column::Integer)
    
    i_row = j_column+1
    found_non_zero_entry = false
    while !found_non_zero_entry
        if r[i_row, j_column] == 0
            i_row += 1
        else
            swap_rows!(r, i_row, j_column)
            push_gate!(circuit, control_x(i_row, j_column))
            push_gate!(circuit, control_x(j_column, i_row))
            push_gate!(circuit, control_x(i_row, j_column))
            found_non_zero_entry = true
        end
    end
end

function add_control_x_gates_for_linear_transformation!(circuit::QuantumCircuit, r::gfp_mat,
    j_column::Integer)
    
    iter = Iterators.filter(i_row -> i_row != j_column, 1:nrows(r))
    for i_row = iter
        if r[i_row, j_column] == 1
            add_row!(r, 1, j_column, i_row)
            push_gate!(circuit, control_x(j_column, i_row))
        end
    end
end

function get_clifford_for_linear_transformation(current_clifford::CliffordOperator,
    num_qubits::Integer, r::gfp_mat)

    new_c = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    new_c[1:num_qubits, 1:num_qubits] = inv(transpose(r))
    new_c[num_qubits+1:2*num_qubits, num_qubits+1:2*num_qubits] = r
    new_h = zero_matrix(GF(2), 2*num_qubits, 1)
    new_clifford = get_clifford_operator(new_c, new_h)
    current_clifford = current_clifford*new_clifford
    return current_clifford
end

function push_hadamard_for_c3_and_return_clifford!(circuit::QuantumCircuit,
        current_clifford::CliffordOperator, g_prime_rank::Integer)
    num_qubits = circuit.qubit_count
    for i in num_qubits-g_prime_rank+1:num_qubits
        push_gate!(circuit, hadamard(i))
    end
    c_new = get_c3_matrix(num_qubits-g_prime_rank, num_qubits)
    h_new = zero_matrix(GF(2), 2*num_qubits, 1)
    new_clifford = get_clifford_operator(c_new, h_new)
    current_clifford = current_clifford*new_clifford
    return current_clifford
end

function push_phase_gates_and_return_clifford!(circuit::QuantumCircuit,
    current_clifford::CliffordOperator, upper_right_matrix::gfp_mat)
    
    gate_list = []
    num_qubits = nrows(upper_right_matrix)
    p = get_p_matrix(num_qubits)
    c = identity_matrix(GF(2), 2*num_qubits)
    h = zero_matrix(GF(2), 2*num_qubits, 1)
    clifford = get_clifford_operator(c, h)
    for j = 2:num_qubits
        for i = 1:j-1
            if upper_right_matrix[i, j] == 1
                push!(gate_list, control_x(i, j))
                push!(gate_list, phase(j))
                push!(gate_list, control_x(i, j))
                a = zero_matrix(GF(2), 2*num_qubits, 1)
                a[i, 1] = 1
                a[j, 1] = 1
                c_new = identity_matrix(GF(2), 2*num_qubits)+a*transpose(a)*p
                h_new = zero_matrix(GF(2), 2*num_qubits, 1)
                clifford_new = get_clifford_operator(c_new, h_new)
                clifford = clifford_new*clifford
            end
        end
    end
    for i = 1:num_qubits
        if upper_right_matrix[i, i] != clifford.c_bar[i, num_qubits+i]
            push!(gate_list, phase(i))
            a = zero_matrix(GF(2), 2*num_qubits, 1)
            a[i, 1] = 1
            c_new = identity_matrix(GF(2), 2*num_qubits)+a*transpose(a)*p
            h_new = zero_matrix(GF(2), 2*num_qubits, 1)
            clifford_new = get_clifford_operator(c_new, h_new)
            clifford = clifford_new*clifford
        end
    end
    iter = Iterators.reverse(gate_list)
    for gate = iter
        push_gate!(circuit, gate)
    end
    return current_clifford*clifford
end

function get_p_matrix(num_qubits::Integer)
    u = zero_matrix(GF(2), 2*num_qubits, 2*num_qubits)
    u[1:num_qubits, num_qubits+1:2*num_qubits] = identity_matrix(GF(2), num_qubits)
    p = u+transpose(u)
    return p
end

function push_h_matrix!(circuit::QuantumCircuit, current_clifford::CliffordOperator,
    target_clifford::CliffordOperator)
    
    num_qubits = circuit.qubit_count
    p = get_p_matrix(num_qubits)
    current_h = current_clifford.h_bar[1:2*num_qubits, 1]
    target_h = target_clifford.h_bar[1:2*num_qubits, 1]
    a = p*(current_h+target_h)
    push_gates_for_pauli!(circuit, a, num_qubits)
end

function push_gates_for_pauli!(circuit::QuantumCircuit, a::gfp_mat, num_qubits::Integer)
    for (i_qubit, apply_z) in enumerate(a[1:num_qubits, 1])
        if apply_z == 1
            push_gate!(circuit, phase(i_qubit))
            push_gate!(circuit, phase(i_qubit))
        end
    end
    for (i_qubit, apply_x) in enumerate(a[num_qubits+1:2*num_qubits, 1])
        if apply_x == 1
            push_gate!(circuit, hadamard(i_qubit))
            push_gate!(circuit, phase(i_qubit))
            push_gate!(circuit, phase(i_qubit))
            push_gate!(circuit, hadamard(i_qubit))
        end
    end
end
