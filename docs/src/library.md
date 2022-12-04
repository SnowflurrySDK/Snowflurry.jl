# Library

```@meta
DocTestSetup = :(using Snowflake)
```


## Quantum Circuit
```@docs
QuantumCircuit
push_gate!
pop_gate!
simulate
simulate_shots
```

## Quantum Gates
```@docs
Gate
eye
sigma_p
sigma_m
sigma_x
sigma_y
sigma_z
hadamard
phase
pi_8
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
Base.:*(M::Gate, x::Ket)
apply_gate!
```

## Quantum Processing Unit
```@docs
QPU
create_virtual_qpu
```

## Quantum Toolkit

### Basic Quantum Objects

There are three basic quantum objects in Snowflake to simulate a quantum system. These objects are Ket, Bra, and Operator.

```@docs
Ket
Bra
Operator
Base.adjoint
Base.getindex(A::Operator, m::Int64, n::Int64)
eigen
tr
expected_value
kron
MultiBodySystem
commute
anticommute
normalize!
ket2dm
fock_dm
Snowflake.moyal
Snowflake.genlaguerre
get_embed_operator
get_num_qubits(x::Operator)
get_num_qubits(x::Union{Ket, Bra})
get_num_bodies(x::Operator, hilbert_space_size_per_body=2)
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
plot_bloch_sphere(density_matrix::Operator; qubit_id::Int = 1,
    bloch_sphere::BlochSphere = BlochSphere())
BlochSphere
plot_bloch_sphere_animation(ket_list::Vector{Ket};
    qubit_id::Int = 1,
    animated_bloch_sphere::AnimatedBlochSphere = AnimatedBlochSphere())
```
```@raw html
<iframe src="assets/visualize/plot_bloch_sphere_animation_for_ket.html"
style="height:825px;width:100%;">
</iframe>
```
```@docs
plot_bloch_sphere_animation(density_matrix_list::Vector{Operator};
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
