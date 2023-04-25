# Library

```@meta
DocTestSetup = :(using Snowflake, SnowflakePlots)
```


## Quantum Circuit
```@docs
QuantumCircuit
push!
pop!
simulate
simulate_shots
get_measurement_probabilities(circuit::QuantumCircuit)
inv(circuit::QuantumCircuit)
get_num_gates_per_type
get_num_gates
serialize_job
transpile
compare_circuits
circuit_contains_gate_type
```

## Quantum Gates
```@docs
AbstractGate
eye
sigma_p
sigma_m
sigma_x
sigma_y
sigma_z
hadamard
pi_8
pi_8_dagger
x_90
x_minus_90
y_90
y_minus_90
z_90
z_minus_90
rotation
rotation_x
rotation_y
phase_shift
universal
control_z
control_x
iswap
swap
toffoli
iswap_dagger
Base.:*(M::AbstractGate, x::Ket)
apply_gate!
get_operator
inv(gate::AbstractGate)
move_gate(gate::AbstractGate, qubit_mapping::AbstractDict{T,T}) where T<:Integer
move_gate(gate::AbstractGate, new_connected_qubits::AbstractVector{T}) where T<:Integer
```

## Quantum Processing Unit
```@docs
AnyonQPU
VirtualQPU
Client
get_host
submit_circuit
get_status
get_result
run_job
transpile_and_run_job
get_transpiler
SequentialTranspiler
```

## Quantum Toolkit

### Basic Quantum Objects

There are three basic quantum objects in Snowflake to simulate a quantum system. These objects are Ket, Bra, and AbstractOperator.

```@docs
Ket
Bra
DiagonalOperator
AntiDiagonalOperator
DenseOperator
Base.adjoint
is_hermitian
Base.exp(A::AbstractOperator)
Base.getindex(A::AbstractOperator, m::Int64, n::Int64)
eigen
tr
expected_value
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
sesolve
mesolve
compare_kets
```

### Visualization

The [SnowflakePlots](https://github.com/anyonlabs/SnowflakePlots.jl) package provides multiple visualization tools for Snowflake.jl. Please see the documentation of [SnowflakePlots](https://github.com/anyonlabs/SnowflakePlots.jl) for more details. 


```@meta
DocTestSetup = nothing
```
