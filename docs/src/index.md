# Snowflake.jl
```@meta
DocTestSetup = :(using Snowflake)
```
*A library for quantum computing using Julia*


Snowflake is a pure Julia quantum computing stack that allows you to easily design quantum circuits, algorithms, experiments and applications. Julia can then run them on real quantum computers and/or classical simulators. 

!!! warning
    The documentation of Snowflake is still a work in progress. That being said, a lot can be learnt from the unit tests in the test folder.

# Installation

Make sure your system has Julia (v.1.6 or a more recent version) installed. If not, download the latest version from [https://julialang.org/downloads/](https://julialang.org/downloads/).

Launch Julia REPL and type:
```julia
import Pkg
Pkg.add("Snowflake")
```
If you intend to use a particular development branch from github repo, you can use the following commands:
```julia
import Pkg
Pkg.add(url="https://github.com/anyonlabs/Snowflake.jl", rev="BRANCH_NAME")
```

**Note:** Replace the `BRANCH_NAME` with the name of the branch you want to use. The stable release is `main` and the most up-to-date one is `next`.


# Get Started
Like other Julia Packages, you can use Snowflake in a [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/), in a [Julia script](https://docs.julialang.org/en/v1/manual/getting-started/), or in a [notebook](https://docs.julialang.org/en/v1/manual/getting-started/).

A typical workflow to use a quantum computer consists of the following four steps:

- Build: Design a quantum circuit(s) that represents the problem you are considering.

- Compile: Compile circuits for a specific quantum service, e.g. a quantum system or classical simulator.

- Run: Run the compiled circuits on the specified quantum service(s). These services can be cloud-based or local.

- Postprocess: Compute summary statistics and visualize the results of the experiments.

Now, let's try Snowflake by making a two-qubit circuit which implements a [Bell/EPR state](https://en.wikipedia.org/wiki/Bell_state). The quantum circuit for generating a Bell state involves a Hadamard gate on one of the qubits followed by a CNOT gate (see https://en.wikipedia.org/wiki/Quantum_logic_gate for an introduction to quantum logic gates). This circuit is shown below:

![Bell State generator circuit](https://upload.wikimedia.org/wikipedia/commons/f/fc/The_Hadamard-CNOT_transform_on_the_zero-state.png)

First import Snowflake:

```julia
using Snowflake
```

Then, let's define a two-qubit circuit:

```julia
c = QuantumCircuit(qubit_count=2, bit_count=0)
```

If you are using Julia REPL, you should see an output similar to:

```
Quantum Circuit Object:
   id: 1e9c4f6e-64df-11ec-0c5b-036aab5b72cb
   qubit_count: 2
   bit_count: 0
q[1]:

q[2]:
```

Note that the circuit object has been given a Universally Unique Identifier (UUID). This UUID can be used later to retrieve the circuit results from a remote server such as a quantum computer on the cloud.

Now, let's build the circuit using the following commands:

```julia
push_gate!(c, [hadamard(1)])
push_gate!(c, [control_x(1, 2)])
```

The first line adds a Hadamard gate to circuit object `c` which will operate on qubit 1. The second line adds a CNOT gate (Control-X gate) with qubit 1 as the control qubit and qubit 2 as the target qubit. The output in Julia REPL would look like:

```julia
Quantum Circuit Object:
   id: 1e9c4f6e-64df-11ec-0c5b-036aab5b72cb
   qubit_count: 2
   bit_count: 0
q[1]:──H────*──
            |
q[2]:───────X──
```

**Note:** Unlike C++ or Python, indexing in Julia starts from "1" and not "0"!

Finally, you can simulate this circuit and obtain the final quantum state of this two-qubit register:

```julia
ψ = simulate(c)
```

which would give:

```julia
4-element Ket:
0.7071067811865475 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.7071067811865475 + 0.0im
```

**Note:** Snowflake always assumes a qubit is initialized in state 0.

The script below puts all the steps above together:

```julia
using Snowflake

c = QuantumCircuit(qubit_count=2, bit_count=0)
push_gate!(c, [hadamard(1)])
push_gate!(c, [control_x(1, 2)])
ψ = simulate(c)
```

```@meta
DocTestSetup = nothing
```
