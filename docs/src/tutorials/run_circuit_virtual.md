# Run a circuit on a Virtual QPU

In the previous tutorial, we introduced some basic concepts of quantum computing, namely the quantum circuit and quantum gates. 

We also learnt how to build a quantum circuit using `Snowflurry` and simulate the result of such circuit using our local machine. 

In this tutorial, we will the steps involved in running a quantum circuit on a both a virtual and also a real Quantum Processing Unit (QPU). 


## QPU Object
Interactions with different QPUs are facilitated using `struct`s (objects) that represent QPU hardware.  These structures are used to implement a harmonized interface, and are derived from an `abstract type` called `AbstractQPU`. This interface gives you a unified way to write code that is agnostic of the quantum service you are using. The interface dictates how to get metadata about the QPU, how to run a quantum circuit on the QPU, and more. 

!!! warning 
    You should not use `AbstractQPU`, rather use a QPU object which is derived from `AbstractQPU`. For further details on the implemented derived QPUs, see the [Library page](../library.md#Quantum-Processing-Unit). 

Now that you know what QPU objects are, let's get started by importing `Snowflurry`:
```jldoctest get_qpu_metadata_tutorial; output = false
using Snowflurry

# output

```
### Virtual QPU
Next, we are going to create a virtual QPU which will run on our local machine:

```jldoctest get_qpu_metadata_tutorial; output = false
qpu_v=VirtualQPU()
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

```jldoctest get_qpu_metadata_tutorial; output = false
c=QuantumCircuit(qubit_count=2)
push!(c,hadamard(1),control_x(1,2))
# output
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H────*──
            |  
q[2]:───────X──
```               
We can then run this circuit on the virtual qpu for let's say 101 shots. 

```
shots_count=100
result=run_job(qpu_v,c,shots_count)
```
The `result` object is a `Dict{String, Int64}` that summarizes how many times each state was measured in the shots run on the QPU:

```
print(result)

Dict("00" => 53, "11" => 47)
```

!!! note
	The reason the number of measured values for states `00` and `11` are not necessarily equal is due to the fact that `VirtualQPU` tries to mimick the statistical nature of a real hardware. By increasing the `shots_count` the experiment will can confirm that the probability of `00` and `11` are equal. 



The virtual QPU currently mimicks an ideal hardware with no error. In future versions, we expect to add noise models and also models for other sources of error such as crosstalk, thermal noise, etc. 

In the next tutorial, we will show how to submit a job to a real quantum processing hardware. 