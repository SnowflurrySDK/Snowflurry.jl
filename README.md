![Snowflake](https://repository-images.githubusercontent.com/441460066/2fac88f2-d91f-4159-b35c-82d56d3719f5)

# Snowflake.jl

![CI tests](https://github.com/anyonlabs/Snowflake.jl/actions/workflows/CI.yml/badge.svg)
[![codecov](https://codecov.io/gh/anyonlabs/Snowflake.jl/branch/next/graph/badge.svg?token=OB65YO307L)](https://codecov.io/gh/anyonlabs/Snowflake.jl)

Snowflake is an open source Julia-based software library for implementing quantum circuits, and then running them on quantum computers and quantum simulators.

# Get Started

Make sure your system has Julia installed. If not, download the latest version from [https://julialang.org/downloads/](https://julialang.org/downloads/).

# Installation

Launch julia REPL and add Snowflake latest revision using the following commands

```julia
import Pkg
Pkg.add("https://github.com/anyonlabs/Snowflake.jl#next")
```

# Get Started

Like other Julia Packages, you can use Snowflake in a [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/), in a [Julia script](https://docs.julialang.org/en/v1/manual/getting-started/), or in a [notebook](https://docs.julialang.org/en/v1/manual/getting-started/).

Now let's try Snowflake by making a two qubit circuit which implements a [Bell/EPR state](https://en.wikipedia.org/wiki/Bell_state). The quantum circuit achiving a Bell state involves a Hadamard gate on one of the qubits followed by a CNOT gate (see https://en.wikipedia.org/wiki/Quantum_logic_gate for an introduction to quantum logic gates). This circuit is show below:

![Bell State generator circuit](https://upload.wikimedia.org/wikipedia/commons/f/fc/The_Hadamard-CNOT_transform_on_the_zero-state.png)

First import Snowflake:

```julia
using Snowflake
```

Then lets define a two qubit circuit:

```julia
c = Circuit(qubit_count=2, bit_count=0)
```

If you are using Julia REPL you should see an output similar to:

```
Circuit Object:
   id: 1e9c4f6e-64df-11ec-0c5b-036aab5b72cb
   qubit_count: 2
   bit_count: 0
q[1]:

q[2]:
```

Note the circuit object has been given a Universally Unique Identifier (UUID). This UUID can be used later to retrieve the circuit results from a remote server such as a quantum computer on the cloud.

Now let's build the circuit using the following commands:

```julia
pushGate!(c, [hadamard(1)])
pushGate!(c, [control_x(1, 2)])
```

The first line adds a Hadamrd gate which will operate on qubit 1. The second line adds a CNOT gate (Control-X gate) with control qubit being qubit 1 and target qubit being qubit 2. The output in Julia REPL would look like:

```julia
Circuit Object:
   id: 1e9c4f6e-64df-11ec-0c5b-036aab5b72cb
   qubit_count: 2
   bit_count: 0
q[1]:--H----*--
            |
q[2]:-------X--
```

**Note:** Unlike C++ or Python, indexing in Julia starts from "1" and not "0"!

Finally you can simulate this circuit and obtain the final quantum state of this two-qubit register:

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

c = Circuit(qubit_count=2, bit_count=0)
pushGate!(c, [hadamard(1)])
pushGate!(c, [control_x(1, 2)])
ψ = simulate(c)
```

# Snowflake Contributors Community

We welcome contributions! If you are interested in contributing to this project, a good place to start is to read our guidelines.

We are dedicated to cultivating an open and inclusive community to build software for near term quantum computers. Please read our code of conduct for the rules of engagement within our community.

# Alpha Disclaimer

Snowflake is currently in alpha. We may change or remove parts of Snowflake's API when making new releases.

Copyright (c) 2021 by Snowflake Developers and Anyon Systems, Inc.
