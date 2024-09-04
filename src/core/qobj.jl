"""
A `Ket` represents a *quantum wavefunction* and is mathematically equivalent to a column vector of complex values. The norm of a Ket should always be unity.  
A `Ket` representing a system with a qubit count of \$n=2\$ has \$2^n\$ states. 
By convention, qubit 1 is the leftmost digit, followed by every subsequent qubit. 
Hence, a 2-qubit `Ket` has 4 complex-valued coefficients \$a_{ij}\$, each corresponding to state \$\\left|ij\\right\\rangle\$, in the following order:
```math
\\psi = \\begin{bmatrix}
    a_{00}  \\\\
    a_{10}  \\\\
    a_{01}  \\\\
    a_{11}  \\\\
    \\end{bmatrix}.
```

# Examples
A Ket can be initialized by using a pre-built basis such as the `fock` basis. See [`fock`](@ref) for further information on this function. 
```jldoctest
julia> ψ = fock(2, 4)
4-element Ket{ComplexF64}:
0.0 + 0.0im
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im


```

Although NOT the preferred way, one can also directly build a Ket object by passing a column vector as the initializer. 
```jldoctest
julia> using Snowflurry

julia> ψ = Ket([1.0; 0.0; 0.0; 0.0])
4-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


```
"""
struct Ket{T<:Complex}
    data::Vector{T}
end

# overload constructor to enable initilization from Real-valued array
Ket(x::Vector{T}) where {T<:Real} = Ket{Complex{T}}(convert(Array{Complex{T},1}, x))

# overload constructor to enable initialization from Integer-valued array
# default output is Ket{ComplexF64}
Ket(x::Vector{T}, S::Type{<:Complex} = ComplexF64) where {T<:Integer} = Ket(Vector{S}(x))

# overload constructor to enable initialization from Complex{Integer}-valued array
# default output is Ket{ComplexF64}
Ket(x::Vector{T}, S::Type{<:Complex} = ComplexF64) where {T<:Complex{Int}} =
    Ket(Vector{S}(x))

function Base.show(io::IO, x::Ket)
    println(io, "$(length(x.data))-element Ket{$(eltype(x.data))}:")
    for val in x.data
        println(io, val)
    end
end

Base.length(x::Ket) = Base.length(x.data)

function get_canonical_global_phase(Ψ::Complex)::Real
    return atan(imag(Ψ), real(Ψ))
end

function get_canonical_global_phase(ψ::Ket{Complex{T}})::T where {T<:Real}
    # Use the first non-zero element to determine the global phase of the ket
    for index in eachindex(ψ.data)
        element = ψ.data[index]
        if (!isapprox(element, 0; atol = sqrt(eps(T))))
            return get_canonical_global_phase(element)
        end
    end

    # If the matrix is zero, then define the global phase as 0
    return T(0)
end

"""

    compare_kets(ψ_0::Ket,ψ_1::Ket)

Checks for equivalence allowing for a global phase difference between two input kets.

# Examples
```jldoctest
julia> ψ_0 = Ket([1., 2., 3., 4.])
4-element Ket{ComplexF64}:
1.0 + 0.0im
2.0 + 0.0im
3.0 + 0.0im
4.0 + 0.0im


julia> δ = π/3 # phase offset
1.0471975511965976

julia> ψ_1 = exp(im * δ) * ψ_0
4-element Ket{ComplexF64}:
0.5000000000000001 + 0.8660254037844386im
1.0000000000000002 + 1.7320508075688772im
1.5000000000000004 + 2.598076211353316im
2.0000000000000004 + 3.4641016151377544im


julia> compare_kets(ψ_0, ψ_1)
true

julia> apply_instruction!(ψ_1, sigma_x(1))
4-element Ket{ComplexF64}:
1.5000000000000004 + 2.598076211353316im
2.0000000000000004 + 3.4641016151377544im
0.5000000000000001 + 0.8660254037844386im
1.0000000000000002 + 1.7320508075688772im


julia> compare_kets(ψ_0, ψ_1) # no longer equivalent after SigmaX gate
false

```
"""
function compare_kets(ψ_0::Ket, ψ_1::Ket)

    @assert length(ψ_0) == length(ψ_1) ("Input Kets must be of same dimension")
    θ_0 = get_canonical_global_phase(ψ_0)
    θ_1 = get_canonical_global_phase(ψ_1)

    δ = θ_0 - θ_1

    return isapprox(ψ_0, exp(im * δ) * ψ_1; atol = 1e-5)
end

"""
A structure representing a Bra (i.e., a row vector of complex values). A Bra is created as the complex conjugate of a Ket.

# Examples
```jldoctest
julia> ψ = fock(1, 3)
3-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im


julia> _ψ = Bra(ψ)
3-element Bra{ComplexF64}:
0.0 - 0.0im
1.0 - 0.0im
0.0 - 0.0im


julia> _ψ * ψ    # A Bra times a Ket is a scalar
1.0 + 0.0im

julia> ψ*_ψ     # A Ket times a Bra is an operator
(3, 3)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im


```
"""
struct Bra{T<:Complex}
    data::LinearAlgebra.Adjoint{T,Vector{T}}
    # constructor overload from Ket{Complex{T}}
    Bra(x::Ket{T}) where {T<:Complex} = new{T}(adjoint(x.data))
    # This constructor is used when a Bra is multiplied by an AbstractOperator
    Bra(x::LinearAlgebra.Adjoint{T,SVector{N,T}}) where {N,T<:Complex} = new{T}(x)
    # This constructor is used when a Bra is multiplied by a SparseOperator or initialized with adjoint of vector
    Bra(x::LinearAlgebra.Adjoint{T,Vector{T}}) where {T<:Complex} = new{T}(x)
end

function Base.show(io::IO, x::Bra)
    println(io, "$(length(x.data))-element Bra{$(eltype(x.data))}:")
    for val in x.data
        println(io, val)
    end
end

abstract type AbstractOperator end

"""
    SparseOperator{N,T<:Complex}<:AbstractOperator

A structure representing a quantum operator with a sparse (CSR) matrix representation, with element type T.
The equivalent dense matrix would have size NxN.

!!! warning 
    The `apply_operator()` method is not implemented for this operator type. Try using `DenseOperator` instead.

# Examples
```jldoctest
julia> z = SparseOperator([-1.0 1.0;0.0 -1.0])
(2, 2)-element Snowflurry.SparseOperator:
Underlying data ComplexF64:
 -1.0 + 0.0im   1.0 + 0.0im
       ⋅       -1.0 + 0.0im

```
"""
struct SparseOperator{N,T<:Complex} <: AbstractOperator
    data::SparseMatrixCSC{T,Int64}
end

function SparseOperator(x::SparseArrays.SparseMatrixCSC{T,Int64}) where {T<:Complex}
    @assert size(x)[1] == size(x)[2] "Input Matrix is not square"

    SparseOperator{size(x)[1],T}(x)
end

# Constructor from Real-valued Matrix
SparseOperator(x::Matrix{T}) where {T<:Real} =
    SparseOperator(SparseArrays.sparse(Complex.(x)))
# Constructor from Complex-valued Matrix
SparseOperator(x::Matrix{T}) where {T<:Complex} = SparseOperator(SparseArrays.sparse(x))
# Constructor from Integer-valued Matrix
# default output is Operator{ComplexF64}
SparseOperator(x::Matrix{T}, S::Type{<:Complex} = ComplexF64) where {T<:Integer} =
    SparseOperator(Matrix{S}(x))

get_matrix(op::SparseOperator{N,T}) where {N,T<:Complex} = convert(Matrix{T}, op.data)

"""
    sparse(x::AbstractOperator)

Returns a SparseOperator representation of x.

# Examples
```jldoctest
julia> z = sparse(sigma_z())
(2, 2)-element Snowflurry.SparseOperator:
Underlying data ComplexF64:
 1.0 + 0.0im        ⋅     
      ⋅       -1.0 + 0.0im
```
"""
SparseArrays.sparse(x::AbstractOperator) =
    SparseOperator(SparseArrays.sparse(DenseOperator(x).data))

"""
    DenseOperator{N,T<:Complex}<:AbstractOperator

A structure representing a quantum operator with a full (dense) matrix representation of size NxN and containing elements of type T.

# Examples
```jldoctest
julia> z = DenseOperator([1.0 0.0;0.0 -1.0])
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    -1.0 + 0.0im

```
Alternatively:
```jldoctest
julia> z = rotation(π/2, -π/4)  
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.7071067811865476 + 0.0im    0.4999999999999999 - 0.5im
-0.4999999999999999 - 0.5im    0.7071067811865476 + 0.0im


```
"""
struct DenseOperator{N,T<:Complex} <: AbstractOperator
    data::SMatrix{N,N,T}
end

# Constructor from Real-valued Matrix
DenseOperator(x::Matrix{T}) where {T<:Real} =
    DenseOperator(convert(SMatrix{size(x)...,Complex{T}}, x))

# Constructor from Complex-valued Matrix
DenseOperator(x::Matrix{T}) where {T<:Complex} =
    DenseOperator(convert(SMatrix{size(x)...,T}, x))

# Constructor from Integer-valued Matrix
# default output is Operator{ComplexF64}
DenseOperator(x::Matrix{T}, S::Type{<:Complex} = ComplexF64) where {T<:Integer} =
    DenseOperator(Matrix{S}(x))

# Construction of DenseOperator using AbstractOperator
DenseOperator(op::AbstractOperator) = DenseOperator(get_matrix(op))

# Move Constructor: used to simplify operations such as 
# Base.:+(A::AbstractOperator,B::AbstractOperator)=DenseOperator(A)+DenseOperator(B)
# so that an input of type DenseOperator is not copied
DenseOperator(op::DenseOperator) = op

DenseOperator(m::SizedMatrix{N,N,T}) where {N,T<:Complex} = DenseOperator(SMatrix{N,N,T}(m))

DenseOperator(m::SizedMatrix{N,N,T}) where {N,T<:Real} =
    DenseOperator(SMatrix{N,N,Complex{T}}(m))

get_matrix(op::DenseOperator{N,T}) where {N,T<:Complex} = convert(Matrix{T}, op.data)

function Base.inv(op::AbstractOperator)::DenseOperator
    inv_op_matrix = inv(get_matrix(op))

    return DenseOperator(inv_op_matrix)
end

"""
    SwapLikeOperator{N,T<:Complex}<:AbstractOperator

A structure representing a quantum operator performing a "swap" operation, with element type T.
A `phase` value is applied to the swapped qubit coefficients.
This operator is always of size 4x4.

For example, the iswap `Operator` can be built using a `phase=0.0 + 1.0im` by calling:
```jldoctest
julia> SwapLikeOperator(0.0 + 1.0im)
(4, 4)-element Snowflurry.SwapLikeOperator:
Underlying data ComplexF64:
Equivalent DenseOperator:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im

```
"""
struct SwapLikeOperator{N,T<:Complex} <: AbstractOperator
    phase::T
end

SwapLikeOperator(phase::T) where {T<:Complex} = SwapLikeOperator{4,T}(phase)

# Constructor from Real phase value, or other numeric types.
SwapLikeOperator(phase::T) where {T<:Real} =
    SwapLikeOperator{4,Complex{T}}(Complex{T}(phase))

# Constructor from Complex{Int} or Complex{Bool} such as Complex(1) or `im` 
SwapLikeOperator(
    phase::T,
    S::Type{<:Complex} = ComplexF64,
) where {T<:Union{Complex{Bool},Complex{Int}}} = SwapLikeOperator(S(phase))

# Constructor from Integer-valued phase
# default output is Operator{ComplexF64}
SwapLikeOperator(phase::T, S::Type{<:Complex} = ComplexF64) where {T<:Integer} =
    SwapLikeOperator(S(phase))

# Cast SwapLikeOperator to DenseOperator
DenseOperator(op::SwapLikeOperator{N,T}) where {N,T<:Complex} = DenseOperator(
    T[[1.0, 0.0, 0.0, 0.0] [0.0, 0.0, op.phase, 0.0] [0.0, op.phase, 0.0, 0.0] [
        0.0,
        0.0,
        0.0,
        1.0,
    ]],
)

get_matrix(op::SwapLikeOperator) = get_matrix(DenseOperator(op))

"""
    IdentityOperator{N,T<:Complex}<:AbstractOperator

A structure representing the identity quantum operator, with element type T.
This operator is always of size 2x2.

# Example
```jldoctest
julia> IdentityOperator()
(2, 2)-element Snowflurry.IdentityOperator:
Underlying data ComplexF64:
Equivalent DenseOperator:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im

```
"""
struct IdentityOperator{N,T<:Complex} <: AbstractOperator end

IdentityOperator(T::Type = ComplexF64) = IdentityOperator{2,T}()

DenseOperator(::IdentityOperator{2,T}) where {T<:Complex} = eye(T)

get_matrix(op::IdentityOperator) = get_matrix(DenseOperator(op))

"""

getindex(A::AbstractOperator, i::Integer, j::Integer)

Access the element at row i and column j in the matrix corresponding to `Operator` `A`.

# Examples
```jldoctest
julia> Y = sigma_y()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    0.0 - 1.0im
    0.0 + 1.0im    .


julia> Y[1,1]
0.0 + 0.0im

julia> Y[1,2]
0.0 - 1.0im

julia> Y[2,1]
0.0 + 1.0im

julia> Y[2,2]
0.0 + 0.0im

```
"""
Base.getindex(op::AbstractOperator, i::Integer, j::Integer) = DenseOperator(op).data[i, j]

"""

    DiagonalOperator{N,T<:Complex}<:AbstractOperator

A structure representing a diagonal quantum `Operator` (i.e., a complex matrix of element type T, with non-zero elements all lying on the diagonal).
The equivalent dense matrix would have size NxN.

# Examples
```jldoctest
julia> z = DiagonalOperator([1.0,-1.0])
(2,2)-element Snowflurry.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 0.0im    .
.    -1.0 + 0.0im

julia> z = DiagonalOperator([1.0+im,1.0,1.0,0.0-im])
(4,4)-element Snowflurry.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 1.0im    .    .    .
.    1.0 + 0.0im    .    .
.    .    1.0 + 0.0im    .
.    .    .    0.0 - 1.0im

```
"""
struct DiagonalOperator{N,T<:Complex} <: AbstractOperator
    data::SVector{N,T}
end

# Constructor from Real-valued Vector
DiagonalOperator(x::Vector{T}) where {T<:Real} =
    DiagonalOperator(convert(SVector{length(x),Complex{T}}, x))

# Constructor from Complex-valued Vector
DiagonalOperator(x::Vector{T}) where {T<:Complex} =
    DiagonalOperator(convert(SVector{length(x),T}, x))

# Constructor from Integer-valued Vector
# default output is DiagonalOperator{ComplexF64}
DiagonalOperator(x::Vector{T}, S::Type{<:Complex} = ComplexF64) where {T<:Integer} =
    DiagonalOperator(Vector{S}(x))

function Base.getindex(
    diag_op::DiagonalOperator{N,T},
    i::Integer,
    j::Integer,
) where {N,T<:Complex}
    if j == i
        return diag_op.data[i]
    else
        return T(0.0)
    end
end

"""

    AntiDiagonalOperator{N,T<:Complex}<:AbstractOperator

A structure representing a anti-diagonal quantum `Operator` (i.e., a complex matrix of element type T, with non-zero elements all lying on the cross-diagonal).
The equivalent dense matrix would have size NxN.

# Examples
```jldoctest
julia> AntiDiagonalOperator([1, 2])
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    2.0 + 0.0im    .

```
"""
struct AntiDiagonalOperator{N,T<:Complex} <: AbstractOperator
    data::SVector{N,T}

    function AntiDiagonalOperator(x::Union{Vector{T},SVector{N,T}}) where {N,T<:Complex}
        if Val(N) != Val(2)
            throw(
                DomainError(
                    "$(:AntiDiagonalOperator) only implemented for single target (N=2). Received N=$N",
                ),
            )
        else
            return new{N,T}(x)
        end
    end
end


# Constructor from Integer-valued Vector
# default output is AntiDiagonalOperator{N,ComplexF64}
AntiDiagonalOperator(x::Vector{T}, S::Type{<:Complex} = ComplexF64) where {T<:Integer} =
    AntiDiagonalOperator(convert(SVector{length(x),S}, x))

# Constructor from Real-valued Vector
AntiDiagonalOperator(x::Vector{T}) where {T<:Real} =
    AntiDiagonalOperator(convert(SVector{length(x),Complex{T}}, x))

# Constructor from Complex-valued Vector
AntiDiagonalOperator(x::Vector{T}) where {T<:Complex} =
    AntiDiagonalOperator(convert(SVector{length(x),T}, x))

function Base.getindex(
    anti_diag_op::AntiDiagonalOperator{N,T},
    i::Integer,
    j::Integer,
) where {N,T<:Complex}
    if N - j + 1 == i
        return anti_diag_op.data[i]
    else
        return T(0.0)
    end
end

"""
    Base.adjoint(x)

Compute the adjoint (a.k.a. conjugate transpose) of a Ket, a Bra, or an Operator.
"""
Base.adjoint(x::Ket) = Bra(x)
Base.adjoint(x::Bra) = Ket(adjoint(x.data))

Base.adjoint(A::AbstractOperator) = typeof(A)(adjoint(A.data))
Base.adjoint(A::AntiDiagonalOperator{N,T}) where {N,T<:Complex} =
    AntiDiagonalOperator(SVector{N,T}(reverse(adjoint(A.data))))

Base.adjoint(A::SwapLikeOperator) = typeof(A)(adjoint(A.phase))

Base.adjoint(A::IdentityOperator) = A

"""
    is_hermitian(A::AbstractOperator)

Determine if Operator `A` is Hermitian (i.e., self-adjoint).

# Examples
```jldoctest
julia> Y = sigma_y()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    0.0 - 1.0im
    0.0 + 1.0im    .


julia> is_hermitian(Y)
true

julia> P = sigma_p()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    0.0 + 0.0im    .


julia> is_hermitian(P)
false

```
"""
is_hermitian(A::AbstractOperator) = ishermitian(DenseOperator(A).data)
is_hermitian(A::DenseOperator) = LinearAlgebra.ishermitian(A.data)
is_hermitian(A::SparseOperator) = LinearAlgebra.ishermitian(A.data)

Base.:*(s::Number, x::Ket) = Ket(s * x.data)
Base.:*(x::Ket, s::Number) = Base.:*(s, x)
Base.:isapprox(x::Ket, y::Ket; atol::Real = 1.0e-6) = isapprox(x.data, y.data, atol = atol)
Base.:isapprox(x::Bra, y::Bra; atol::Real = 1.0e-6) = isapprox(x.data, y.data, atol = atol)

# generic cases
Base.:isapprox(x::AbstractOperator, y::AbstractOperator; atol::Real = 1.0e-6) =
    isapprox(DenseOperator(x), DenseOperator(y), atol = atol)

# specializations
Base.:isapprox(x::DenseOperator, y::DenseOperator; atol::Real = 1.0e-6) =
    isapprox(x.data, y.data, atol = atol)
Base.:isapprox(x::SparseOperator, y::SparseOperator; atol::Real = 1.0e-6) =
    isapprox(x.data, y.data, atol = atol)
Base.:isapprox(x::DiagonalOperator, y::DiagonalOperator; atol::Real = 1.0e-6) =
    isapprox(x.data, y.data, atol = atol)
Base.:isapprox(x::AntiDiagonalOperator, y::AntiDiagonalOperator; atol::Real = 1.0e-6) =
    isapprox(x.data, y.data, atol = atol)
Base.:isapprox(x::SwapLikeOperator, y::SwapLikeOperator; atol::Real = 1.0e-6) =
    isapprox(x.phase, y.phase, atol = atol)

Base.:isapprox(x::SwapLikeOperator, y::AbstractOperator; atol::Real = 1.0e-6) =
    isapprox(DenseOperator(x), y, atol = atol)
Base.:isapprox(x::AbstractOperator, y::SwapLikeOperator; atol::Real = 1.0e-6) =
    isapprox(x, DenseOperator(y), atol = atol)


Base.:-(x::Ket) = -1.0 * x
Base.:-(x::Ket, y::Ket) = Ket(x.data - y.data)
Base.:*(x::Bra, y::Ket) = x.data * y.data
Base.:+(x::Ket, y::Ket) = Ket(x.data + y.data)
Base.:*(x::Ket, y::Bra) = DenseOperator(x.data * y.data)

Base.:*(M::AbstractOperator, x::Ket) = Ket(Vector(DenseOperator(M).data * x.data))
Base.:*(M::SparseOperator, x::Ket) = Ket(M.data * x.data)
Base.:*(x::Bra, M::AbstractOperator) = Bra(x.data * DenseOperator(M).data)
Base.:*(x::Bra, M::SparseOperator) = Bra(x.data * M.data)

# generic cases
Base.:*(A::AbstractOperator, B::AbstractOperator) = DenseOperator(A) * DenseOperator(B)

# specializations
Base.:*(A::DenseOperator{N,T}, B::DenseOperator{N,T}) where {N,T<:Complex} =
    DenseOperator(A.data * B.data)

Base.:*(A::DenseOperator, B::DenseOperator) = throw(
    DimensionMismatch(
        "Cannot multiply Operators of dissimilar sizes." *
        " A has size $(size(A)) and B has size $(size(B)).",
    ),
)
Base.:+(A::DenseOperator, B::DenseOperator) = throw(
    DimensionMismatch(
        "Cannot sum Operators of dissimilar sizes." *
        " A has size $(size(A)) and B has size $(size(B)).",
    ),
)
Base.:-(A::DenseOperator, B::DenseOperator) = throw(
    DimensionMismatch(
        "Cannot take difference of Operators of dissimilar sizes." *
        " A has size $(size(A)) and B has size $(size(B)).",
    ),
)

Base.:*(A::DenseOperator{N,T}, B::DenseOperator{N,S}) where {N,T<:Complex,S<:Complex} =
    DenseOperator(*(promote(A.data, B.data)...))
Base.:*(A::DiagonalOperator{N,T}, B::DiagonalOperator{N,T}) where {N,T<:Complex} =
    DiagonalOperator(SVector{N,T}([a * b for (a, b) in zip(A.data, B.data)]))
Base.:*(A::AntiDiagonalOperator{N,T}, B::AntiDiagonalOperator{N,T}) where {N,T<:Complex} =
    DiagonalOperator(SVector{N,T}([a * b for (a, b) in zip(A.data, reverse(B.data))]))
Base.:*(A::SparseOperator{N,T}, B::SparseOperator{N,T}) where {N,T<:Complex} =
    SparseOperator{N,T}(A.data * B.data)

Base.:*(A::IdentityOperator, B::IdentityOperator) = A
function Base.:*(A::IdentityOperator, B::AbstractOperator)
    if size(A) != size(B)
        throw(
            DimensionMismatch(
                "Cannot multiply Operators of dissimilar sizes." *
                " A has size $(size(A)) and B has size $(size(B)).",
            ),
        )
    end

    if typeof(A[1, 1]) != typeof(B[1, 1])
        # build promoted Operator of same type as input
        output_type = typeof(promote(A[1, 1], B[1, 1])[1])

        return output_type(1.0) * B
    else
        return B
    end
end
Base.:*(A::AbstractOperator, B::IdentityOperator) = B * A

Base.:*(s::Number, A::DenseOperator) = DenseOperator(s * A.data)
Base.:*(s::Number, A::DiagonalOperator) = DiagonalOperator(s * A.data)
Base.:*(s::Number, A::AntiDiagonalOperator) = AntiDiagonalOperator(s * A.data)
Base.:*(s::Number, A::SparseOperator) = SparseOperator(s * A.data)
Base.:*(s::Number, A::SwapLikeOperator) = s * DenseOperator(A)
Base.:*(s::Number, A::IdentityOperator) = s * DenseOperator(A)


Base.:*(A::AbstractOperator, s::Number) = Base.:*(s, A)

# generic cases
Base.:+(A::AbstractOperator, B::AbstractOperator) = DenseOperator(A) + DenseOperator(B)
Base.:-(A::AbstractOperator, B::AbstractOperator) = DenseOperator(A) - DenseOperator(B)

# specializations
Base.:+(A::DenseOperator{N,T}, B::DenseOperator{N,S}) where {N,T<:Complex,S<:Complex} =
    DenseOperator(+(promote(A.data, B.data)...))

Base.:+(A::T, B::T) where {T<:DenseOperator} = T(A.data + B.data)
Base.:+(A::T, B::T) where {T<:SparseOperator} = T(A.data + B.data)
Base.:+(A::T, B::T) where {T<:DiagonalOperator} = T(A.data + B.data)
Base.:+(A::T, B::T) where {T<:AntiDiagonalOperator} = AntiDiagonalOperator(A.data + B.data)
Base.:+(A::T, B::T) where {T<:SwapLikeOperator} = DenseOperator(A) + DenseOperator(B)


# specializations
Base.:-(A::DenseOperator{N,T}, B::DenseOperator{N,S}) where {N,T<:Complex,S<:Complex} =
    DenseOperator(-(promote(A.data, B.data)...))

Base.:-(A::T, B::T) where {T<:DenseOperator} = T(A.data - B.data)
Base.:-(A::T, B::T) where {T<:SparseOperator} = T(A.data - B.data)
Base.:-(A::T, B::T) where {T<:DiagonalOperator} = T(A.data - B.data)
Base.:-(A::T, B::T) where {T<:AntiDiagonalOperator} = AntiDiagonalOperator(A.data - B.data)
Base.:-(A::T, B::T) where {T<:SwapLikeOperator} = DenseOperator(A) - DenseOperator(B)

Base.length(x::Union{Ket,Bra}) = length(x.data)

"""
    exp(A::AbstractOperator)

Compute the matrix exponential of `Operator` `A`.

# Examples
```jldoctest
julia> X = sigma_x()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


julia> x_rotation_90_deg = exp(-im*π/4*X)
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.7071067811865475 + 0.0im    0.0 - 0.7071067811865475im
0.0 - 0.7071067811865475im    0.7071067811865475 + 0.0im


```
"""
Base.exp(A::AbstractOperator) = DenseOperator(exp(DenseOperator(A).data))

# specializations
Base.exp(A::DenseOperator) = DenseOperator(exp(A.data))
Base.exp(A::DiagonalOperator) = DiagonalOperator([exp(a) for a in Vector(A.data)])

"""
    eigen(A::AbstractOperator)

Compute the eigenvalue decomposition of Operator `A` and return an `Eigen`
factorization object `F`. Eigenvalues are found in `F.values` while eigenvectors are
found in the matrix `F.vectors`. Each column of this matrix corresponds to an eigenvector.
The `i`th eigenvector is extracted by calling `F.vectors[:, i]`.

# Examples
```jldoctest
julia> X = sigma_x()
(2,2)-element Snowflurry.AntiDiagonalOperator:
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
LinearAlgebra.eigen(A::AbstractOperator) = LinearAlgebra.eigen(DenseOperator(A))
# specializations
LinearAlgebra.eigen(A::DenseOperator) = LinearAlgebra.eigen(Matrix(A.data))
LinearAlgebra.eigen(A::SparseOperator; kwargs...) = Arpack.eigs(A.data; kwargs...)

"""
    tr(A::AbstractOperator)

Compute the trace of Operator `A`.

# Examples
```jldoctest
julia> I = eye()
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im


julia> trace = tr(I)
2.0 + 0.0im

```
"""
LinearAlgebra.tr(A::AbstractOperator) = LinearAlgebra.tr(DenseOperator(A))
LinearAlgebra.tr(A::DenseOperator{N,T}) where {N,T<:Complex} = LinearAlgebra.tr(A.data)


"""
    expected_value(A::AbstractOperator, psi::Ket)

Compute the expectation value ⟨`ψ`|`A`|`ψ`⟩ given Operator `A` and Ket |`ψ`⟩.

# Examples
```jldoctest
julia> ψ = Ket([0.0; 1.0])
2-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im


julia> A = sigma_z()
(2,2)-element Snowflurry.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 0.0im    .
.    -1.0 + 0.0im


julia> expected_value(A, ψ)
-1.0 + 0.0im
```
"""
expected_value(A::AbstractOperator, psi::Ket) = (Bra(psi) * A * psi)



# generic case
Base.:size(M::AbstractOperator) = size(M.data)

# specializations
Base.:size(M::DiagonalOperator) = (length(M.data), length(M.data))
Base.:size(M::AntiDiagonalOperator) = (length(M.data), length(M.data))
Base.:size(M::SwapLikeOperator) = (4, 4)
Base.:size(M::IdentityOperator) = (2, 2)


# iterator for Ket object
Base.iterate(x::Ket, state = 1) =
    state > length(x.data) ? nothing : (x.data[state], state + 1)

"""
    kron(x, y)

Compute the Kronecker product of two [`Kets`](@ref Ket) or two 
[`DenseOperator`](@ref) , [`DiagonalOperator`](@ref), [`AntiDiagonalOperator`](@ref).
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
(4, 4)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 - 1.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 - 1.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 1.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im


```
"""
Base.kron(x::Ket, y::Ket) = Ket(kron(x.data, y.data))

Base.kron(x::AbstractOperator, y::AbstractOperator) =
    kron(DenseOperator(x), DenseOperator(y))

Base.kron(x::DenseOperator, y::DenseOperator) = DenseOperator(kron(x.data, y.data))

Base.kron(x::SparseOperator, y::SparseOperator) = SparseOperator(kron(x.data, y.data))


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
        "Snowflurry.Multibody system with %d bodies\n",
        length(system.hilbert_space_structure)
    )
    @printf(io, "   Hilbert space structure:\n")
    @printf(io, "   ")
    show(io, system.hilbert_space_structure)
end

"""
    get_embed_operator(op::DenseOperator, target_body_index::Int, system::MultiBodySystem)

Uses a local operator (`op`), which is defined for a particular body (e.g. qubit) with index `target_body_index`, to build the corresponding operator for the Hilbert space of the multi-body system given by `system`. 
# Examples
```jldoctest
julia> system = MultiBodySystem(3, 2)
Snowflurry.Multibody system with 3 bodies
   Hilbert space structure:
   [2, 2, 2]

julia> x = sigma_x()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .

julia> X_1 = get_embed_operator(x, 1, system)
(8, 8)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
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
function get_embed_operator(
    op::T,
    target_body_index::Int,
    system::MultiBodySystem,
) where {T<:Union{DenseOperator,SparseOperator}}
    n_body = length(system.hilbert_space_structure)
    @assert target_body_index <= n_body

    result = T(
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
            result = kron(result, T(Matrix{eltype(op.data)}(I, n_hilbert, n_hilbert)))
        end
    end
    return result
end


get_embed_operator(op::AbstractOperator, target_body_index::Int, system::MultiBodySystem) =
    get_embed_operator(DenseOperator(op), target_body_index, system)

get_matrix(op::AbstractOperator) = throw(NotImplementedError(:get_matrix, op))

function Base.show(io::IO, x::DenseOperator)
    println(io, "$(size(x.data))-element Snowflurry.DenseOperator:")
    println(io, "Underlying data $(eltype(x.data)):")
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

function Base.show(io::IO, x::SparseOperator)
    println(io, "$(size(x.data))-element Snowflurry.SparseOperator:")
    println(io, "Underlying data $(eltype(x.data)):")
    Base.print_array(io, x.data)
end


function Base.show(io::IO, x::SwapLikeOperator)
    println(io, "$(size(x))-element Snowflurry.SwapLikeOperator:")
    println(io, "Underlying data $(eltype(x.phase)):")
    (nrow, ncol) = size(x)

    println(io, "Equivalent DenseOperator:")
    denseop = DenseOperator(x)
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            if j == 1
                print(io, "$(denseop.data[i, j])")
            else
                print(io, "    $(denseop.data[i, j])")
            end
        end
        println(io)
    end
end

function Base.show(io::IO, x::IdentityOperator)
    println(io, "$(size(x))-element Snowflurry.IdentityOperator:")
    println(io, "Underlying data $(typeof(x[1,1])):")
    (nrow, ncol) = size(x)

    println(io, "Equivalent DenseOperator:")
    denseop = DenseOperator(x)
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            if j == 1
                print(io, "$(denseop.data[i, j])")
            else
                print(io, "    $(denseop.data[i, j])")
            end
        end
        println(io)
    end
end

function Base.show(io::IO, x::DiagonalOperator)
    println(
        io,
        "($(length(x.data)),$(length(x.data)))-element Snowflurry.DiagonalOperator:",
    )
    println(io, "Underlying data type: $(eltype(x.data)):")
    nrow = length(x.data)
    ncol = nrow
    for i in range(1, stop = nrow)
        for j in range(1, stop = ncol)
            if j == i
                if j == 1
                    print(io, "$(x.data[i])")
                else
                    print(io, "    $(x.data[i])")
                end
            else
                if j == 1
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
    matrix = zeros(T, N, N)
    nrow = length(op.data)
    ncol = nrow
    for i = 1:nrow
        for j = 1:ncol
            if i == j
                matrix[i, j] = op.data[i]
            end
        end
    end
    return matrix
end

function Base.show(io::IO, x::AntiDiagonalOperator)
    println(
        io,
        "($(length(x.data)),$(length(x.data)))-element Snowflurry.AntiDiagonalOperator:",
    )
    println(io, "Underlying data type: $(eltype(x.data)):")
    nrow = length(x.data)
    ncol = nrow
    for i = 1:nrow
        for j = 1:ncol
            if ncol - j + 1 == i
                print(io, "    $(x.data[i])")
            else
                print(io, "    .")
            end
        end
        println(io)
    end
end

function get_matrix(op::AntiDiagonalOperator{N,T}) where {N,T<:Complex}
    matrix = zeros(T, N, N)
    nrow = length(op.data)
    ncol = nrow
    for i = 1:nrow
        for j = 1:ncol
            if ncol - j + 1 == i
                matrix[i, j] = op.data[i]
            end
        end
    end
    return matrix
end

"""
    get_num_qubits(x::AbstractOperator)

Returns the number of qubits associated with an `Operator`.
# Examples
```jldoctest
julia> ρ = DenseOperator([1. 0. 
                          0. 0.])
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im

julia> get_num_qubits(ρ)
1

```
"""
function get_num_qubits(x::AbstractOperator)
    (num_rows, num_columns) = size(x)
    if num_rows != num_columns
        throw(ErrorException("$(typeof(x)) is not square"))
    end
    if num_rows < 2 || count_ones(num_rows) != 1
        throw(
            DomainError(
                num_rows,
                "$(typeof(x)) does not correspond to an integer number of qubits",
            ),
        )
    end

    return trailing_zeros(num_rows)
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
function get_num_qubits(x::Union{Ket,Bra})
    size = length(x)
    if size < 2 || count_ones(size) != 1
        throw(
            DomainError(
                size,
                "Ket or Bra does not correspond to an integer number of qubits",
            ),
        )
    end
    return trailing_zeros(size)
end

"""
    get_num_bodies(x::AbstractOperator, hilbert_space_size_per_body=2)

Returns the number of bodies associated with an `Operator` given the
`hilbert_space_size_per_body`.
# Examples
```jldoctest
julia> ρ = DenseOperator([1. 0. 0.
                          0. 0. 0.
                          0. 0. 0.])
(3, 3)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im

julia> get_num_bodies(ρ, 3)
1

```
"""
function get_num_bodies(x::AbstractOperator, hilbert_space_size_per_body = 2)
    (num_rows, num_columns) = size(x)
    if num_rows != num_columns
        throw(ErrorException("$(typeof(x)) is not square"))
    end
    num_bodies = log(hilbert_space_size_per_body, num_rows)
    if mod(num_bodies, 1) != 0
        throw(
            DomainError(
                num_bodies,
                "$(typeof(x)) does not correspond to an integer number of bodies",
            ),
        )
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
function get_num_bodies(x::Union{Ket,Bra}, hilbert_space_size_per_body = 2)
    num_bodies = log(hilbert_space_size_per_body, length(x))
    if mod(num_bodies, 1) != 0
        throw(
            DomainError(
                num_bodies,
                "Ket or Bra does not correspond to an integer number of bodies",
            ),
        )
    end
    return Int(num_bodies)
end

"""
    fock(i, hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the `i`th Fock basis of a Hilbert space with size `hspace_size` as a Ket.

!!! note
    Fock basis states numbering starts at 0.

The Ket contains values of type `T`, which by default is ComplexF64.
# Examples
```jldoctest
julia> ψ = fock(0, 3)
3-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


julia> ψ = fock(1, 3)
3-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im


julia> ψ = fock(1, 3, ComplexF32) # specifying a type other than ComplexF64
3-element Ket{ComplexF32}:
0.0f0 + 0.0f0im
1.0f0 + 0.0f0im
0.0f0 + 0.0f0im
```
"""
function fock(i, hspace_size, T::Type{<:Complex} = ComplexF64)
    @assert i >= 0 "Fock basis numbering starts at 0, received: $i"
    @assert i < hspace_size "Fock basis number can at most be one less than the hspace_size, received: $i, with hspace_size: $hspace_size"

    d = fill(T(0.0), hspace_size)
    d[i+1] = 1.0
    return Ket(d)
end

"""
    spin_up(T::Type{<:Complex}=ComplexF64)

Returns the `Ket` representation of the spin-up state.

The `Ket` stores values of type `T`, which is `ComplexF64` by default.

# Examples
```jldoctest
julia> ψ = spin_up()
2-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im


```
"""
spin_up(T::Type{<:Complex} = ComplexF64) = fock(0, 2, T)

"""
    spin_down(T::Type{<:Complex}=ComplexF64)

Returns the `Ket` representation of the spin-down state.

The `Ket` stores values of type `T`, which is `ComplexF64` by default.

# Examples
```jldoctest
julia> ψ = spin_down()
2-element Ket{ComplexF64}:
0.0 + 0.0im
1.0 + 0.0im


```
"""
spin_down(T::Type{<:Complex} = ComplexF64) = fock(1, 2, T)

"""
    create(hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the bosonic creation operator for a Fock space of size `hspace_size`, of default type ComplexF64.
"""
function create(hspace_size, T::Type{<:Complex} = ComplexF64)
    a_dag = zeros(T, hspace_size, hspace_size)
    for i = 2:hspace_size
        a_dag[i, i-1] = sqrt((i - 1.0))
    end
    return DenseOperator(a_dag)
end

"""
    destroy(hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the bosonic annhilation operator for a Fock space of size `hspace_size`, of default type ComplexF64.
"""
function destroy(hspace_size, T::Type{<:Complex} = ComplexF64)
    a = zeros(T, hspace_size, hspace_size)
    for i = 2:hspace_size
        a[i-1, i] = sqrt((i - 1.0))
    end
    return DenseOperator(a)
end

"""
    number_op(hspace_size,T::Type{<:Complex}=ComplexF64)

Returns the number operator for a Fock space of size `hspace_size`, of default type ComplexF64.
"""
function number_op(hspace_size, T::Type{<:Complex} = ComplexF64)
    n = zeros(T, hspace_size, hspace_size)
    for i = 2:hspace_size
        n[i, i] = i - 1.0
    end
    return DenseOperator(n)
end

"""
    coherent(alpha, hspace_size)

Returns a coherent state for the parameter `alpha` in a Fock space of size `hspace_size`.
Note that |alpha|^2 is equal to the photon number of the coherent state. 

    # Examples
```jldoctest
julia> ψ = coherent(2.0, 20)
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


julia> expected_value(number_op(20), ψ)
3.99999979364864 + 0.0im
```
"""
function coherent(alpha, hspace_size)
    ψ = fock(0, hspace_size)
    for i = 1:hspace_size-1
        ψ += (alpha^i) / (sqrt(factorial(i))) * fock(i, hspace_size)
    end
    ψ = exp(-0.5 * abs2(alpha)) * ψ
    return ψ
end

"""
    normalize!(x::Ket)

Normalizes Ket `x` such that its magnitude becomes unity.

```jldoctest
julia> ψ = Ket([1., 2., 4.])
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
function LinearAlgebra.normalize!(x::Ket)
    a = LinearAlgebra.norm(x.data, 2)
    x = 1.0 / a * x
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
basis state. For instance, for a 2-qubit `Ket`, the probabilities are listed for \$\\left|00\\right\\rangle\$, 
\$\\left|10\\right\\rangle\$, \$\\left|01\\right\\rangle\$, and \$\\left|11\\right\\rangle\$. 
!!! note
    By convention, qubit 1 is the leftmost digit, followed by every subsequent qubit. 
    \$\\left|10\\right\\rangle\$ has qubit 1 in state \$\\left|1\\right\\rangle\$ and qubit 2 in state \$\\left|0\\right\\rangle\$

# Examples
The following example constructs a `Ket`, where the probability of measuring 
\$\\left|00\\right\\rangle\$ is 50% and the probability of measuring \$\\left|01\\right\\rangle\$ is also 50%.

```jldoctest get_measurement_probabilities
julia> ψ = 1/sqrt(2) * Ket([1, 0, 1, 0])
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
function get_measurement_probabilities(
    x::Ket{Complex{T}},
)::AbstractVector{T} where {T<:Real}
    return real.(adjoint.(x) .* x)
end

function get_measurement_probabilities(
    x::Ket{Complex{T}},
    target_bodies::Vector{U},
    hspace_size_per_body::U = 2,
)::AbstractVector{T} where {T<:Real,U<:Integer}

    num_bodies = get_num_bodies(x, hspace_size_per_body)
    hspace_size_per_body_list = fill(hspace_size_per_body, num_bodies)
    return get_measurement_probabilities(x, target_bodies, hspace_size_per_body_list)
end

function get_measurement_probabilities(
    x::Ket{Complex{T}},
    target_bodies::Vector{U},
    hspace_size_per_body::Vector{U},
)::AbstractVector{T} where {T<:Real,U<:Integer}

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
            target_index =
                get_target_amplitude_index(bitstring, target_bodies, hspace_size_per_body)
            target_amplitudes[target_index] += single_amplitude
            increment_bitstring!(bitstring, hspace_size_per_body)
        end
        return target_amplitudes
    end
end

function throw_if_targets_are_invalid(
    x::Ket{Complex{T}},
    target_bodies::Vector{U},
    hspace_size_per_body::Vector{U},
) where {T<:Real,U<:Integer}

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
        throw(
            ErrorException(
                "elements of target_bodies cannot be greater than the " *
                "number of bodies",
            ),
        )
    end
end

function get_num_target_amplitudes(
    target_bodies::Vector{T},
    hspace_size_per_body::Vector{T},
) where {T<:Integer}

    num_amplitudes = 1
    for target_index in target_bodies
        num_amplitudes *= hspace_size_per_body[target_index]
    end
    return num_amplitudes
end

function get_target_amplitude_index(
    bitstring::Vector{T},
    target_bodies::Vector{T},
    hspace_size_per_body::Vector{T},
) where {T<:Integer}

    amplitude_index = 1
    previous_base = 1
    for i_body in reverse(target_bodies)
        amplitude_index += bitstring[i_body] * previous_base
        previous_base *= hspace_size_per_body[i_body]
    end
    return amplitude_index
end

function increment_bitstring!(
    bitstring::Vector{T},
    hspace_size_per_bit::Vector{T},
) where {T<:Integer}

    num_bits = length(bitstring)
    i_bit = num_bits
    finished_updating = false
    while i_bit > 0 && !finished_updating
        if bitstring[i_bit] == hspace_size_per_bit[i_bit] - 1
            bitstring[i_bit] = 0
            i_bit -= 1
        else
            bitstring[i_bit] += 1
            finished_updating = true
        end
    end
end

"""
    commute(A::AbstractOperator, B::AbstractOperator)

Returns the commutation of `A` and `B`.
```jldoctest
julia> σ_x = sigma_x()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


julia> σ_y = sigma_y()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    0.0 - 1.0im
    0.0 + 1.0im    .


julia> commute(σ_x, σ_y)
(2,2)-element Snowflurry.DiagonalOperator:
Underlying data type: ComplexF64:
0.0 + 2.0im    .
.    0.0 - 2.0im

```
"""
commute(A::AbstractOperator, B::AbstractOperator) = A * B - B * A


"""
    anticommute(A::AbstractOperator, B::AbstractOperator)

Returns the anticommutation of `A` and `B`.
```jldoctest
julia> σ_x = sigma_x()
(2,2)-element Snowflurry.AntiDiagonalOperator:
Underlying data type: ComplexF64:
    .    1.0 + 0.0im
    1.0 + 0.0im    .


julia> anticommute(σ_x, σ_x)
(2,2)-element Snowflurry.DiagonalOperator:
Underlying data type: ComplexF64:
2.0 + 0.0im    .
.    2.0 + 0.0im

```
"""
anticommute(A::AbstractOperator, B::AbstractOperator) = A * B + B * A


"""
    ket2dm(ψ::Ket)

Returns the density matrix corresponding to the pure state ψ.
"""
function ket2dm(ψ::Ket)
    return ψ * Bra(ψ)
end

"""
    fock_dm(i::Int64, hspace_size::Int64)

Returns the density matrix corresponding to the Fock base `i` defined in a Hilbert space of
size `hspace_size`.

```jldoctest
julia> dm = fock_dm(0, 2)
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im


```
"""
fock_dm(i::Int64, hspace_size::Int64) = ket2dm(fock(i, hspace_size))

"""
    wigner(ρ::AbstractOperator, p::Real, q::Real)

Computes the Wigner function of the density matrix `ρ` at the point (`p`,`q`).

```jldoctest
julia> alpha = 0.25;

julia> hspace_size = 8;

julia> Ψ = coherent(alpha, hspace_size);

julia> prob = wigner(ket2dm(Ψ), 0, 0);

julia> @printf "prob: %.6f" prob
prob: 0.561815
```
"""
function wigner(ρ::AbstractOperator, p::Real, q::Real)
    hilbert_size, _ = size(ρ)
    eta = q + p * im
    w = 0.0
    for m = 1:hilbert_size
        for n = 1:m
            if (n == m)
                w = w + real(ρ[m, n] * moyal(eta, m - 1, n - 1))
            else
                w = w + 2.0 * real(ρ[m, n] * moyal(eta, m - 1, n - 1))
            end
        end
    end
    return w
end

"""
    moyal(m, n)

Returns the Moyal function `w_mn(eta)` for Fock states `m` and `n`.

!!! note
    Fock basis states numbering starts at 0.

"""
function moyal(eta, m, n)
    @assert m >= 0 "Fock basis number cannot be negative, received: $m"
    @assert n >= 0 "Fock basis number cannot be negative, received: $n"

    L = genlaguerre(4.0 * abs2(eta), m - n, n)
    w_mn =
        2.0 * (-1)^n / pi *
        sqrt(factorial(big(n)) / factorial(big(m))) *
        (2.0 * conj(eta))^(m - n) *
        exp(-2.0 * abs2(eta)) *
        L
    return w_mn
end


"""
    genlaguerre(x, alpha, n)

Returns the generalized Laguerre polynomial of degree `n` for `x` using a recursive
method. See [https://en.wikipedia.org/wiki/Laguerre_polynomials](https://en.wikipedia.org/wiki/Laguerre_polynomials).
"""
function genlaguerre(x, alpha, n)
    result = 0.0
    L_0 = 1
    L_1 = 1.0 + alpha - x
    if (n == 0)
        return L_0
    end
    if (n == 1)
        return L_1
    end

    for k = 1:n-1
        result = (2.0 * k + 1.0 + alpha - x) * L_1 - (k + alpha) * L_0
        result = result / (k + 1.0)
        L_0 = L_1
        L_1 = result
    end
    return result
end

function get_canonical_global_phase(H::AbstractMatrix{Complex{T}})::T where {T<:Real}
    # Use the first non-zero element to determine the global phase of the matrix
    for index in eachindex(H)
        element = H[index]
        if (!isapprox(element, 0; atol = sqrt(eps(T))))
            return get_canonical_global_phase(element)
        end
    end

    # If the matrix is zero, then define the global phase as 0
    return T(0)
end


"""

    compare_operators(H_0::AbstractOperator, H_1::AbstractOperator)::Bool

Checks for equivalence allowing for a global phase difference between two input operators.

# Examples
```jldoctest
julia> H_0 = z_90()
(2,2)-element Snowflurry.DiagonalOperator:
Underlying data type: ComplexF64:
0.7071067811865476 - 0.7071067811865475im    .
.    0.7071067811865476 + 0.7071067811865475im


julia> H_1 = phase_shift(pi / 2)
(2,2)-element Snowflurry.DiagonalOperator:
Underlying data type: ComplexF64:
1.0 + 0.0im    .
.    6.123233995736766e-17 + 1.0im


julia> compare_operators(H_0, H_1)
true

julia> H_1 *= sigma_x()
(2, 2)-element Snowflurry.DenseOperator:
Underlying data ComplexF64:
0.0 + 0.0im    1.0 + 0.0im
6.123233995736766e-17 + 1.0im    0.0 + 0.0im


julia> compare_operators(H_0, H_1) # no longer equivalent after applying sigma x
false

```
"""
function compare_operators(H_0::AbstractOperator, H_1::AbstractOperator)::Bool
    m_0 = get_matrix(H_0)
    m_1 = get_matrix(H_1)

    @assert size(m_0) == size(m_1)

    δ = get_canonical_global_phase(m_0) - get_canonical_global_phase(m_1)

    # We need to check atol for values close to zero
    return isapprox(m_0, exp(im * δ) .* m_1; atol = 1e-6)
end
