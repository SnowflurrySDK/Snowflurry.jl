using LinearAlgebra

export Bra, Ket, fock, MultiBodySystem, getEmbedOperator

struct Ket
    data::Vector{Complex}
end

function Base.show(io::IO, x::Ket)
    println("$(length(x.data))-element Ket:")
    for val in x.data
        println(val)
    end
end

struct Bra
    data::LinearAlgebra.Adjoint{Any,Vector{Complex}}
    Bra(x::Ket) = new(adjoint(x.data))
    Bra(x::LinearAlgebra.Adjoint{Any,Vector{Complex}}) = new(x)
end

struct Operator 
    data::Matrix{Complex}
end

struct MultiBodySystem
    hilbert_space_structure::Vector{Int}
    MultiBodySystem(n_body, hilbert_size_per_body) = new(fill(hilbert_size_per_body, n_body))
end

function getEmbedOperator(op::Operator, target_body_index::Int, system::MultiBodySystem)
    n_body = length(system.hilbert_space_structure)
    @assert target_body_index <= n_body

    hilber_space_size = 1
    for hilbert_size_per_body in system.hilbert_space_structure
        hilber_space_size *= hilbert_size_per_body
    end
    
    result = Operator(Matrix{Complex}(I, system.hilbert_space_structure[1], system.hilbert_space_structure[1]))
    if (target_body_index == 1) 
        result = op
    end

    for i_body in 2:n_body
        if (i_body == target_body_index)
            result = kron(result, op)
        else
            n_hilbert = system.hilbert_space_structure[i_body]
            result = kron(result, Operator(Matrix{Complex}(I, n_hilbert, n_hilbert)))
        end
    end
    return result
end


function Base.show(io::IO, x::Operator)
    println(io, "\t$(size(x.data))-element Iris.Operator:")
    println(io, "\tUnderlying data $(typeof(x.data)) : ")
    (nrow, ncol) = size(x.data)
    for i in range(1, stop=nrow)
        for j in range(1, stop=ncol)
            print(io, "\t\t$(x.data[i, j])")
        end
        println(io)
    end
end

Base.size(x::Ket) = Base.size(x.data)
Base.length(x::Ket) = Base.length(x.data)
Base.adjoint(x::Ket) = Bra(x)
Base.adjoint(x::Bra) = Ket(adjoint(x.data))
Base.:*(alpha::Number, x::Ket) = Ket(alpha * x.data)
Base.:isapprox(x::Ket, y::Ket)  = isapprox(x.data, y.data)
Base.:-(x::Ket) = -1.0 * x
Base.:-(x::Ket, y::Ket) = Ket(x.data - y.data)
Base.:*(x::Bra, y::Ket) = x.data * y.data
Base.:+(x::Ket, y::Ket) = Ket(x.data + y.data)
Base.:*(x::Ket, y::Bra) = Operator(x.data * y.data)

Base.:*(M::Operator, x::Ket) = Ket(M.data * x.data)
Base.:*(x::Bra, M::Operator) = Bra(x.data * M.data)

# iterator for Ket object
Base.iterate(x::Ket, state=1) = state > length(x.data) ? nothing : (x.data[state], state + 1)


Base.kron(x::Ket, y::Ket) = Ket(kron(x.data, y.data))
Base.kron(x::Operator, y::Operator) = Operator(kron(x.data, y.data))


function fock(hilbert_space_size, id)
    d = fill(Complex(0.0), hilbert_space_size)
    d[id] = 1.0
    return Ket(d)
end