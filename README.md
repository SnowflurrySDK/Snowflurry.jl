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
Snowflurry is still in pre-release phase. Therefore, and for the time being, we recommend installing it by checking out the `main` branch from Github. This is achieved by typing the following commands in the Julia REPL:

```julia
import Pkg
Pkg.add(url="https://github.com/SnowflurrySDK/Snowflurry.jl", rev="main")
```
This adds the Snowflurry package to the current [Julia Environment](https://pkgdocs.julialang.org/v1/environments/).

**Note:** once `Snowflurry.jl` is released to [JuliaHub](https://https://juliahub.com/), it will be possible to import the latest release using the following command:
```julia
import Pkg
Pkg.add("Snowflurry")
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

A typical workflow to execute a quantum circuit on a quantum service consists of these three steps.

- Create: Build the circuit using quantum gates.

- Transpile: transform the circuit into an equivalent one, but with improved performance and ensuring compatibility with the chosen quantum service.

- Execute: Run the compiled circuits on the specified quantum service. The quantum service could be a remote quantum hardware or a local simulator.

Now, let's try Snowflurry by making a two-qubit circuit which implements a [Bell/EPR state](https://en.wikipedia.org/wiki/Bell_state). The quantum circuit for generating a Bell state involves a Hadamard gate on one of the qubits followed by a CNOT gate (see [here](https://en.wikipedia.org/wiki/Quantum_logic_gate) for an introduction to quantum logic gates). This circuit is shown below:

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
q[1]:

q[2]:
```

In Snowflurry, all qubits start in state $\left|0\right\rangle$. Our circuit is, therefore,  in state $\left|00\right\rangle$. The qubit ordering convention used is qubit number 1 on the left, with each following qubit to the right of it. We now proceed by adding gates to our circuit.

```julia
push!(c, hadamard(1))
push!(c, control_x(1, 2))

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

The next step we want to take is to execute our circuit. Instead of submitting a job to a remote quantum service, we will use Snowflurry's built-in simulator. We do not need to transpile our circuit since our simulator can handle all gates, but for larger circuit you should consider transpilation to reduce the amount of work the simulator has to perform.

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

Finally, we can use [SnowflurryPlots](https://github.com/SnowflurrySDK/SnowflurryPlots.jl) to generate a histogram which shows the measurement
output distribution after taking a certain number of shots, in this case 100, on a quantum
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
push!(c, readout(1, 1))
push!(c, readout(2, 2))
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
