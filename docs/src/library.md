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
CliffordOperator
get_clifford_operator
PauliGroupElement
get_pauli_group_element
```

```@meta
DocTestSetup = nothing
```
