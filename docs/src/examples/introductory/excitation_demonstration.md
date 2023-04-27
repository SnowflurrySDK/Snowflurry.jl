# Excitation demonstration

```@meta
DocTestSetup = quote
    ENV["ANYON_QUANTUM_USER"] = "test-user"
    ENV["ANYON_QUANTUM_TOKEN"] = "not-a-real-token"
    ENV["ANYON_QUANTUM_HOST"] = "yukon.anyonsys.com"
end
```

This example is going to show a demonstration of how to excite a qubit into state one.

A Bloch sphere of a system in state one is shown below.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/excitation_bloch.svg"
		title="Excitation demonstration visualization"
		width="240"
	/>
</div>
```

## Theory

We want to take our qubit from state zero to state one. To do this, we must perform a quantum gate. We call the gate we want to perform `X`. We can write down equations for our `X` gate. The `X` gate should take a qubit in state zero to state one and a qubit in state one into state zero.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/x_ket_equations.svg"
		title="X-gate ket equations"
        style="transform: scale(0.5)"
	/>
</div>
```

We can re-write out equations into matrix form.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/x_matrix_equations.svg"
		title="X-gate matrix equations"
        style="transform: scale(0.5)"
	/>
</div>
```

It is trivial to solve `X` as a matrix. 

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/x_matrix.svg"
		title="X-gate matrix"
        style="transform: scale(0.5)"
	/>
</div>
```

Quantum gates are also, in general, represented as matrices. On a single-qubit, a gate is a rotation around the Bloch sphere. The `X`-gate is a 180° rotation around the X-axis.

## Code

We are going to start by importing Snowflake and creating an empty circuit.

```jldoctest excitation_demonstration_example; output = false
using Snowflake

circuit = QuantumCircuit(qubit_count = 1)

# output
Quantum Circuit Object:
   qubit_count: 1
q[1]:
```

We must now apply our X gate to our circuit.

```jldoctest excitation_demonstration_example; output = false
qubit = 1
push!(circuit, sigma_x(qubit))

# output

Quantum Circuit Object:
   qubit_count: 1
q[1]:──X──
```

Our circuit with the X-gate applied, and the implied measurement is shown below.

```@raw html
<div style="text-align: center;">
	<img
		src="../../images/excitation_circuit.svg"
		title="Excitation demonstration circuit"
        style="transform: scale(2)"
	/>
</div>
```

Now we want to run this example on Anyon's Quantum computer. We need to construct an AnyonQPU object. You can get more information on QPU objects at the [Get QPU Metadata example](./get_qpu_metadata.md).

```jldoctest excitation_demonstration_example; output = false
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

Now we run our quantum circuit on Anyon's quantum computer!

```julia
num_repititions = 200
result = run_job(qpu, circuit, num_repititions)

println(result)
```

The results show an overwhelming majority of samples are in state one.

```text
Dict("1" => 191, "0" => 9)
```

## Summary

In this example, we've gone over how to excite a qubit into state one. We've explained that a single qubit gate is a rotation around the Bloch's sphere.

The full code is available at [examples/excitation\_demonstration.jl](https://github.com/anyonlabs/Snowflake.jl/blob/main/examples/excitation_demonstration.jl)
