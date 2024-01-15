# Quantum Toolkit

## Basic Quantum Objects

There are three basic quantum objects in Snowflurry to simulate a quantum system. These objects are `Ket`, `Bra`, and `AbstractOperator`.

```@docs
Ket
Bra
DiagonalOperator
AntiDiagonalOperator
DenseOperator
SwapLikeOperator
IdentityOperator
SparseOperator
Readout
readout
Base.adjoint
is_hermitian
Base.exp(A::AbstractOperator)
Base.getindex(A::AbstractOperator, m::Int64, n::Int64)
expected_value(A::AbstractOperator, psi::Ket)
sparse
eigen
tr
kron
MultiBodySystem
commute
anticommute
normalize!
get_measurement_probabilities(x::Ket{Complex{T}}) where T<:Real
ket2dm
fock_dm
wigner
moyal
genlaguerre
get_embed_operator
get_num_qubits(x::AbstractOperator)
get_num_qubits(x::Union{Ket, Bra})
get_num_bodies(x::AbstractOperator, hilbert_space_size_per_body=2)
get_num_bodies(x::Union{Ket, Bra}, hilbert_space_size_per_body=2)
fock
spin_up
spin_down
create
destroy
number_op
coherent
compare_kets
```