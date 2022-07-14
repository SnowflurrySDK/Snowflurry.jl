"""
    CliffordOperator(c_bar::Matrix{GF2}, h_bar::Vector{GF2})

A Clifford operator which is represented using the approach of 
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).

The operator can be constructed using the ``\\bar{C}`` matrix and the ``\\bar{h}``
vector.
"""
struct CliffordOperator
    c_bar::Matrix{GF2}
    h_bar::Vector{GF2}

    function CliffordOperator(c_bar::Matrix{GF2}, h_bar::Vector{GF2})
        @assert size(c_bar,1) == size(c_bar,2)
        @assert size(c_bar,1) == size(h_bar, 1)
        @assert mod(size(h_bar, 1), 2) == 1
        new(c_bar, h_bar)
    end
end

"""
    get_clifford_operator(c::Matrix{GF2}, h::Vector{GF2})

Construct a Clifford operator using the matrix C and the vector h in the representation of 
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).
"""
function get_clifford_operator(c::Matrix{GF2}, h::Vector{GF2})
    c_bar = get_c_bar(c)
    h_bar = copy(h)
    push!(h_bar, 0)
    CliffordOperator(c_bar, h_bar)
end

function get_c_bar(c::Matrix{GF2})
    n = Int(size(c, 1)/2)
    u = zeros(GF2, 2*n, 2*n)
    for i = 1:n
        u[i, i+n] = 1
    end

    d = diag(transpose(c)*u*c)
    c_bar = zeros(GF2, 2*n+1, 2*n+1)
    c_bar[1:2*n+1, 1:2*n] = vcat(c, transpose(d))
    c_bar[2*n+1, 2*n+1] = 1
    return c_bar
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
    term_3 = diag(transpose(q1.c_bar)*triangular*q1.c_bar)
    h_bar = q1.h_bar+term_2+term_3
    return h_bar
end

function get_u_bar(q::CliffordOperator)
    n = Int((size(q.c_bar, 1)-1)/2)
    u_bar = zeros(GF2, 2*n+1, 2*n+1)
    for i = 1:n
        u_bar[i, i+n] = 1
    end
    u_bar[2*n+1,2*n+1] = 1
    return u_bar
end

function get_strictly_lower_triangular(m::Matrix)
    lower_triangular = copy(m)
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
    term_2 = diag(transpose(inv(q.c_bar))*triangular*inv(q.c_bar))
    h_bar = term_1+term_2
    return h_bar
end
