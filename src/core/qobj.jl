"""
A Ket represents a *quantum wavefunction* and is mathematically equivalent to a column vector of complex values. The norm of a Ket should always be unity.  
# Fields
- `data` -- the stored values.
# Examples
Although NOT the preferred way, one can directly build a Ket object by passing a column vector as the initializer. 
```jldoctest
julia> using Snowflake

julia> ψ = Snowflake.Ket([1.0; 0.0; 0.0])
3-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


```
A better way to initialize a Ket is to use a pre-built basis such as the `fock` basis. See [`fock`](@ref) for further information on this function. 
```jldoctest
julia> ψ = Snowflake.fock(2, 3)
3-element Ket{ComplexF64}:
0.0 + 0.0im
0.0 + 0.0im
1.0 + 0.0im


```
"""
struct Ket{T<:Complex}
    data::Vector{T} 
end

# overload constructor to enable initilization from Real-valued array
Ket(x::Vector{T}) where {T<:Real} = Ket{Complex{T}}(convert(Array{Complex{T},1},x))

# overload constructor to enable initialization from Integer-valued array
# default output is Ket{ComplexF64}
Ket(x::Vector{T},S::Type{<:Complex}=ComplexF64) where {T<:Integer}=Ket(Vector{S}(x))

function Base.show(io::IO, x::Ket)
    println(io, "$(length(x.data))-element Ket{$(eltype(x.data))}:")
    for val in x.data
        println(io, val)
    end
end

Base.length(x::Ket) = Base.length(x.data)

"""
A structure representing a Bra (i.e. a row vector of complex values). A Bra is created as the complex conjugate of a Ket.
# Fields
- `data` -- the stored values.
# Examples
```jldoctest
julia> ψ = Snowflake.fock(1, 3)
3-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im


julia> _ψ = Snowflake.Bra(ψ)
3-element Bra{ComplexF64}:
0.0 - 0.0im
1.0 - 0.0im
0.0 - 0.0im


julia> _ψ * ψ    # A Bra times a Ket is a scalar
1.0 + 0.0im

julia> ψ*_ψ     # A Ket times a Bra is an operator
(3, 3)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
```
"""
struct Bra{T<:Complex}
    data::LinearAlgebra.Adjoint{T,Vector{T}}
    # constructor overload from Ket{Complex{T}}
    Bra(x::Ket{T}) where {T<:Complex} = new{T}(adjoint(x.data))
    # This constructor is used when a Bra is multiplied by an Operator
    Bra(x::LinearAlgebra.Adjoint{T,Vector{T}}) where {T<:Complex} = new{T}(x) 
end

function Base.show(io::IO, x::Bra)
    println(io, "$(length(x.data))-element Bra{$(eltype(x.data))}:")
    for val in x.data
        println(io, val)
    end
end

"""
A structure representing a quantum operator (i.e. a complex matrix).
# Fields
- `data` -- the complex matrix.

# Examples
```jldoctest
julia> z = Snowflake.Operator([1.0 0.0;0.0 -1.0])
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    -1.0 + 0.0im

```
Alternatively:
```jldoctest
julia> z = Snowflake.sigma_z()  #sigma_z is a defined function in Snowflake
(2,2)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 0.0im    .
.    -1.0 + 0.0im

julia> z = Snowflake.DiagonalOperator([1.0+im,1.0,1.0,0.0-im])
(4,4)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 1.0im    .    .    .
.    1.0 + 0.0im    .    .
.    .    1.0 + 0.0im    .
.    .    .    0.0 - 1.0im


julia> z = Snowflake.DiagonalOperator([1.0+im,1.0,1.0,0.0-im])
(4,4)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 1.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 - 1.0im

```
"""
struct Operator{T<:Complex}
    data::Matrix{T}
end

# Constructor from Real-valued Matrix
Operator(x::Matrix{T}) where {T<:Real} = Operator(convert(Matrix{Complex{T}},x) )

# Constructor from Integer-valued Matrix
# default output is Operator{ComplexF64}
Operator(x::Matrix{T},S::Type{<:Complex}=ComplexF64) where {T<:Integer} = Operator(Matrix{S}(x))

# Constructor from adjoint(Operator{T})
Operator(x::LinearAlgebra.Adjoint{T,Matrix{T}}) where {T<:Complex} = Operator{T}(x) 

get_matrix(op::Operator) = op.data

abstract type AbstractOperator end

"""
A structure representing a diagonal quantum operator (i.e. a complex matrix, with non-zero elements all lying on the diagonal).

# Examples
```jldoctest
julia> z = Snowflake.DiagonalOperator([1.0,-1.0])
(2,2)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 0.0im    .
.    -1.0 + 0.0im

julia> z = Snowflake.DiagonalOperator([1.0+im,1.0,1.0,0.0-im])
(4,4)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 1.0im    .    .    .
.    1.0 + 0.0im    .    .
.    .    1.0 + 0.0im    .
.    .    .    0.0 - 1.0im

```
"""
struct DiagonalOperator{N,T<:Complex}<:AbstractOperator
    data::SVector{N,T}
end

# Constructor from Real-valued Vector
DiagonalOperator(x::Vector{T}) where {T<:Real} = DiagonalOperator(convert(SVector{length(x),Complex{T}},x) )

# Constructor from Complex-valued Vector
DiagonalOperator(x::Vector{T}) where {T<:Complex} = DiagonalOperator(convert(SVector{length(x),T},x) )

# Constructor from Integer-valued Vector
# default output is Operator{ComplexF64}
DiagonalOperator(x::Vector{T},S::Type{<:Complex}=ComplexF64) where {T<:Integer} = DiagonalOperator(Vector{S}(x))

# Constructor from adjoint(DiagonalOperator{T})
DiagonalOperator(x::LinearAlgebra.Adjoint{T,SVector{N,T}}) where {T<:Complex,N} = DiagonalOperator{N,T}(x) 

# Construction of Operator using DiagonalOperator{N,T}
function Operator{T}(diag_op::DiagonalOperator{N,T}) where {N,T<:Complex} 
    op_matrix=  zeros(T,N,N)

    for i in 1:N
        op_matrix[i,i]=diag_op.data[i]
    end
    return Operator{T}(op_matrix) 
end

Operator(diag_op::DiagonalOperator{N,T}) where {N,T<:Complex}=  Operator{T}(diag_op)

function Base.getindex(diag_op::DiagonalOperator{N,T}, i::Integer, j::Integer) where {N,T<:Complex}
    if j == i
        return diag_op.data[i]
    else
        return T(0.)
    end
end

"""
A structure representing a anti-diagonal quantum operator (i.e. a complex matrix, with non-zero elements all lying on the cross-diagonal).

# Examples
```jldoctest
julia> Snowflake.AntiDiagonalOperator([1,2])
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    2.0 + 0.0im    .

```
"""
struct AntiDiagonalOperator{N,T<:Complex}<:AbstractOperator
    data::SVector{N,T}

    function AntiDiagonalOperator(
        x::Union{
            Vector{T},
            SVector{N,T},
            }
        ) where {N,T<:Complex}
        if Val(N)!=Val(2)
            throw(DomainError("$(:AntiDiagonalOperator) only implemented for single target (N=2). Received N=$N"))
        else
            return new{N,T}(x)
        end
    end
end


# Constructor from Integer-valued Vector
# default output is AntiDiagonalOperator{N,ComplexF64}
AntiDiagonalOperator(x::Vector{T},S::Type{<:Complex}=ComplexF64) where {T<:Integer} = 
    AntiDiagonalOperator(convert(SVector{length(x),S},x) )

# Constructor from Real-valued Vector
AntiDiagonalOperator(x::Vector{T}) where {T<:Real} = AntiDiagonalOperator(convert(SVector{length(x),Complex{T}},x) )

# Constructor from Complex-valued Vector
AntiDiagonalOperator(x::Vector{T}) where {T<:Complex} = AntiDiagonalOperator(convert(SVector{length(x),T},x) )

# Constructor from adjoint(AntiDiagonalOperator{T})
AntiDiagonalOperator(x::LinearAlgebra.Adjoint{T,SVector{N,T}}) where {T<:Complex,N} = AntiDiagonalOperator{N,T}(x) 

# Construction of Operator from AntiDiagonalOperator{N,T}
function Operator{T}(anti_diag_op::AntiDiagonalOperator{N,T}) where {N,T<:Complex} 
    op_matrix=  zeros(T,N,N)

    nrow=N
    ncol=nrow
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            if ncol-j+1 == i
                op_matrix[i,j]=anti_diag_op.data[i]
            end
        end
    end
    return Operator{T}(op_matrix) 
end

Operator(anti_diag_op::AntiDiagonalOperator{N,T}) where {N,T<:Complex}=  Operator{T}(anti_diag_op)

function Base.getindex(anti_diag_op::AntiDiagonalOperator{N,T}, i::Integer, j::Integer) where {N,T<:Complex}
    if N-j+1 == i
        return anti_diag_op.data[i]
    else
        return T(0.)
    end
end

"""
    Base.adjoint(x)

Compute the adjoint (a.k.a. conjugate transpose) of a Ket, a Bra, or an Operator.
"""
Base.adjoint(x::Ket) = Bra(x)
Base.adjoint(x::Bra) = Ket(adjoint(x.data))
Base.adjoint(A::Operator) = Operator(adjoint(A.data))
Base.adjoint(A::AbstractOperator) = typeof(A)(adjoint(A.data))

Base.adjoint(A::AntiDiagonalOperator{N,T}) where {N,T<:Complex}=
    AntiDiagonalOperator(SVector{N,T}(reverse(adjoint(A.data))))


"""
    is_hermitian(A::Operator)

Determine if Operator `A` is Hermitian (i.e. self-adjoint).

# Examples
```jldoctest
julia> Y = sigma_y()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    0.0 - 1.0im
    0.0 + 1.0im    .


julia> is_hermitian(Y)
true

julia> P = sigma_p()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    0.0 + 0.0im    .


julia> is_hermitian(P)
false

```
"""
is_hermitian(A::Operator) = LinearAlgebra.ishermitian(A.data)

is_hermitian(A::AbstractOperator)    = LinearAlgebra.ishermitian(Operator(A).data)

Base.:*(alpha::Number, x::Ket) = Ket(alpha * x.data)
Base.:isapprox(x::Ket, y::Ket; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)
Base.:isapprox(x::Bra, y::Bra; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)
Base.:isapprox(x::Operator{T}, y::Operator{T}; atol::Real=1.0e-6) where {T<:Complex}= isapprox(x.data, y.data, atol=atol)

# generic cases
Base.:isapprox(x::AbstractOperator, y::Operator; atol::Real=1.0e-6) = isapprox(Operator(x), y, atol=atol)
Base.:isapprox(x::Operator, y::AbstractOperator; atol::Real=1.0e-6) = isapprox(x, Operator(y), atol=atol)
Base.:isapprox(x::AbstractOperator, y::AbstractOperator; atol::Real=1.0e-6) = isapprox(Operator(x), Operator(y), atol=atol)

# specializations
Base.:isapprox(x::DiagonalOperator, y::DiagonalOperator; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)
Base.:isapprox(x::AntiDiagonalOperator, y::AntiDiagonalOperator; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)

Base.:isapprox(x::AntiDiagonalOperator, y::Operator; atol::Real=1.0e-6) = isapprox(Operator(x), y, atol=atol)
Base.:isapprox(x::Operator, y::AntiDiagonalOperator; atol::Real=1.0e-6) = isapprox(x, Operator(y), atol=atol)

Base.:isapprox(x::AntiDiagonalOperator, y::AntiDiagonalOperator; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)


Base.:-(x::Ket) = -1.0 * x
Base.:-(x::Ket, y::Ket) = Ket(x.data - y.data)
Base.:*(x::Bra, y::Ket) = x.data * y.data
Base.:+(x::Ket, y::Ket) = Ket(x.data + y.data)
Base.:*(x::Ket, y::Bra) = Operator(x.data * y.data)
Base.:*(M::Operator, x::Ket) = Ket(M.data * x.data)
Base.:*(x::Bra, M::Operator) = Bra(x.data * M.data)

Base.:*(M::AbstractOperator, x::Ket) = Ket(Operator(M).data * x.data)
Base.:*(x::Bra, M::AbstractOperator) = Bra(x.data * Operator(M).data)

Base.:*(A::Operator, B::Operator) = Operator(A.data * B.data)

# generic cases
Base.:*(A::AbstractOperator, B::Operator) = Operator(A) * B
Base.:*(A::Operator, B::AbstractOperator) = A * Operator(B)
Base.:*(A::AbstractOperator, B::AbstractOperator) = Operator(A) * Operator(B)

# specializations
Base.:*(A::DiagonalOperator{N,T}, B::DiagonalOperator{N,T}) where {N,T<:Complex} =
    DiagonalOperator(SVector{N,T}([a*b for (a,b) in zip(A.data,B.data)]))
Base.:*(A::AntiDiagonalOperator{N,T}, B::AntiDiagonalOperator{N,T}) where {N,T<:Complex} =
    DiagonalOperator(SVector{N,T}([a*b for (a,b) in zip(A.data,reverse(B.data))]))

Base.:*(A::AntiDiagonalOperator, B::Operator) = Operator(A) * B
Base.:*(A::Operator, B::AntiDiagonalOperator) = A * Operator(B)

Base.:*(A::AntiDiagonalOperator{N,T}, B::AntiDiagonalOperator{N,T}) where {N,T<:Complex} =
    DiagonalOperator(SVector{N,T}([a*b for (a,b) in zip(A.data,reverse(B.data))]))

Base.:*(A::AntiDiagonalOperator, B::DiagonalOperator) = Operator(A) * Operator(B)

Base.:*(s::Number, A::Operator) = Operator(s*A.data)
Base.:*(s::Number, A::AbstractOperator) = typeof(A)(s*A.data)

Base.:*(s::Number, A::AntiDiagonalOperator) = AntiDiagonalOperator(s*A.data)


Base.:+(A::Operator, B::Operator) = Operator(A.data+ B.data)
Base.:-(A::Operator, B::Operator) = Operator(A.data- B.data)

# generic cases
Base.:+(A::AbstractOperator, B::Operator) = Operator(A) + B
Base.:+(A::Operator, B::AbstractOperator) = A + Operator(B)
Base.:+(A::AbstractOperator, B::AbstractOperator) = Operator(A) + Operator(B)

Base.:-(A::AbstractOperator, B::Operator) = Operator(A) - B
Base.:-(A::Operator, B::AbstractOperator) = A - Operator(B)
Base.:-(A::AbstractOperator, B::AbstractOperator) = Operator(A) - Operator(B)

# specializations
Base.:+(A::DiagonalOperator, B::DiagonalOperator) = DiagonalOperator(A.data+B.data)
Base.:-(A::DiagonalOperator, B::DiagonalOperator) = DiagonalOperator(A.data-B.data)

Base.:+(A::AntiDiagonalOperator, B::AntiDiagonalOperator) = AntiDiagonalOperator(A.data+B.data)
Base.:-(A::AntiDiagonalOperator, B::AntiDiagonalOperator) = AntiDiagonalOperator(A.data-B.data)


Base.length(x::Union{Ket, Bra}) = length(x.data)

"""
    exp(A::Operator)

Compute the matrix exponential of `Operator` `A`.

# Examples
```jldoctest
julia> X = sigma_x()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


julia> x_rotation_90_deg = exp(-im*π/4*X)
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.7071067811865477 + 0.0im    0.0 - 0.7071067811865475im
0.0 - 0.7071067811865475im    0.7071067811865477 + 0.0im


```
"""
Base.exp(A::Operator) = Operator(exp(A.data))

Base.exp(A::AbstractOperator) = exp(Operator(A))

Base.exp(A::DiagonalOperator) = DiagonalOperator([exp(a) for a in Vector(A.data)])

"""
    Base.getindex(A::Operator, m::Int64, n::Int64)

Return the element at row `m` and column `n` of Operator `A`.
"""
Base.getindex(A::Operator, m::Int64, n::Int64) = Base.getindex(A.data, m, n)

"""
    eigen(A::Operator)

Compute the eigenvalue decomposition of Operator `A` and return an `Eigen`
factorization object `F`. Eigenvalues are found in `F.values` while eigenvectors are
found in the matrix `F.vectors`. Each column of this matrix corresponds to an eigenvector.
The `i`th eigenvector is extracted by calling `F.vectors[:, i]`.

# Examples
```jldoctest
julia> X = sigma_x()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .

julia> F = eigen(X);

julia> eigenvalues = F.values
2-element Vector{Float64}:
 -1.0
  1.0

julia> eigenvector_1 = F.vectors[:, 1]
2-element Vector{ComplexF64}:
 -0.7071067811865475 + 0.0im
  0.7071067811865475 + 0.0im
```
"""
eigen(A::Operator) = LinearAlgebra.eigen(A.data)

eigen(A::AbstractOperator) = LinearAlgebra.eigen(Operator(A).data)

"""
    tr(A::Operator)

Compute the trace of Operator `A`.

# Examples
```jldoctest
julia> I = eye()
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im


julia> trace = tr(I)
2.0 + 0.0im

```
"""
tr(A::Operator)=LinearAlgebra.tr(A.data)

"""
    expected_value(A::Operator, psi::Ket)

Compute the expectation value ⟨`ψ`|`A`|`ψ`⟩ given Operator `A` and Ket |`ψ`⟩.

# Examples
```jldoctest
julia> ψ = Ket([0.0; 1.0])
2-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im


julia> A = sigma_z()
(2,2)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 0.0im    .
.    -1.0 + 0.0im


julia> expected_value(A, ψ)
-1.0 + 0.0im
```
"""
expected_value(A::Operator, psi::Ket) = (Bra(psi)*(A*psi))

expected_value(A::DiagonalOperator, psi::Ket) = (Bra(psi)*(Operator(A)*psi))


Base.:size(M::Operator) = size(M.data)

# iterator for Ket object
Base.iterate(x::Ket, state = 1) =
    state > length(x.data) ? nothing : (x.data[state], state + 1)

    """
    kron(x, y)

Compute the Kronecker product of two [`Kets`](@ref Ket) or two [`Operators`](@ref Operator).
More details about the Kronecker product can be found
[here](https://en.wikipedia.org/wiki/Kronecker_product). 

# Examples
```jldoctest
julia> ψ_0 = Ket([0.0; 1.0])
2-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im


julia> ψ_1 = Ket([1.0; 0.0])
2-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im


julia> ψ_0_1 = kron(ψ_0, ψ_1)
4-element Ket{ComplexF64}:
0.0 + 0.0im
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im


julia> kron(sigma_x(), sigma_y())
(4, 4)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 - 1.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 - 1.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 1.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
```
"""
Base.kron(x::Ket, y::Ket) = Ket(kron(x.data, y.data))
Base.kron(x::Operator, y::Operator) = Operator(kron(x.data, y.data))

Base.kron(x::AbstractOperator, y::Operator) = kron(Operator(x), y)
Base.kron(x::Operator, y::AbstractOperator) = kron(x, Operator(y))
Base.kron(x::AbstractOperator, y::AbstractOperator) = kron(Operator(x), Operator(y))


"""
A structure representing a quantum multi-body system.
# Fields
- `hilbert_space_structure` -- a vector of integers specifying the local Hilbert space size for each "body" within the multi-body system. 
"""
struct MultiBodySystem
    hilbert_space_structure::Vector{Int}
    MultiBodySystem(n_body::Integer, hilbert_size_per_body::Integer) =
        new(fill(hilbert_size_per_body, n_body))
end

function Base.show(io::IO, system::MultiBodySystem)
    @printf(
        io,
        "Snowflake.Multibody system with %d bodies\n",
        length(system.hilbert_space_structure)
    )
    @printf(io, "   Hilbert space structure:\n")
    @printf(io, "   ")
    show(io, system.hilbert_space_structure)
end

"""
    get_embed_operator(op::Operator, target_body_index::Int, system::MultiBodySystem)

Uses a local operator (`op`), which is defined for a particular body (e.g. qubit) with index `target_body_index`, to build the corresponding operator for the Hilbert space of the multi-body system given by `system`. 
# Examples
```jldoctest
julia> system = Snowflake.MultiBodySystem(3,2)
Snowflake.Multibody system with 3 bodies
   Hilbert space structure:
   [2, 2, 2]

julia> x = Snowflake.sigma_x()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .

julia> X_1=Snowflake.get_embed_operator(x,1,system)
(8, 8)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}: 
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
```
"""
function get_embed_operator(op::Operator, target_body_index::Int, system::MultiBodySystem)
    n_body = length(system.hilbert_space_structure)
    @assert target_body_index <= n_body

    result = Operator(
        Matrix{eltype(op.data)}(
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
            result = kron(result, Operator(Matrix{eltype(op.data)}(I, n_hilbert, n_hilbert)))
        end
    end
    return result
end

get_embed_operator(op::DiagonalOperator, target_body_index::Int, system::MultiBodySystem)=
    get_embed_operator(Operator(op), target_body_index, system)

get_embed_operator(anti_diag_op::AntiDiagonalOperator, target_body_index::Int, system::MultiBodySystem)=
    get_embed_operator(Operator(anti_diag_op), target_body_index, system)

function Base.show(io::IO, x::Operator)
    println(io, "$(size(x.data))-element Snowflake.Operator:")
    println(io, "Underlying data $(typeof(x.data)):")
    (nrow, ncol) = size(x.data)
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            if j == 1
                print(io, "$(x.data[i, j])")
            else
                print(io, "    $(x.data[i, j])")
            end
        end
        println(io)
    end
end

function Base.show(io::IO, x::DiagonalOperator)
    println(io, "($(length(x.data)),$(length(x.data)))-element Snowflake.DiagonalOperator:")
    println(io, "Underlying data type: $(eltype(x.data)):")
    nrow=length(x.data) 
    ncol=nrow
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            if j == i
                if j==1
                    print(io, "$(x.data[i])")
                else
                    print(io, "    $(x.data[i])")
                end
            else
                if j==1
                    print(io, ".")
                else
                    print(io, "    .")
                end
            end
        end
        println(io)
    end
end

function get_matrix(op::DiagonalOperator{N,T}) where {N,T<:Complex}
    matrix=zeros(T,N,N)
    nrow=length(op.data) 
    ncol=nrow
    for i in 1:nrow
        for j in 1:ncol
            if i == j
                matrix[i,j]= op.data[i]
            end
        end
    end
    return matrix
end

function Base.show(io::IO, x::AntiDiagonalOperator)
    println(io, "($(length(x.data)),$(length(x.data)))-element Snowflake.AntiDiagonalOperator:")
    println(io, "Underlying data type: $(eltype(x.data)):")
    nrow=length(x.data) 
    ncol=nrow
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            if ncol-j+1 == i
                print(io, "    $(x.data[i])")
            else
                print(io, "    .")
            end
        end
        println(io)
    end
end

function get_matrix(op::AntiDiagonalOperator{N,T}) where {N,T<:Complex}
    matrix=zeros(T,N,N)
    nrow=length(op.data) 
    ncol=nrow
    for i in 1:nrow
        for j in 1:ncol
            if ncol-j+1 == i
                matrix[i,j]= op.data[i]
            end
        end
    end
    return matrix
end

"""
    get_num_qubits(x::Operator)

Returns the number of qubits associated with an `Operator`.
# Examples
```jldoctest
julia> ρ = Operator([1. 0.
                     0. 0.])
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im

julia> get_num_qubits(ρ)
1

```
"""
function get_num_qubits(x::Operator)
    (num_rows, num_columns) = size(x)
    if num_rows != num_columns
        throw(ErrorException("Operator is not square"))
    end
    qubit_count = log2(num_rows)
    if mod(qubit_count, 1) != 0
        throw(DomainError(qubit_count,
            "Operator does not correspond to an integer number of qubits"))
    end
    return Int(qubit_count)
end

"""
    get_num_qubits(x::Union{Ket, Bra})

Returns the number of qubits associated with a `Ket` or a `Bra`.
# Examples
```jldoctest
julia> ψ = Ket([1., 0., 0., 0.])
4-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


julia> get_num_qubits(ψ)
2

```
"""
function get_num_qubits(x::Union{Ket, Bra})
    qubit_count = log2(length(x))
    if mod(qubit_count, 1) != 0
        throw(DomainError(qubit_count,
            "Ket or Bra does not correspond to an integer number of qubits"))
    end
    return Int(qubit_count)
end

"""
    get_num_bodies(x::Operator, hilbert_space_size_per_body=2)

Returns the number of bodies associated with an `Operator` given the
`hilbert_space_size_per_body`.
# Examples
```jldoctest
julia> ρ = Operator([1. 0. 0.
                     0. 0. 0.
                     0. 0. 0.])
(3, 3)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im

julia> get_num_bodies(ρ, 3)
1

```
"""
function get_num_bodies(x::Operator, hilbert_space_size_per_body=2)
    (num_rows, num_columns) = size(x)
    if num_rows != num_columns
        throw(ErrorException("Operator is not square"))
    end
    num_bodies = log(hilbert_space_size_per_body, num_rows)
    if mod(num_bodies, 1) != 0
        throw(DomainError(num_bodies,
            "Operator does not correspond to an integer number of bodies"))
    end
    return Int(num_bodies)
end

"""
    get_num_bodies(x::Union{Ket, Bra}, hilbert_space_size_per_body=2)

Returns the number of bodies associated with a `Ket` or a `Bra` given the
`hilbert_space_size_per_body`.
# Examples
```jldoctest
julia> ψ = Ket([1., 0., 0., 0., 0., 0., 0., 0., 0.])
9-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


julia> get_num_bodies(ψ, 3)
2

```
"""
function get_num_bodies(x::Union{Ket, Bra}, hilbert_space_size_per_body=2)
    num_bodies = log(hilbert_space_size_per_body, length(x))
    if mod(num_bodies, 1) != 0
        throw(DomainError(num_bodies,
            "Ket or Bra does not correspond to an integer number of bodies"))
    end
    return Int(num_bodies)
end

"""
    Snowflake.fock(i, hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the `i`th fock basis of a Hilbert space with size `hspace_size` as Snowflake.Ket, of default type ComplexF64.
# Examples
```jldoctest
julia> ψ = Snowflake.fock(0, 3)
3-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


julia> ψ = Snowflake.fock(1, 3)
3-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im


julia> ψ = Snowflake.fock(1, 3,ComplexF32) # specifying a type other than ComplexF64
3-element Ket{ComplexF32}:
0.0f0 + 0.0f0im
1.0f0 + 0.0f0im
0.0f0 + 0.0f0im
```
"""
function fock(i, hspace_size,T::Type{<:Complex}=ComplexF64)
    d = fill(T(0.0), hspace_size)
    d[i+1] = 1.0
    return Ket(d)
end

spin_up() = fock(0,2)
spin_down() = fock(1,2)

"""
    Snowflake.create(hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the bosonic creation operator for a Fock space of size `hspace_size`, of default type ComplexF64.
"""
function create(hspace_size,T::Type{<:Complex}=ComplexF64)
    a_dag = zeros(T, hspace_size,hspace_size)
    for i in 2:hspace_size
        a_dag[i,i-1]=sqrt((i-1.0))
    end
    return Operator(a_dag)
end

"""
    Snowflake.destroy(hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the bosonic annhilation operator for a Fock space of size `hspace_size`, of default type ComplexF64.
"""
function destroy(hspace_size,T::Type{<:Complex}=ComplexF64)
    a= zeros(T, hspace_size,hspace_size)
    for i in 2:hspace_size
        a[i-1,i]=sqrt((i-1.0))
    end
    return Operator(a)
end

"""
    Snowflake.number_op(hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the number operator for a Fock space of size `hspace_size`, of default type ComplexF64.
"""
function number_op(hspace_size,T::Type{<:Complex}=ComplexF64)
    n= zeros(T, hspace_size,hspace_size)
    for i in 2:hspace_size
        n[i,i]=i-1.0
    end
    return Operator(n)
end

"""
    Snowflake.coherent(alpha, hspace_size)

Returns a coherent state for the parameter `alpha` in a Fock space of size `hspace_size`. Note that |alpha|^2 is equal to the 
    photon number of the coherent state. 

    # Examples
```jldoctest
julia> ψ = Snowflake.coherent(2.0,20)
20-element Ket{ComplexF64}:
0.1353352832366127 + 0.0im
0.2706705664732254 + 0.0im
0.3827859860416437 + 0.0im
0.44200318416631873 + 0.0im
0.44200318416631873 + 0.0im
0.3953396664268989 + 0.0im
0.3227934859426707 + 0.0im
0.24400893961026582 + 0.0im
0.17254037586855772 + 0.0im
0.11502691724570517 + 0.0im
0.07274941014482605 + 0.0im
0.043869544940011405 + 0.0im
0.025328093580341972 + 0.0im
0.014049498479026656 + 0.0im
0.007509772823502764 + 0.0im
0.003878030010563634 + 0.0im
0.001939015005281817 + 0.0im
0.000940560432521708 + 0.0im
0.0004433844399679012 + 0.0im
0.00020343873336404819 + 0.0im


julia> Snowflake.expected_value(Snowflake.number_op(20),ψ)
3.99999979364864 + 0.0im
```
"""
function coherent(alpha, hspace_size)
    ψ = fock(0,hspace_size)
    for i  in 1:hspace_size-1
        ψ+=(alpha^i)/(sqrt(factorial(i)))*fock(i,hspace_size)
    end
    ψ = exp(-0.5*abs2(alpha))*ψ
    return ψ 
end

"""
    Snowflake.normalize!(x::Ket)

Normalizes Ket `x` such that its magnitude becomes unity.

```jldoctest
julia> ψ=Ket([1.,2.,4.])
3-element Ket{ComplexF64}:
1.0 + 0.0im
2.0 + 0.0im
4.0 + 0.0im

julia> normalize!(ψ)
3-element Ket{ComplexF64}:
0.2182178902359924 + 0.0im
0.4364357804719848 + 0.0im
0.8728715609439696 + 0.0im
```

"""
function normalize!(x::Ket)
    a = LinearAlgebra.norm(x.data,2)
    x = 1.0/a*x
    return x
end

"""
    get_measurement_probabilities(x::Ket{Complex{T}},
        [target_bodies::Vector{U},
        hspace_size_per_body::Union{U,Vector{U}}=2])::AbstractVector{T}
        where {T<:Real, U<:Integer}

Returns a vector listing the measurement probabilities of the `target_bodies` of `Ket` `x`.

The Hilbert space size per body can be specified by providing a `Vector` of `Integer` for
the `hspace_size_per_body` argument. The `Vector` must specify the Hilbert space size for
each body. If the space size is uniform, a single `Integer` can be given instead. If
only `x` is provided, the probabilities are provided for all the bodies.

The measurement probabilities are listed from the smallest to the largest computational
basis state. For instance, for a 2-qubit `Ket`, the probabilities are listed for 00, 01, 10,
and 11.
# Examples
The following example constructs a `Ket`, where the probability of measuring 00 is 50% and
the probability of measuring 10 is also 50%.
```jldoctest get_measurement_probabilities
julia> ψ = 1/sqrt(2)*Ket([1, 0, 1, 0])
4-element Ket{ComplexF64}:
0.7071067811865475 + 0.0im
0.0 + 0.0im
0.7071067811865475 + 0.0im
0.0 + 0.0im


julia> get_measurement_probabilities(ψ)
4-element Vector{Float64}:
 0.4999999999999999
 0.0
 0.4999999999999999
 0.0

```

For the same `Ket`, the probability of measuring qubit 2 and finding 0 is 100%.
```jldoctest get_measurement_probabilities
julia> target_qubit = [2];

julia> get_measurement_probabilities(ψ, target_qubit)
2-element Vector{Float64}:
 0.9999999999999998
 0.0

```
"""
function get_measurement_probabilities(x::Ket{Complex{T}})::AbstractVector{T} where T<:Real
    return real.(adjoint.(x) .* x)
end

function get_measurement_probabilities(x::Ket{Complex{T}},
    target_bodies::Vector{U},
    hspace_size_per_body::U = 2)::AbstractVector{T} where {T<:Real, U<:Integer}

    num_bodies = get_num_bodies(x, hspace_size_per_body)
    hspace_size_per_body_list = fill(hspace_size_per_body, num_bodies)
    return get_measurement_probabilities(x, target_bodies, hspace_size_per_body_list)
end

function get_measurement_probabilities(x::Ket{Complex{T}},
    target_bodies::Vector{U},
    hspace_size_per_body::Vector{U})::AbstractVector{T} where {T<:Real, U<:Integer}

    throw_if_targets_are_invalid(x, target_bodies, hspace_size_per_body)
    amplitudes = get_measurement_probabilities(x)
    num_amplitudes = length(amplitudes)
    num_target_amplitudes = get_num_target_amplitudes(target_bodies, hspace_size_per_body)
    if num_target_amplitudes == num_amplitudes
        return amplitudes
    else
        num_bodies = length(hspace_size_per_body)
        bitstring = zeros(U, num_bodies)
        target_amplitudes = zeros(T, num_target_amplitudes)
        for single_amplitude in amplitudes
            target_index = get_target_amplitude_index(bitstring, target_bodies,
                hspace_size_per_body)
            target_amplitudes[target_index] += single_amplitude
            increment_bitstring!(bitstring, hspace_size_per_body)
        end
        return target_amplitudes
    end
end

function throw_if_targets_are_invalid(x::Ket{Complex{T}},
    target_bodies::Vector{U},
    hspace_size_per_body::Vector{U}) where {T<:Real, U<:Integer}

    expected_ket_length = prod(hspace_size_per_body)
    if expected_ket_length != length(x)
        throw(ErrorException("the hspace_size_per_body is incorrect for the provided ket"))
    end

    if isempty(target_bodies)
        throw(ErrorException("target_bodies is empty"))
    end

    if !allunique(target_bodies)
        throw(ErrorException("the elements of target_bodies must be unique"))
    end

    if !issorted(target_bodies)
        throw(ErrorException("target_bodies must be sorted in ascending order"))
    end

    num_bodies = length(hspace_size_per_body)
    if target_bodies[end] > num_bodies
        throw(ErrorException("elements of target_bodies cannot be greater than the "*
            "number of bodies"))
    end
end

function get_num_target_amplitudes(target_bodies::Vector{T},
    hspace_size_per_body::Vector{T}) where T<:Integer

    num_amplitudes = 1
    for target_index in target_bodies
        num_amplitudes *= hspace_size_per_body[target_index]
    end
    return num_amplitudes
end

function get_target_amplitude_index(bitstring::Vector{T}, target_bodies::Vector{T},
    hspace_size_per_body::Vector{T}) where T<:Integer

    amplitude_index = 1
    previous_base = 1
    for i_body in reverse(target_bodies)
        amplitude_index +=
            bitstring[i_body]*previous_base
        previous_base *= hspace_size_per_body[i_body]
    end
    return amplitude_index
end

function increment_bitstring!(bitstring::Vector{T},
    hspace_size_per_bit::Vector{T}) where T<:Integer

    num_bits = length(bitstring)
    i_bit = num_bits
    finished_updating = false
    while i_bit > 0 && !finished_updating
        if bitstring[i_bit] == hspace_size_per_bit[i_bit]-1
            bitstring[i_bit] = 0
            i_bit -= 1
        else
            bitstring[i_bit] += 1
            finished_updating = true
        end
    end
end

"""
    Snowflake.commute(A::Operator, B::Operator)

Returns the commutation of `A` and `B`.
```jldoctest
julia> σ_x = sigma_x()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


julia> σ_y = sigma_y()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    0.0 - 1.0im
    0.0 + 1.0im    .


julia> Snowflake.commute(σ_x,σ_y)
(2,2)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
0.0 + 2.0im    .
.    0.0 - 2.0im

```
"""
commute(A::Operator, B::Operator) = A*B-B*A

# generic cases
commute(A::AbstractOperator, B::Operator)= commute(Operator(A),B)
commute(A::Operator, B::AbstractOperator)= commute(A,Operator(B))

commute(A::AbstractOperator, B::AbstractOperator)= A*B-B*A 

commute(A::AntiDiagonalOperator, B::AntiDiagonalOperator)= A*B-B*A

commute(A::AntiDiagonalOperator, B::DiagonalOperator)= commute(Operator(A),Operator(B))
commute(A::DiagonalOperator, B::AntiDiagonalOperator)= commute(Operator(A),Operator(B))


"""
    Snowflake.anticommute(A::Operator, B::Operator)

Returns the anticommutation of `A` and `B`.
```jldoctest
julia> σ_x = Snowflake.sigma_x()
(2,2)-element Snowflake.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


julia> Snowflake.anticommute(σ_x,σ_x)
(2,2)-element Snowflake.DiagonalOperator:
Underlying data type: ComplexF64:
2.0 + 0.0im    .
.    2.0 + 0.0im

```
"""
anticommute(A::Operator, B::Operator)= A*B+B*A

# generic cases
anticommute(A::AbstractOperator, B::Operator)=anticommute(Operator(A),B)
anticommute(A::Operator, B::AbstractOperator)=anticommute(A,Operator(B))

anticommute(A::AbstractOperator, B::AbstractOperator)=A*B+B*A 


anticommute(A::DiagonalOperator, B::Operator)=anticommute(Operator(A),B)
anticommute(A::Operator, B::DiagonalOperator)=anticommute(A,Operator(B))

anticommute(A::DiagonalOperator, B::DiagonalOperator)=A*B+B*A

anticommute(A::AntiDiagonalOperator, B::Operator)=anticommute(Operator(A),B)
anticommute(A::Operator, B::AntiDiagonalOperator)=anticommute(A,Operator(B))

anticommute(A::AntiDiagonalOperator, B::AntiDiagonalOperator)=A*B+B*A

"""
    Snowflake.ket2dm(ψ)

Returns the density matrix corresponding to the pure state ψ.
"""
function ket2dm(ψ::Ket)
    return ψ*Bra(ψ)
end

"""
    Snowflake.fock_dm(i, hspace_size)

Returns the density matrix corresponding to the Fock base `i` defined in a Hilbert space of size `hspace_size`.

```jldoctest
julia> dm=Snowflake.fock_dm(0,2)
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im
```
"""
fock_dm(i::Int64, hspace_size::Int64) = ket2dm(fock(i,hspace_size))


function wigner(ρ::Operator, p::Real, q::Real)
    hilbert_size, _ = size(ρ.data)
    eta = q + p*im
    w = 0.0
    for m in 1:hilbert_size
        for n in 1:m
            if (n==m)
                w = w + real(ρ[m,n]*moyal(eta, m, n))
            else
                w = w + 2.0*real(ρ[m,n]*moyal(eta, m, n))
            end
        end
    end
    return w
end

"""
    Snowflake.moyal(m, n)

Returns the Moyal function `w_mn(eta)` for Fock states `m` and `n`.


"""
function moyal(eta, m,n)
    L = genlaguerre(4.0*abs2(eta),m-n, n)
    w_mn = 2.0*(-1)^n/pi*sqrt(factorial(big(n))/factorial(big(m)))*(2.0*conj(eta))^(m-n)*exp(-2.0*abs2(eta))*L
    return w_mn
end


"""
    Snowflake.genlaguerre(x, alpha, n)

Returns the generalized Laguerre polynomial of degree `n` for `x` using a recursive
method. See [https://en.wikipedia.org/wiki/Laguerre_polynomials](https://en.wikipedia.org/wiki/Laguerre_polynomials).
"""
function genlaguerre(x,alpha, n)
    result =0.0
    L_0 = 1
    L_1 = 1.0+alpha-x
    if (n==0)
        return L_0
    end
    if (n==1)
        return L_1
    end

    for k in 1:n-1
        result = (2.0*k+1.0+alpha-x)*L_1-(k+alpha)*L_0
        result = result/ (k+1.0)
        L_0 = L_1
        L_1 = result
    end        
    return result
end