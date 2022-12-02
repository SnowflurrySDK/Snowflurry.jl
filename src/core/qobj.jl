"""
A Ket represents a *quantum wavefunction* and is mathematically equivalent to a column vector of complex values. The norm of a Ket should always be unity.  
# Fields
- `data` -- the stored values.
# Examples
Although NOT the preferred way, one can directly build a Ket object by passing a column vector as the initializer. 
```jldoctest
julia> using Snowflake

julia> ψ = Snowflake.Ket([1.0; 0.0; 0.0]);

julia> print(ψ)
3-element Ket:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
```
A better way to initialize a Ket is to use a pre-built basis such as the `fock` basis. See [`fock`](@ref) for further information on this function. 
```jldoctest
julia> ψ = Snowflake.fock(2, 3);

julia> print(ψ)
3-element Ket:
0.0 + 0.0im
0.0 + 0.0im
1.0 + 0.0im
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
# Fields
- `data` -- the stored values.
# Examples
```jldoctest
julia> ψ = Snowflake.fock(1, 3);

julia> print(ψ)
3-element Ket:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im

julia> _ψ = Snowflake.Bra(ψ);

julia> print(_ψ)
Bra(Any[0.0 - 0.0im 1.0 - 0.0im 0.0 - 0.0im])


julia> _ψ * ψ    # A Bra times a Ket is a scalar
1.0 + 0.0im

julia> ψ*_ψ     # A Ket times a Bra is an operator
(3, 3)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
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
# Fields
- `data` -- the complex matrix.

# Examples
```jldoctest
julia> z = Snowflake.Operator([1.0 0.0;0.0 -1.0])
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    -1.0 + 0.0im

```
Alternatively:
```jldoctest
julia> z = Snowflake.sigma_z()  #sigma_z is a defined function in Snowflake
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    -1.0 + 0.0im
```
"""
struct Operator
    data::Matrix{Complex}
end

Base.length(x::Ket) = Base.length(x.data)

"""
    Base.adjoint(x)

Compute the adjoint (a.k.a. conjugate transpose) of a Ket, a Bra, or an Operator.
"""
Base.adjoint(x::Ket) = Bra(x)
Base.adjoint(x::Bra) = Ket(adjoint(x.data))
Base.adjoint(A::Operator) = Operator(adjoint(A.data))

ishermitian(A::Operator) = LinearAlgebra.ishermitian(A.data)

Base.:*(alpha::Number, x::Ket) = Ket(alpha * x.data)
Base.:isapprox(x::Ket, y::Ket; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)
Base.:isapprox(x::Bra, y::Bra; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)
Base.:isapprox(x::Operator, y::Operator; atol::Real=1.0e-6) = isapprox(x.data, y.data, atol=atol)
Base.:-(x::Ket) = -1.0 * x
Base.:-(x::Ket, y::Ket) = Ket(x.data - y.data)
Base.:*(x::Bra, y::Ket) = x.data * y.data
Base.:+(x::Ket, y::Ket) = Ket(x.data + y.data)
Base.:*(x::Ket, y::Bra) = Operator(x.data * y.data)
Base.:*(M::Operator, x::Ket) = Ket(M.data * x.data)
Base.:*(x::Bra, M::Operator) = Bra(x.data * M.data)
Base.:*(A::Operator, B::Operator) = Operator(A.data * B.data)
Base.:*(s::Any, A::Operator) = Operator(s*A.data)
Base.:+(A::Operator, B::Operator) = Operator(A.data+ B.data)
Base.:-(A::Operator, B::Operator) = Operator(A.data- B.data)
Base.length(x::Union{Ket, Bra}) = Base.length(x.data)

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
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
0.0 + 0.0im    1.0 + 0.0im
1.0 + 0.0im    0.0 + 0.0im

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

"""
    tr(A::Operator)

Compute the trace of Operator `A`.

# Examples
```jldoctest
julia> I = eye()
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
1.0 + 0.0im    0 + 0im
0 + 0im    1.0 + 0.0im


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
julia> ψ = Ket([0.0; 1.0]);

julia> print(ψ)
2-element Ket:
0.0 + 0.0im
1.0 + 0.0im


julia> A = sigma_z()
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    -1.0 + 0.0im


julia> expected_value(A, ψ)
-1.0 + 0.0im
```
"""
expected_value(A::Operator, psi::Ket) = (Bra(psi)*(A*psi))


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
julia> ψ_0 = Ket([0.0; 1.0]);

julia> print(ψ_0)
2-element Ket:
0.0 + 0.0im
1.0 + 0.0im


julia> ψ_1 = Ket([1.0; 0.0]);

julia> print(ψ_1)
2-element Ket:
1.0 + 0.0im
0.0 + 0.0im


julia> ψ_0_1 = kron(ψ_0, ψ_1);

julia> print(ψ_0_1)
4-element Ket:
0.0 + 0.0im
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im


julia> kron(sigma_x(), sigma_y())
(4, 4)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 - 1.0im
0.0 + 0.0im    0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 - 1.0im    0.0 + 0.0im    0.0 + 0.0im
0.0 + 1.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
```
"""
Base.kron(x::Ket, y::Ket) = Ket(kron(x.data, y.data))
Base.kron(x::Operator, y::Operator) = Operator(kron(x.data, y.data))

"""
A structure representing a quantum multi-body system.
# Fields
- `hilbert_space_structure` -- a vector of integers specifying the local Hilbert space size for each "body" within the multi-body system. 
"""
struct MultiBodySystem
    hilbert_space_structure::Vector{Int}
    MultiBodySystem(n_body, hilbert_size_per_body) =
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
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
0.0 + 0.0im    1.0 + 0.0im
1.0 + 0.0im    0.0 + 0.0im

julia> X_1=Snowflake.get_embed_operator(x,1,system)
(8, 8)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
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


"""
    get_num_qubits(x::Operator)

Returns the number of qubits associated with an `Operator`.
# Examples
```jldoctest
julia> ρ = Operator([1 0
                     0 0])
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
1 + 0im    0 + 0im
0 + 0im    0 + 0im

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
julia> ψ = Ket([1, 0, 0, 0]);

julia> print(ψ)
4-element Ket:
1 + 0im
0 + 0im
0 + 0im
0 + 0im

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
julia> ρ = Operator([1 0 0
                     0 0 0
                     0 0 0])
(3, 3)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
1 + 0im    0 + 0im    0 + 0im
0 + 0im    0 + 0im    0 + 0im
0 + 0im    0 + 0im    0 + 0im

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
julia> ψ = Ket([1, 0, 0, 0, 0, 0, 0, 0, 0]);

julia> print(ψ)
9-element Ket:
1 + 0im
0 + 0im
0 + 0im
0 + 0im
0 + 0im
0 + 0im
0 + 0im
0 + 0im
0 + 0im

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
    Snowflake.fock(i, hspace_size)

Returns the `i`th fock basis of a Hilbert space with size `hspace_size` as Snowflake.Ket.
# Examples
```jldoctest
julia> ψ = Snowflake.fock(0, 3);

julia> print(ψ)
3-element Ket:
1.0 + 0.0im
0.0 + 0.0im
0.0 + 0.0im


julia> ψ = Snowflake.fock(1, 3);

julia> print(ψ)
3-element Ket:
0.0 + 0.0im
1.0 + 0.0im
0.0 + 0.0im
```
"""
function fock(i, hspace_size)
    d = fill(Complex(0.0), hspace_size)
    d[i+1] = 1.0
    return Ket(d)
end

spin_up() = fock(0,2)
spin_down() = fock(1,2)

"""
    Snowflake.create(hspace_size)

Returns the bosonic creation operator for a Fock space of size `hspace_size`.
"""
function create(hspace_size)
    a_dag = zeros(Complex, hspace_size,hspace_size)
    for i in 2:hspace_size
        a_dag[i,i-1]=sqrt((i-1.0))
    end
    return Operator(a_dag)
end

"""
    Snowflake.destroy(hspace_size)

Returns the bosonic annhilation operator for a Fock space of size `hspace_size`.
"""
function destroy(hspace_size)
    a= zeros(Complex, hspace_size,hspace_size)
    for i in 2:hspace_size
        a[i-1,i]=sqrt((i-1.0))
    end
    return Operator(a)
end

"""
    Snowflake.number_op(hspace_size)

Returns the number operator for a Fock space of size `hspace_size`.
"""
function number_op(hspace_size)
    n= zeros(Complex, hspace_size,hspace_size)
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
julia> ψ = Snowflake.coherent(2.0,20);

julia> print(ψ)
20-element Ket:
0.13533528323661270231781372785917483270168304443359375 + 0.0im
0.2706705664732254046356274557183496654033660888671875 + 0.0im
0.3827859860416437253261507804308297496944779411605434060697044368322244814859633 + 0.0im
0.4420031841663186705315006220668383887063770056788388080454298547413058719111879 + 0.0im
0.4420031841663186705315006220668383887063770056788388080454298547413058719111879 + 0.0im
0.3953396664268989033516298387998153143981494385130297054512994395645417722835952 + 0.0im
0.3227934859426706749083446895240143309122789082442331409841890434072244670369041 + 0.0im
0.2440089396102658373848913914105868080225858281751344102479261185426274154783478 + 0.0im
0.1725403758685577344434702345068468523504659376126805082402433361167676595291802 + 0.0im
0.1150269172457051562956468230045645682336439584084536721601622240778451063527861 + 0.0im
0.07274941014482606043765122911007029674853133081310976424472247415659623989683902 + 0.0im
0.04386954494001140575894979175461054210856445342112420740912216424244799751166167 + 0.0im
0.02532809358034196997591593372015585816248494654573845414140041049288863525802268 + 0.0im
0.01404949847902665677216550321294394000313011924224810466364209088409881639691112 + 0.0im
0.007509772823502763531724947918871845905858490361570411398782773832262018118359266 + 0.0im
0.003878030010563633897440227516084030465660984499951448370503442999620168228954113 + 0.0im
0.001939015005281816948720113758042015232830492249975724185251721499810084114477056 + 0.0im
0.0009405604325217079112661845386949416195293171394724978755464370121167236584289665 + 0.0im
0.0004433844399679012093293182780011289711800019436937749734346315219336842860352511 + 0.0im
0.0002034387333640481868882144439914691756776463670619686354629916554722074664961924 + 0.0im


julia> Snowflake.expected_value(Snowflake.number_op(20),ψ)
3.999999793648639261230596388008292158320219007459973469036845972185905095821291 + 0.0im
```
"""
function coherent(alpha, hspace_size)
    ψ = fock(0,hspace_size)
    for i  in 1:hspace_size-1
        ψ+=(alpha^i)/(sqrt(factorial(big(i))))*fock(i,hspace_size)
    end
    ψ = exp(-0.5*abs2(alpha))*ψ
    return ψ 
end

"""
    Snowflake.normalize!(x::Ket)

Normalizes Ket `x` such that its magnitude becomes unity.
"""
function normalize!(x::Ket)
    a = LinearAlgebra.norm(x.data,2)
    x = 1.0/a*x
    return x
end

"""
    Snowflake.commute(A::Operator, B::Operator)

Returns the commutation of `A` and `B`.
```jldoctest
julia> σ_x = sigma_x()
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
0.0 + 0.0im    1.0 + 0.0im
1.0 + 0.0im    0.0 + 0.0im


julia> σ_y = sigma_y()
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
0.0 + 0.0im    0.0 - 1.0im
0.0 + 1.0im    0.0 + 0.0im


julia> Snowflake.commute(σ_x,σ_y)
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
0.0 + 2.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 - 2.0im
```
"""
function commute(A::Operator, B::Operator)
    return A*B-B*A
end

"""
    Snowflake.anticommute(A::Operator, B::Operator)

Returns the anticommutation of `A` and `B`.
```jldoctest
julia> σ_x = Snowflake.sigma_x()
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
0.0 + 0.0im    1.0 + 0.0im
1.0 + 0.0im    0.0 + 0.0im


julia> Snowflake.anticommute(σ_x,σ_x)
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}: 
2.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    2.0 + 0.0im
```
"""
function anticommute(A::Operator, B::Operator)
    return A*B+B*A
end

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