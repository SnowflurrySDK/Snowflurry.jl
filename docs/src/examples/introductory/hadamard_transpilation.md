# Hadamard transpilation example

```@meta
DocTestSetup = quote
    ENV["ANYON_QUANTUM_USER"] = "test-user"
    ENV["ANYON_QUANTUM_TOKEN"] = "not-a-real-token"
    ENV["ANYON_QUANTUM_HOST"] = "yukon.anyonsys.com"
end
```

This example is going to introduce the Hadamard gate. Also, this example demonstrates how to use a transpiler to run a non-native gate, the Hadamard gate, on Anyon's Quantum Computer.

## Theory

A hadamard gate is a 180° rotation around a tilted axis and is defined by the following unitary.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/hadamard_matrix.svg"
		title="Hadamard matrix"
        style="transform: scale(0.5);"
	/>
</div>
```

A Bloch sphere representation of a Hadamard gate applied to state zero is shown below.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/hadamard_bloch.svg"
		title="Hadamard visualization visualization"
		width="240"
	/>
</div>
```


## Code

We are going to start by importing Snowflake.

```jldoctest transpiled_hadamard_example; output = false
using Snowflake

circuit = QuantumCircuit(qubit_count = 1)

# output

Quantum Circuit Object:
   qubit_count: 1
q[1]:
```

We must now apply our Hadamard gate to our circuit.

```jldoctest transpiled_hadamard_example; output = false
push!(circuit, hadamard(1))

# output

Quantum Circuit Object:
   qubit_count: 1
q[1]:──H──
```

Our circuit with the Hadamard-gate applied, and the implied measurement is shown below.


```@raw html
<div style="text-align: center;">
	<img
		src="../../images/hadamard_circuit.svg"
		title="Hadamard circuit"
        style="transform: scale(2);"
	/>
</div>
```

Now we want to run this example on Anyon's Quantum computer. We need to construct an AnyonQPU object. You can get more information on QPU objects at the [Get QPU Metadata example](./get_qpu_metadata.md).

```jldoctest transpiled_hadamard_example; output = false
user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

client = Client(host=host, user=user, access_token=token)
qpu = AnyonQPU(client)

# output

Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6
   connectivity_type:  linear
```

We cannot run our circuit directly on the QPU since the Hadamard gate is not a native gate of Anyon's Quantum Computer. The circuit first has to be transpiled. Transpilation is an object that can transform a circuit into a functionally equivalent circuit with a different form. To get a transpiler which can take an arbitrary circuit and transpile it into something that can run natively on a QPU, one has to use the `get_transpiler` on the QPU. With this transpiler, one can call the `transpile` function to transpile the circuit using the transpiler.

```jldoctest transpiled_hadamard_example; output = false
transpiler = get_transpiler(qpu)
transpiled_circuit = transpile(transpiler, circuit)

# output

Quantum Circuit Object:
   qubit_count: 1 
q[1]:──Z_90────X_90────Z_90──
```

The transpiled circuit is shown below.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/transpiled_hadamard_circuit.svg"
		title="Transpiled Hadamard circuit"
        style="transform: scale(2);"
	/>
</div>
```

Now we run our quantum circuit on Anyon's quantum computer!

```julia
num_repititions = 200
result = run_job(qpu, transpiled_circuit, num_repititions)

println(result)
```

The results show that the samples are randomly distributed between state zero and state one.

```text
Dict("1" => 109, "0" => 91)
```

## Summary

In this example, we've introduced the Hadamard gate. We've also demonstrated how to use a transpiler to transpile any circuit into a circuit which can be natively run on AnyonQPU.

The full code for this example is available at [examples/hadamard\_transplation.jl](https://github.com/anyonlabs/Snowflake.jl/blob/main/examples/hadamard_transpilation.jl)
