![Snowflurry](https://repository-images.githubusercontent.com/441460066/2ba724da-60e9-46a6-aa83-9df5891ea783)

# Snowflurry.jl

![CI tests](https://github.com/SnowflurrySDK/Snowflurry.jl/actions/workflows/CI.yml/badge.svg)
[![codecov](https://codecov.io/gh/SnowflurrySDK/Snowflurry.jl/branch/main/graph/badge.svg?token=OB65YO307L)](https://codecov.io/gh/SnowflurrySDK/Snowflurry.jl)

Snowflurry is an open source Julia-based software library for implementing quantum circuits, and then running them on quantum computers and quantum simulators.

# Installation

The following installation steps are for people interested in using Snowflurry in their own applications. If you are interested in contributing, head right over to our [Contributing to Snowflurry page](./CONTRIBUTING.md).

### Installing Julia

Make sure your system has Julia installed. If not, download the latest version from [https://julialang.org/downloads/](https://julialang.org/downloads/).

We officially support the [latest stable release](https://julialang.org/downloads/#current_stable_release) and the [latest Long-Term Support (LTS) release](https://julialang.org/downloads/#long_term_support_release). Any release in-between should work (please submit a Github issue if they don't), but we only actively test against the LTS and the latest stable version.

### Installing `Snowflurry.jl` package
The latest release of Snowflurry can be pulled from [JuliaHub](https://juliahub.com/ui/Packages/General/Snowflurry) and installed with the following command:
```julia
import Pkg
Pkg.add("Snowflurry")
```

This adds the Snowflurry package to the current [Julia Environment](https://pkgdocs.julialang.org/v1/environments/).

Snowflurry is under active development. To use the development version, the `main` branch from Github can be installed instead using the following commands in the Julia REPL:

```julia
import Pkg
Pkg.add(url="https://github.com/SnowflurrySDK/Snowflurry.jl", rev="main")
```

### Installing `SnowflurryPlots.jl` package


Multiple visualization tools are available in the SnowflurryPlots package. After installing
Snowflurry, the SnowflurryPlots package can be installed by entering the following in the
Julia REPL:
```julia
import Pkg
Pkg.add(url="https://github.com/SnowflurrySDK/SnowflurryPlots.jl", rev="main")
```

# Getting Started

The best way to learn Snowflurry is to use it! Let's try to make a two-qubit circuit which produces a [Bell/EPR state](https://en.wikipedia.org/wiki/Bell_state). We'll use Snowflurry to construct and simulate the circuit then verify the produced `Ket`.

The quantum circuit for generating a Bell state involves a Hadamard gate on one of the qubits followed by a CNOT gate (see [here](https://en.wikipedia.org/wiki/Quantum_logic_gate) for an introduction to quantum logic gates). This circuit is shown below:

<div style="text-align: center;">
	<img
		src="./docs/src/images/bell_circuit.svg"
		title="Bell state generator circuit"
		width="240"
	/>
</div>

First import Snowflurry:

```julia
using Snowflurry
```

With Snowflurry imported, we can define our two-qubit circuit.

```julia
c = QuantumCircuit(qubit_count=2)
print(c)

# output
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:

q[2]:
```

In Snowflurry, all qubits start in state $\left|0\right\rangle$. Our circuit is, therefore, in state $\left|00\right\rangle$. The qubit ordering convention used is qubit number 1 on the left, with each following qubit to the right of it. We now proceed by adding gates to our circuit.

```julia
push!(c, hadamard(1))
push!(c, control_x(1, 2))

print(c)

# output
Quantum Circuit Object:
   qubit_count: 2
   bit_count: 2
q[1]:──H────*──
            |
q[2]:───────X──
```

The first line adds a Hadamard gate to circuit object `c` which will operate on qubit 1. The second line adds a CNOT gate (Control-X gate) with qubit 1 as the control qubit and qubit 2 as the target qubit.

**Note**: Unlike C++ or Python, indexing in Julia starts from "1" and not "0"!

Once we've built our circuit, we can consider if it would benefit from applying any transpilation operations. Transpilation is the process of rewriting the sequence of operations in a circuit to a new sequence. As a rule, the new sequence will yield the same quantum state as the old sequence but possibly optimizing the choice of gates used for performance, using only those gates supported by a specific hardware QPU. Since the circuit is relatively small and Snowflurry's simulator can handle all gates, we won't run any transpilation for the time being.

Next, we'll simulate our circuit to see if we've built what we expect.

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

For those who are familar, we recognize that the resultant state is the Bell state; an equal superposition of the $\left|00\right\rangle$ and $\left|11\right\rangle$ states.

Finally, we can use [SnowflurryPlots](https://github.com/SnowflurrySDK/SnowflurryPlots.jl) to generate a histogram which shows the measurement output distribution after taking a certain number of shots, in this case 100, on a quantum
computer simulator:

```julia
using SnowflurryPlots
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
using Snowflurry, SnowflurryPlots
c = QuantumCircuit(qubit_count=2)
push!(c, hadamard(1))
push!(c, control_x(1, 2))
ψ = simulate(c)
plot_histogram(c, 100)
```

You can learn to execute circuits on simulated hardware by following [the Virtual QPU tutorial](https://snowflurrysdk.github.io/Snowflurry.jl/stable/tutorials/run_circuit_virtual.html).

For selected partners and users who have been granted access to Anyon's hardware, follow [the Virtual QPU tutorial](https://snowflurrysdk.github.io/Snowflurry.jl/stable/tutorials/run_circuit_virtual.html) first, then check out how to run circuits [on real hardware](https://snowflurrysdk.github.io/Snowflurry.jl/stable/tutorials/run_circuit_anyon.html).

# Roadmap

See what we have planned by looking at the [Snowflurry Github Project](https://github.com/orgs/SnowflurrySDK/projects/1).

# Snowflurry Contributors Community

We welcome contributions! If you are interested in contributing to this project, a good place to start is to read our [How to Contribute page](./CONTRIBUTING.md).

We are dedicated to cultivating an open and inclusive community to build software for near term quantum computers. Please read our [Code of Conduct](./CODE_OF_CONDUCT.md) for the rules of engagement within our community.

# Alpha Disclaimer

Snowflurry is currently in alpha. We may change or remove parts of Snowflurry's API when making new releases.

Copyright (c) 2023 by Snowflurry Developers and Anyon Systems, Inc.
