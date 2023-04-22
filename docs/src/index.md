# Snowflake.jl
```@meta
DocTestSetup = :(using Snowflake)
```
*A library for quantum computing using Julia*

Snowflake is a pure Julia quantum computing stack that allows you to easily design quantum circuits, experiments and algorithms. Snowflake can run these quantum applications on real quantum computers or classical simulators.

!!! warning
	Snowflake has yet to reach version 1.0, but we intend to keep compatibility with what is documented here. We will only make a breaking change if something is broken. After version 1.0, the public API will be stable and only change with major releases.

# Installation

The following installation steps are for people interested in using Snowflake in their own applications. If you are interested in contributing, head right over to our [Contributing to Snowflake page](contributing.md).

### Installing Julia

Make sure your system has Julia installed. If not, download the latest version from [https://julialang.org/downloads/](https://julialang.org/downloads/).

We officially support the [latest stable release](https://julialang.org/downloads/#current_stable_release) and the [latest Long-term support release](https://julialang.org/downloads/#long_term_support_release). Any release in-between should work (please file a bug if they don't), but we only actively test against the LTS and the latest stable version.

### Installing the Snowflake package

Launch a Julia REPL and type:

```julia
import Pkg
Pkg.add("Snowflake")
```

This will add the Snowflake package to the current [Julia Environment](https://pkgdocs.julialang.org/v1/environments/).

# Getting Started

A typical workflow to execute a quantum circuit on a quantum service consists of these three steps.

- Create: Build the circuit using quantum gates.

- Transpile: Transpile the circuit to improve performance and make the circuit compatible with the quantum service.

- Execute: Run the compiled circuits on the specified quantum service. The quantum service could be a remote quantum hardware or a local simulator.

Now, let's try Snowflake by making a two-qubit circuit which implements a [Bell/EPR state](https://en.wikipedia.org/wiki/Bell_state). The quantum circuit for generating a Bell state involves a Hadamard gate on one of the qubits followed by a CNOT gate (see https://en.wikipedia.org/wiki/Quantum_logic_gate for an introduction to quantum logic gates). This circuit is shown below:

```@raw html
<div style="text-align: center;">
	<img
		src="./images/cnot_circuit.svg"
		title="Bell state generator circuit"
		width="240"
	/>
</div>
```
First import Snowflake:

```jldoctest getting_started; output = false
using Snowflake

# output

```

With Snowflake imported, we can define our two-qubit circuit.

```jldoctest getting_started
c = QuantumCircuit(qubit_count=2)
print(c)

# output

Quantum Circuit Object:
   qubit_count: 2
q[1]:

q[2]:
```

In Snowflake, all qubits start in state $\left|0\right\rangle$. Our circuit is, therefore,  in state $\left|00\right\rangle$. We now proceed by adding gates to our circuit.

```jldoctest getting_started
push!(c, [hadamard(1)])
push!(c, [control_x(1, 2)])

print(c)

# output
Quantum Circuit Object:
   qubit_count: 2
q[1]:──H────*──
            |
q[2]:───────X──
```

The first line adds a Hadamard gate to circuit object `c` which will operate on qubit 1. The second line adds a CNOT gate (Control-X gate) with qubit 1 as the control qubit and qubit 2 as the target qubit.

!!! note
	Unlike C++ or Python, indexing in Julia starts from "1" and not "0"!

The next step we want to take is to simulate our circuit. We do not need to transpile our circuit since our simulator can handle all gates, but for larger circuit you should consider transpilation to reduce the amount of work the simulator has to perform.

```jldoctest getting_started
ψ = simulate(c)
print(ψ)

# output
4-element Ket{ComplexF64}:
0.7071067811865475 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.7071067811865475 + 0.0im
```
