# Single-qubit readout example

```@meta
DocTestSetup = quote
    ENV["ANYON_QUANTUM_USER"] = "test-user"
    ENV["ANYON_QUANTUM_TOKEN"] = "not-a-real-token"
    ENV["ANYON_QUANTUM_HOST"] = "yukon.anyonsys.com"
end
```

This example is going to show you how to construct a circuit and measure the circuit without any operations. During this example, we will discuss initialization, readout, and readout fidelity.


A Bloch sphere of a system in state zero is shown below.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/readout_zero_bloch.svg"
		title="Zero-state readout visualization"
		width="240"
	/>
</div>
```

## Code

We are going to start by importing Snowflake.

```jldoctest single_qubit_readout_example; output = false
using Snowflake

# output

```

This will bring all Snowflake's imports into the local scope for us to use. Next, we will create our circuit.


```jldoctest single_qubit_readout_example; output = false
circuit = QuantumCircuit(qubit_count = 1)

# output
Quantum Circuit Object:
   qubit_count: 1
q[1]:
```

The circuit has no gates and consists and consists of one quantum register. In Snowflake, quantum registers always start initialized in state zero. The newly created circuit is shown below.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/empty_circuit.svg"
		title="Empty circuit"
        style="transform: scale(2);"
	/>
</div>
```

In Snowflake, circuits have an implied measurement operation at the end of the circuit. Other SDKs, such as [Cirq](https://quantumai.google/cirq) and [Qiskit](https://qiskit.org/), readout operations must be explicitly added to a circuit. The circuit with the readout drawn in is shown below.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/single_qubit_readout_circuit.svg"
		title="Single-qubit readout circuit"
        style="transform: scale(2);"
	/>
</div>
```

Now we want to run this example on Anyon's Quantum computer. We need to construct an AnyonQPU object. You can get more information on QPU objects at the [Get QPU Metadata example](./get_qpu_metadata.md).

```jldoctest single_qubit_readout_example; output = false
user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

qpu = AnyonQPU(host=host, user=user, access_token=token)

# output

Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6
   connectivity_type:  linear
```

Now we run our quantum circuit on Anyon's quantum computer!

```julia
num_repetitions = 200
result = run_job(qpu, circuit, num_repetitions)

println(result)
```

We have our first results! The results are stored in a dictionary where the keys are the states measured, and the values are how many times those states were measured.

```text
Dict("1" => 3, "0" => 197)
```

When you run it yourself, you will see that you don't always get exactly the same result. Don't worry. This is what is expected. When reading out a result, you are sampling from a distribution. The randomness in the samples is what makes the result vary between runs.

From the result, we can see that we have a very high estimated state preparation and readout fidelity of 98.5%! We can only estimate the true readout fidelity since we are sampling from a distribution. You might also be wondering why it is not 100%. In an analogue system, you cannot perfectly set and measure levels. Quantum systems are no different. In quantum systems, these errors are called State preparation and measurement (SPAM) errors.

## Summary

In this example, we've gone over how to construct and readout a single qubit circuit. We've discussed state initialization, readout fidelity, and state preparation and measurement errors.

The full code for this example is available at [examples/single\_qubit\_readout\_fidelity.jl](https://github.com/anyonlabs/Snowflake.jl/blob/main/examples/single_qubit_readout_fidelity.jl)
