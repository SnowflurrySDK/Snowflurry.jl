# Getting Started

A typical workflow to execute a quantum circuit on a quantum service consists of these three steps.

- Create: Build the circuit using quantum gates.

- Transpile: Transpile the circuit to improve performance and make the circuit compatible with the quantum service.

- Execute: Run the compiled circuits on the specified quantum service. The quantum service could be a remote quantum hardware or a local simulator.

## Create a Circuit
Now, let's try Snowflake by making a two-qubit circuit which implements a [Bell/EPR state](https://en.wikipedia.org/wiki/Bell_state). The quantum circuit for generating a Bell state involves a Hadamard gate on one of the qubits followed by a CNOT gate (see https://en.wikipedia.org/wiki/Quantum_logic_gate for an introduction to quantum logic gates). This circuit is shown below:

```@raw html
<div style="text-align: center;">
	<img
		src="./images/bell_circuit.svg"
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

Finally, you can use [SnowflakePlots](https://github.com/anyonlabs/SnowflakePlots.jl) to generate a histogram which shows the measurement
output distribution after taking a certain number of shots, in this case 100, on a quantum
computer simulator:

```julia
using SnowflakePlots
plot_histogram(c, 100)
```
![Measurement results histogram](assets/index/index_histogram.png)

The script below puts all the steps above together:

```julia
using Snowflake, SnowflakePlots
c = QuantumCircuit(qubit_count=2)
push!(c, hadamard(1))
push!(c, control_x(1, 2))
ψ = simulate(c)
plot_histogram(c, 100)
```

## Execute on hardware

Let's see how how to submit the circuit created in the previous section to a virtual or real hardware. 
### Virtual QPU
We can use Snowflake to create a virtual QPU on our local machine:
```jldoctest getting_started
qpu=VirtualQPU()
print(qpu)
# output
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflake.jl
```
Note the `print(qpu)` command is used to print relevant information about the QPU.

Because a virtual QPU can simulate any circuit as it is, we do not need to peform any compilation or tests to run the jobs on the virtual QPU. We can then simply run the job on the qpu for a given number of shots. 
```julia
shots_count=100
result=run_job(qpu, c,shots_count)
```
The `result` variable is a dictionary representing the histogram of the measurement results:
```julia
print(result)
Dict{String, Int64} with 2 entries:
  "00" => 54
  "11" => 46
```
The above output shows that both qubits were measured to be in state '0' in 54 shots out of 100 tries on the virtual QPU. Similarly, both qubits were measured to be in state `1` for 46 shots out of 100 shots run on the QPU. We can achieve statistical convergence by increasing the `shots_count` and observe that outcomes are mesaured with equal probability.

