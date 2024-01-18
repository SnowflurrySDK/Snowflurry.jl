# Run a circuit on a Virtual QPU

In the [previous tutorial](basics.md), we introduced some basic concepts of quantum computing, namely the quantum circuit and quantum gates.

We also learnt how to build a quantum circuit using `Snowflurry` and simulate the result of such circuit using our local machine.

In this tutorial, we will cover the steps involved in running a quantum circuit on a virtual Quantum Processing Unit (QPU).


## QPU Object
Interactions with different QPUs are facilitated using `struct`s (objects) that represent QPU hardware.  These structures are used to implement a harmonized interface and are derived from an `abstract type` called `AbstractQPU`. This interface gives you a unified way to write code that is agnostic of the quantum service you are using. The interface dictates how to get metadata about the QPU, how to run a quantum circuit on the QPU, and more.

!!! warning
	You should not use `AbstractQPU`, rather use a QPU object which is derived from `AbstractQPU`. For further details on the implemented derived QPUs, see the [Library page](../library/qpu.md#Quantum-Processing-Unit).

Now that you know what QPU objects are, let's get started by importing `Snowflurry`:
```jldoctest get_qpu_metadata_tutorial; output = false
using Snowflurry

# output

```
### Virtual QPU
Next, we are going to create a virtual QPU which will run on our local machine:

```jldoctest get_qpu_metadata_tutorial; output = true
qpu_v = VirtualQPU()
# output
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflurry.jl

```
We can print QPU's meta data by simply using
```jldoctest get_qpu_metadata_tutorial; output = true
print(qpu_v)
# output
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflurry.jl

```
or alternatively, retrieve the QPU metadata in a `Dict{String,String}` format through the following command:

```jldoctest get_qpu_metadata_tutorial; output = true
get_metadata(qpu_v)
# output
Dict{String, String} with 2 entries:
  "developers" => "Anyon Systems Inc."
  "package"    => "Snowflurry.jl"


```

Now, let's create a circuit to create a Bell pair as was explained in the previous tutorial:

```jldoctest get_qpu_metadata_tutorial; output = true
c = QuantumCircuit(qubit_count = 2)
push!(c, hadamard(1), control_x(1, 2))
# output
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────*──
            |  
q[2]:───────X──
```

Although we've created a circuit that makes a Bell pair, we need to *measure*
something in order to collect any results. In Snowflurry, we can use a
[`Readout`](@ref) instruction to perform a measurement, which are built 
using the [`readout()`](@ref) helper function.

!!! note
	Measurements are always performed in the ``Z`` basis (also known as the computational basis).

```jldoctest get_qpu_metadata_tutorial; output = true
push!(c, readout(1, 1), readout(2, 2))
# output
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──H────*────✲───────
            |            
q[2]:───────X─────────✲──
```
Here we see that a `readout` instruction can be added to a circuit like any
other gate. Each readout instruction needs two parameters: which qubit to
measure and which result bit to write to. For example, `readout(2, 4)` means
"read qubit 2 and store the result in classical bit 4". So, in this example,
the first readout reads from qubit 1 and writes that result to bit 1 of the
result. The second readout does the same for qubit 2 and bit 2 of the result.

In Snowflurry, `readout` instructions can read from any qubit and write to any
result bit but with some restrictions:
- Any `readout` operation must be the final operation applied to its target qubit
  - We plan to lift this restriction in future versions of Snowflurry
- Separate `readout` operations must write to separate result bits

With our measurements defined, we can now run this circuit on the virtual qpu
for let's say 100 shots.

```julia
shots_count = 100
result = run_job(qpu_v, c, shots_count)
```
The `result` object is a `Dict{String, Int64}` that summarizes how many times each state was measured in the shots run on the QPU. 
**It contains only non-zero entries.**

```julia
print(result)

Dict("00" => 53, "11" => 47)
```
Here we see that, after measurement, the classical result bits were set to $\left|00\right\rangle$
in 53 of the 100 shots. In the other 47 shots, the result bits were set to $\left|11\right\rangle$.

!!! note
	The reason the number of measured values for states $\left|00\right\rangle$ and $\left|11\right\rangle$ are not necessarily equal is due to the fact that `VirtualQPU` tries to mimic the statistical nature of real hardware. By increasing the `shots_count` the experiment will confirm that the probability of  $\left|00\right\rangle$ and  $\left|11\right\rangle$ are equal.


The virtual QPU currently mimics an ideal hardware with no error. Therefore, the states  $\left|01\right\rangle$ and  $\left|10\right\rangle$ have a probability of zero, and they are never measured. 
In future versions, we expect to add noise models for sources such as crosstalk, thermal noise, etc.

In the [next tutorial](@ref "Running a Circuit on Real Hardware"), we will show how to submit a job to real quantum processing hardware.
