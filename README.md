![Snowflake](https://repository-images.githubusercontent.com/441460066/a4572ad1-6421-4679-aa31-4c2a45829dc6)

# Snowflake.jl

![CI tests](https://github.com/anyonlabs/Snowflake.jl/actions/workflows/CI.yml/badge.svg)
[![codecov](https://codecov.io/gh/anyonlabs/Snowflake.jl/branch/main/graph/badge.svg?token=OB65YO307L)](https://codecov.io/gh/anyonlabs/Snowflake.jl)

Snowflake is an open source Julia-based software library for implementing quantum circuits, and then running them on quantum computers and quantum simulators.

# Installation

The following installation steps are for people interested in using Snowflake in their own applications. If you are interested in contributing, head right over to our [Contributing to Snowflake page](./docs/src/contributing.md).

### Installing Julia

Make sure your system has Julia installed. If not, download the latest version from [https://julialang.org/downloads/](https://julialang.org/downloads/).

We officially support the [latest stable release](https://julialang.org/downloads/#current_stable_release) and the [latest Long-term support release](https://julialang.org/downloads/#long_term_support_release). Any release in-between should work (please file a bug if they don't), but we only actively test against the LTS and the latest stable version.

### Installing `Snowflake.jl` package
Snowflake is still in pre-release phase. Therefore, and for the time being, we recommand installing it by checking out the `main` branch from github. This can be achieved by typing the following commands in the Julia REPL:

```julia
import Pkg
Pkg.add(url="https://github.com/anyonlabs/Snowflake.jl", rev="main")
```
This will add the Snowflake  package to the current [Julia Environment](https://pkgdocs.julialang.org/v1/environments/).

**Note** Once `Snowflake.jl` is released, you can install the latest release using the following command:
	```julia
	import Pkg
	Pkg.add("Snowflake")
	```

### Installing `SnowflakePlots.jl` package


Multiple visualization tools are available in the SnowflakePlots package. After installing
Snowflake, the SnowflakePlots package can be installed by entering the following in the
Julia REPL:
```julia
import Pkg
Pkg.add(url="https://github.com/anyonlabs/SnowflakePlots.jl", rev="main")
```

# Getting Started

A typical workflow to execute a quantum circuit on a quantum service consists of these three steps.

- Create: Build the circuit using quantum gates.

- Transpile: Transpile the circuit to improve performance and make the circuit compatible with the quantum service.

- Execute: Run the compiled circuits on the specified quantum service. The quantum service could be a remote quantum hardware or a local simulator.

Now, let's try Snowflake by making a two-qubit circuit which implements a [Bell/EPR state](https://en.wikipedia.org/wiki/Bell_state). The quantum circuit for generating a Bell state involves a Hadamard gate on one of the qubits followed by a CNOT gate (see [here](https://en.wikipedia.org/wiki/Quantum_logic_gate) for an introduction to quantum logic gates). This circuit is shown below:

<div style="text-align: center;">
	<img
		src="./docs/src/images/bell_circuit.svg"
		title="Bell state generator circuit"
		width="240"
	/>
</div>

First import Snowflake:

```julia
using Snowflake
```

With Snowflake imported, we can define our two-qubit circuit.

```julia
c = QuantumCircuit(qubit_count=2)
print(c)

# output
Quantum Circuit Object:
   qubit_count: 2
q[1]:

q[2]:
```

In Snowflake, all qubits start in state $\left|0\right\rangle$. Our circuit is, therefore,  in state $\left|00\right\rangle$. We now proceed by adding gates to our circuit.

```julia
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

**Note**: Unlike C++ or Python, indexing in Julia starts from "1" and not "0"!

The next step we want to take is to simulate our circuit. We do not need to transpile our circuit since our simulator can handle all gates, but for larger circuit you should consider transpilation to reduce the amount of work the simulator has to perform.

```julia
ψ = simulate(c)
print(ψ)

# output
4-element Ket{ComplexF64}:
0.7071067811865475 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.7071067811865475 + 0.0im
```

Finally, we can use [SnowflakePlots](https://github.com/anyonlabs/SnowflakePlots.jl) to generate a histogram which shows the measurement
output distribution after taking a certain number of shots, in this case 100, on a quantum
computer simulator:

```julia
using SnowflakePlots
plot_histogram(c, 100)
```

<div style="text-align: center;">
	<img
		src="./docs/src/assets/index/index_histogram.png"
		title="Bell state generator circuit"
		width="520
		"
	/>
</div>

The script below puts all the steps above together:

```julia
using Snowflake, SnowflakePlots
c = QuantumCircuit(qubit_count=2)
push!(c, [hadamard(1)])
push!(c, [control_x(1, 2)])
ψ = simulate(c)
plot_histogram(c, 100)
```

# Roadmap

See what we have planned by looking at the [Snowflake Github Project](https://github.com/orgs/anyonlabs/projects/8).

# Snowflake Contributors Community

We welcome contributions! If you are interested in contributing to this project, a good place to start is to read our [How to contribute page](./docs/src/contributing.md).

We are dedicated to cultivating an open and inclusive community to build software for near term quantum computers. Please read our code of conduct for the rules of engagement within our community.

# Alpha Disclaimer

Snowflake is currently in alpha. We may change or remove parts of Snowflake's API when making new releases.

Copyright (c) 2023 by Snowflake Developers and Anyon Systems, Inc.
