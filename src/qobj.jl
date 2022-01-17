"""
A Ket represnts a *quantum wavefunction* and is mathematically equivalent to a column vector of complex values. The norm of a Ket should always be unity.  
**Fields**
- `data` -- the stored values.
# Examples
Although NOT the preferred way, one can directly build a Ket object by passing a column vector as the initializer. 
```jldoctest
julia> using Snowflake

julia> ψ = Snowflake.Ket([1.0; 0.0; 0.0])
3-element Ket:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
```
A better way to initialize a Ket is to use a pre-built basis such as `fock` basis. See `fock` for further information on this function. 
```jldoctest
julia> ψ = Snowflake.fock(2, 3)
3-element Ket:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im
```
"""
struct Ket
    data::Vector{Complex}
end

function Base.show(io::IO, x::Ket)
    println("$(length(x.data))-element Ket:")
    for val in x.data
        println(val)
    end
end

"""
A structure representing a Bra (i.e. a row vector of complex values). A Bra is created as the complex conjugate of a Ket.
**Fields**
- `data` -- the stored values.
# Examples
```jldoctest
julia> ψ = Snowflake.fock(2, 3)
3-element Ket:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im

julia> _ψ = Snowflake.Bra(ψ)
Bra(Any[0.0 - 0.0im 1.0 - 0.0im 0.0 - 0.0im])


julia> _ψ * ψ    # A Bra times a Ket is a scalar
1.0 + 0.0im

julia> ψ*_ψ     # A Ket times a Bra is an operator
        (3, 3)-element Snowflake.Operator:
        Underlying data Matrix{Complex} : 
                0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             1.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
```
"""
struct Bra
    data::LinearAlgebra.Adjoint{Any,Vector{Any}}
    Bra(x::Ket) = new(adjoint(x.data))
    # This construcor is used when a Bra is multiplied by an Operator
    Bra(x::LinearAlgebra.Adjoint{Any,Vector{Any}}) = new(x)
end

"""
A structure representing a quantum operator (i.e. a complex matrix).
**Fields**
- `data` -- the complex matrix.

# Examples
```jldoctest
julia> z = Snowflake.Operator([1.0 0.0;0.0 -1.0])
        (2, 2)-element Snowflake.Operator:
        Underlying data Matrix{Complex} : 
                1.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             -1.0 + 0.0im

```
Alternatively:
```jldoctest
julia> z = Snowflake.sigma_z()  #sigma_z is a defined function in Snowflake
        (2, 2)-element Snowflake.Operator:
        Underlying data Matrix{Complex} : 
                1.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             -1.0 + 0.0im
```
"""
struct Operator
    data::Matrix{Complex}
end

"""
A structure representing a quantum multi-body system.
**Fields**
- `hilbert_space_structure` -- a vector of integers specifying the local hilbert space size for each "body" within the multi-body system. 
"""
struct MultiBodySystem
    hilbert_space_structure::Vector{Int}
    MultiBodySystem(n_body, hilbert_size_per_body) =
        new(fill(hilbert_size_per_body, n_body))
end

function Base.show(io::IO, system::MultiBodySystem)
    @printf(io, "Snowflake.Multibody system with %d bodies\n", length(system.hilbert_space_structure))
    @printf(io, "   Hilbert space structure:\n")
    @printf(io, "   ")
    show(io, system.hilbert_space_structure)
end

"""
    Snowflake.get_embed_operator(op::Operator, target_body_index::Int, system::MultiBodySystem)

Uses a local operator (`op`) which is defined for a particular body (e.g. qubit) with index `target_body_index` to build the corresponding operator for the hilbert soace of the  multi-body system given by `system`. 
# Examples
```jldoctest
julia> system = Snowflake.MultiBodySystem(3,2)
Snowflake.Multibody system with 3 bodies
   Hilbert space structure:
   [2, 2, 2]

julia> x = Snowflake.sigma_x()
        (2, 2)-element Snowflake.Operator:
        Underlying data Matrix{Complex} : 
                0.0 + 0.0im             1.0 + 0.0im
                1.0 + 0.0im             0.0 + 0.0im

julia> X_1=Snowflake.get_embed_operator(x,1,system)
        (8, 8)-element Snowflake.Operator:
        Underlying data Matrix{Complex} : 
                0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             1.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             1.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             1.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             1.0 + 0.0im
                1.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             1.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             0.0 + 0.0im             1.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
                0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             1.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im             0.0 + 0.0im
```
"""
function get_embed_operator(op::Operator, target_body_index::Int, system::MultiBodySystem)
    n_body = length(system.hilbert_space_structure)
    @assert target_body_index <= n_body

    hilber_space_size = 1
    for hilbert_size_per_body in system.hilbert_space_structure
        hilber_space_size *= hilbert_size_per_body
    end

    result = Operator(
        Matrix{Complex}(
            I,
            system.hilbert_space_structure[1],
            system.hilbert_space_structure[1],
        ),
    )
    if (target_body_index == 1)
        result = op
    end

    for i_body = 2:n_body
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
    println(io, "\t$(size(x.data))-element Snowflake.Operator:")
    println(io, "\tUnderlying data $(typeof(x.data)) : ")
    (nrow, ncol) = size(x.data)
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            print(io, "\t\t$(x.data[i, j])")
        end
        println(io)
    end
end

Base.length(x::Ket) = Base.length(x.data)
Base.adjoint(x::Ket) = Bra(x)
Base.adjoint(x::Bra) = Ket(adjoint(x.data))
Base.:*(alpha::Number, x::Ket) = Ket(alpha * x.data)
Base.:isapprox(x::Ket, y::Ket) = isapprox(x.data, y.data)
Base.:isapprox(x::Bra, y::Bra) = isapprox(x.data, y.data)
Base.:-(x::Ket) = -1.0 * x
Base.:-(x::Ket, y::Ket) = Ket(x.data - y.data)
Base.:*(x::Bra, y::Ket) = x.data * y.data
Base.:+(x::Ket, y::Ket) = Ket(x.data + y.data)
Base.:*(x::Ket, y::Bra) = Operator(x.data * y.data)

Base.:*(M::Operator, x::Ket) = Ket(M.data * x.data)
Base.:*(x::Bra, M::Operator) = Bra(x.data * M.data)
Base.:size(M::Operator) = size(M.data)

# iterator for Ket object
Base.iterate(x::Ket, state = 1) =
    state > length(x.data) ? nothing : (x.data[state], state + 1)


Base.kron(x::Ket, y::Ket) = Ket(kron(x.data, y.data))
Base.kron(x::Operator, y::Operator) = Operator(kron(x.data, y.data))

"""
    Snowflake.fock(i, hspace_size)

Returns the `i`th fock basis of a Hilbert space with size `hspace_size` as Snowflake.Ket
# Examples
```jldoctest
julia> ψ = Snowflake.fock(1, 3)
3-element Ket:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


julia> ψ = Snowflake.fock(2, 3)
3-element Ket:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im
```
"""
function fock(i, hspace_size)
    d = fill(Complex(0.0), hspace_size)
    d[i] = 1.0
    return Ket(d)
end
