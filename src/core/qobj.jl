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
Base.getindex(A::Operator, m::Int64, n::Int64) = Base.getindex(A.data, m, n)

eigen(A::Operator) = LinearAlgebra.eigen(A.data)
expected_value(A::Operator, psi::Ket) = (Bra(psi)*(A*psi))


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
    d[i+1] = 1.0
    return Ket(d)
end

function create(hspace_size)
    a_dag = zeros(Complex, hspace_size,hspace_size)
    for i in 2:hspace_size
        a_dag[i,i-1]=sqrt((i-1.0))
    end
    return Operator(a_dag)
end

function destroy(hspace_size)
    a= zeros(Complex, hspace_size,hspace_size)
    for i in 2:hspace_size
        a[i-1,i]=sqrt((i-1.0))
    end
    return Operator(a)
end

function number_op(hspace_size)
    n= zeros(Complex, hspace_size,hspace_size)
    for i in 2:hspace_size
        n[i,i]=i-1.0
    end
    return Operator(n)
end

function coherent(alpha, hspace_size)
    ψ = fock(0,hspace_size)
    for i  in 1:hspace_size-1
        ψ+=(alpha^i)/(sqrt(factorial(big(i))))*fock(i,hspace_size)
    end
    ψ = exp(-0.5*abs2(alpha))*ψ
    return ψ 
end

function normalize!(x::Ket)
    a = LinearAlgebra.norm(x.data,2)
    x = 1.0/a*x
    return x
end

function commute(A::Operator, B::Operator)
    return A*B-B*A
end

function anticommute(A::Operator, B::Operator)
    return A*B+B*A
end

"""
    Snowflake.ket2dm(ψ)

Returns the density matrix corresponding to the pure state ψ 
"""

function ket2dm(ψ::Ket)
    return ψ*Bra(ψ)
end

"""
    Snowflake.fock_dm(i, hspace_size)

Returns the density matrix corresponding to fock base `i` defined in a hilbert space size of `hspace_size`.
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

Returns the Moyal function `w_mn(eta)` for fock states `m` and `n`.
"""
function moyal(eta, m,n)
    L = genlaguerre(4.0*abs2(eta),m-n, n)
    w_mn = 2.0*(-1)^n/pi*sqrt(factorial(big(n))/factorial(big(m)))*(2.0*conj(eta))^(m-n)*exp(-2.0*abs2(eta))*L
    return w_mn
end


"""
    Snowflake.laguerre(x::Real,n::UInt)
    Returns the value of Laguerre polynomial of degree `n` for `x` using a recursive method. See https://en.wikipedia.org/wiki/Laguerre_polynomials
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