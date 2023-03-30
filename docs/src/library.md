# Library

```@meta
DocTestSetup = :(using Snowflake)
```


## Quantum Circuit
```@docs
QuantumCircuit
push!
pop!
simulate
simulate_shots
get_measurement_probabilities(circuit::QuantumCircuit)
get_inverse(circuit::QuantumCircuit)
get_gate_counts
get_num_gates
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
phase
phase_dagger
pi_8
pi_8_dagger
x_90
rotation
rotation_x
rotation_y
rotation_z
phase_shift
universal
control_z
control_x
iswap
toffoli
iswap_dagger
Base.:*(M::AbstractGate, x::Ket)
apply_gate!
get_operator
get_inverse(gate::AbstractGate)
```

## Quantum Processing Unit
```@docs
QPU
create_virtual_qpu
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
Snowflake.moyal
Snowflake.genlaguerre
get_embed_operator
get_num_qubits(x::AbstractOperator)
get_num_qubits(x::Union{Ket, Bra})
get_num_bodies(x::AbstractOperator, hilbert_space_size_per_body=2)
get_num_bodies(x::Union{Ket, Bra}, hilbert_space_size_per_body=2)
fock
create
destroy
number_op
coherent
sesolve
mesolve
```

### Visualization

Snowflake provides multiple tools for visualizing quantum computer calculations.

```@docs
plot_bloch_sphere(circuit::QuantumCircuit; qubit_id::Int = 1,
    bloch_sphere::BlochSphere = BlochSphere())
plot_bloch_sphere(ket::Ket; qubit_id::Int = 1,
    bloch_sphere::BlochSphere = BlochSphere())
plot_bloch_sphere(density_matrix::AbstractOperator; qubit_id::Int = 1,
    bloch_sphere::BlochSphere = BlochSphere())
BlochSphere
plot_bloch_sphere_animation(ket_list::Vector{Ket{T}} where {T<:Complex};
    qubit_id::Int = 1,
    animated_bloch_sphere::AnimatedBlochSphere = AnimatedBlochSphere())
```
```@raw html
<iframe src="assets/visualize/plot_bloch_sphere_animation_for_ket.html"
style="height:825px;width:100%;">
</iframe>
```
```@docs
plot_bloch_sphere_animation(density_matrix_list::Vector{T} where {T<:AbstractOperator};
    qubit_id::Int = 1,
    animated_bloch_sphere::AnimatedBlochSphere = AnimatedBlochSphere())
```
```@raw html
<iframe src="assets/visualize/plot_bloch_sphere_animation_for_operator.html"
style="height:825px;width:100%;">
</iframe>
```
```@docs
AnimatedBlochSphere
```
```@raw html
<iframe src="assets/visualize/plot_bloch_sphere_animation_without_interpolation.html"
style="height:825px;width:100%;">
</iframe>
```

```@meta
DocTestSetup = nothing
```
