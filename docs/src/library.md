# Library

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

There are three basic quantum objects defined in Snowflake to simulate a Quantum system. These objects are Ket, Bra, and Operator.

```@docs
Ket
Bra
Operator
commute
anticommute
normalize
ket2dm
fock_dm
```


```@docs
MultiBodySystem
get_embed_operator
```

```@docs
fock
create
destroy
number_op
coherent
```
