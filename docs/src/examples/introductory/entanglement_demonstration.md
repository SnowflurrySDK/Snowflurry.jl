# Entanglement demonstration example

```@meta
DocTestSetup = quote
    ENV["ANYON_QUANTUM_USER"] = "test-user"
    ENV["ANYON_QUANTUM_TOKEN"] = "not-a-real-token"
    ENV["ANYON_QUANTUM_HOST"] = "yukon.anyonsys.com"
end
```

This example is going to demonstrate entanglement by preparing and measuring a bell state.

## Theory

Bell states are a set of maximually entangled states. We are going to look at one of these states, $\frac{\left|00\right\rangle+\left|11\right\rangle}{\sqrt{2}}$, today.

The $\frac{\left|00\right\rangle+\left|11\right\rangle}{\sqrt{2}}$ state can be constructed using the following circuit.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/entanglement_circuit.svg"
		title="Bell-state generator"
        style="transform: scale(2);margin: 2em"
	/>
</div>
```

The Hadamard gate on the first qubit puts the first qubit into state $\frac{\left|0\right\rangle+\left|1\right\rangle}{\sqrt{2}}$. Since the second qubit remains unchanged, the total system is in state $\frac{\left|00\right\rangle+\left|10\right\rangle}{\sqrt{2}}$

After applying the controlled X gate on qubits one and two. If the first qubit is in state zero then nothing happens to the second qubits. State $\left|00\right\rangle$, therefore, stays the same. If the first qubit is in state one the second qubti is flipped. State $\left|10\right\rangle$, therefore, becomes state $\left|11\right\rangle$. After the controlled-X gate the system's state is there now $\frac{\left|00\right\rangle+\left|11\right\rangle}{\sqrt{2}}$

The two qubit's states are now entangled. If you measure one of the qubits you also get information about the other qubit's state. They are no longer independant.

## Code

We are going to start by importing Snowflake and creating our circuit.

```jldoctest entanglement_demonstration_example; output = false
using Snowflake

circuit = QuantumCircuit(qubit_count = 2)

# output

Quantum Circuit Object:
   qubit_count: 2
q[1]:

q[2]:
```

We must now apply our gates to our circuit.

```jldoctest entanglement_demonstration_example; output = false
push!(circuit, [hadamard(1), control_x(1, 2)])

# output

Quantum Circuit Object:
   qubit_count: 2
q[1]:──H────*──
            |
q[2]:───────X──
```

Now we want to run this example on Anyon's Quantum computer. We need to construct an AnyonQPU object. You get more information on QPU objects at the [Get QPU Metadata example](./get_qpu_metadata.md).

```jldoctest entanglement_demonstration_example; output = false
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
```

We cannot run our circuit directly on the QPU since neither the Hadamard gate or the CX gate is a native gate of Anyon's Quantum Computer. We first have to transpile the circuit.

```jldoctest entanglement_demonstration_example; output = false
transpiler = get_transpiler(qpu)
transpiled_circuit = transpile(transpiler, circuit)

# output

Quantum Circuit Object:
   qubit_count: 2
Part 1 of 2
q[1]:──Z────X_90────Z_90────X_m90──────────────────────────────────*──
                                                                   |
q[2]:────────────────────────────────Z────X_90────Z_90────X_m90────Z──


Part 2 of 2
q[1]:──────────────────────────────

q[2]:──Z────X_90────Z_90────X_m90──
```

Now we run our quantum circuit on Anyon's quantum computer!

```julia
num_repititions = 200
result = run_job(qpu, transpiled_circuit, num_repititions)

println(result)
```

The results show that the samples are mostly sampled between state $\left|00\right\rangle$ and $\left|11\right\rangle$.

```text
Dict("11" => 97, "00" => 83, "01" => 11, "10" => 9)
```

## Summary

In this example, we've shown how to generate one of the Bell states. With this we've demonstrated entanglement between two qubits.

The full code for this example is available at [examples/entanglement\_demonstration.jl](https://github.com/anyonlabs/Snowflake.jl/blob/main/examples/entanglement_demonstration.jl)
