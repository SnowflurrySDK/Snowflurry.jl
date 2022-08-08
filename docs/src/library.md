# Library

```@meta
DocTestSetup = :(using Snowflake)
```


## Quantum Circuit
```@docs
QuantumCircuit
push_gate!
pop_gate!
append!(base_circuit::QuantumCircuit, circuits_to_append::QuantumCircuit...)
get_wider_circuit
get_reordered_circuit
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
get_random_clifford
PauliGroupElement
get_pauli_group_element
push_clifford!
```

## Benchmarking
### Randomized Benchmarking
Snowflake has tools for conducting randomized benchmarking following the approach of
[Magesan, Gambetta, and Emerson (2012)](http://dx.doi.org/10.1103/PhysRevA.85.042311).

```@docs
run_randomized_benchmarking
RandomizedBenchmarkingProperties
RandomizedBenchmarkingFitProperties
RandomizedBenchmarkingResults
RandomizedBenchmarkingFitResults
plot_benchmarking
```

```@meta
DocTestSetup = nothing
```
