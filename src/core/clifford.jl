using GaloisFields

const GF = @GaloisField 2

"""
    CliffordOperator

A Clifford operator which is represented using the approach of 
[Dehaene and De Moor (2003)](https://doi.org/10.1103/PhysRevA.68.042318).
"""
struct CliffordOperator
    c_bar::Matrix{GF}
    h_bar::Vector{GF}

    function CliffordOperator(c::Matrix{GF}, h::Vector{GF})
        @assert size(c,1) == size(c,2)
        @assert size(c,1) == size(h, 1)
        @assert mod(size(h, 1), 2) == 0
        c_bar = get_c_bar(c)
        h_bar = copy(h)
        push!(h_bar, 0)
        new(c_bar, h_bar)
    end
end

function get_c_bar(c::Matrix{GF})
    n = Int(size(c, 1)/2)
    u = zeros(GF, 2*n, 2*n)
    for i = 1:n
        u[i, i+n] = 1
    end

    d = diag(transpose(c)*u*c)
    c_bar = zeros(GF, 2*n+1, 2*n+1)
    c_bar[1:2*n+1, 1:2*n] = vcat(c, transpose(d))
    c_bar[2*n+1, 2*n+1] = 1
    return c_bar
end
