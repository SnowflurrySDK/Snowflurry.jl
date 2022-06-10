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

## Quantum Gate
```@docs
sigma_x()
sigma_y()
sigma_z()
sigma_p()
sigma_m()
hadamard()
phase()
pi_8()
eye()
x_90()
control_x()
control_z()
iswap()
sigma_x(target)
sigma_y(target)
sigma_z(target)
hadamard(target)
phase(target)
pi_8(target)
x_90(target)
control_z(control_qubit, target_qubit)
control_x(control_qubit, target_qubit)
iswap(qubit_1, qubit_2)
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
MultiBodySystem
commute
anticommute
normalize!
ket2dm
fock_dm
Snowflake.moyal
Snowflake.genlaguerre
get_embed_operator
fock
create
destroy
number_op
coherent
sesolve
mesolve
```

```@meta
DocTestSetup = nothing
```
