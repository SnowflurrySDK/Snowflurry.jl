# Running a Circuit on a Virtual QPU

In the [previous tutorial](basics.md), we introduced some basic concepts of quantum
computing, namely the quantum circuit and the quantum gate.

We also learned how to build and simulate a quantum circuit using `Snowflurry`. This
simulation was performed on our local machine. To harness the power of quantum computing,
we need to execute circuits on a Quantum Processing Unit (QPU).

In this tutorial, we will cover the steps involved in running a quantum circuit on a virtual
QPU.

## QPU Objects
Quantum processing units are represented as
[composite types](https://docs.julialang.org/en/v1/manual/types/#Composite-Types) (i.e.
structs or objects) in `Snowflurry`. Every QPU type is derived from an `abstract type`
called `AbstractQPU`. This allows us to write code that is agnostic of the selected quantum
service. It also gives us a uniform way to retrieve metadata about the QPU, run quantum
circuits on the QPU, and much more.

!!! warning
	You should not use `AbstractQPU` directly. Instead, use a QPU type that is derived from
      `AbstractQPU`. See the [Library page](../library/qpu.md#Quantum-Processing-Unit) for a
      detailed description of implemented QPU types.

### Virtual QPUs
Let's now learn how to use a QPU object. The first step is to import `Snowflurry`:
```jldoctest get_qpu_metadata_tutorial; output = false
using Snowflurry

# output

```

We are then going to create a virtual QPU which will run on our local machine:
```jldoctest get_qpu_metadata_tutorial; output = true
qpu_v = VirtualQPU()
# output
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflurry.jl

```

We can print our QPU's metadata by calling
```jldoctest get_qpu_metadata_tutorial; output = true
print(qpu_v)
# output
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflurry.jl

```
or we can retrieve the QPU metadata in a `Dict{String,String}` format using the following
command:
```jldoctest get_qpu_metadata_tutorial; output = true
get_metadata(qpu_v)
# output
Dict{String, Union{Int64, Vector{Int64}, Vector{Tuple{Int64, Int64}}, String}} with 2 entries:
  "developers" => "Anyon Systems Inc."
  "package"    => "Snowflurry.jl"


```

Now, let's create a circuit that generates a Bell state, as explained in the
[previous tutorial](basics.md):
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

Although we've created a circuit that produces a Bell pair, we need to *measure*
our qubits in order to collect results. In Snowflurry, we use
[`Readout`](@ref) instructions to indicate that a measurement must be taken.
These instructions can be built using the [`readout()`](@ref) helper function.

!!! note
	Measurements are always performed in the ``Z`` basis
      (also known as the computational basis).

Let's add [`Readout`](@ref) instructions to each qubit:
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
Here, we see that a `readout` instruction can be added to a circuit like any
other gate. Each readout instruction needs two parameters. The first is the index of the
qubit to measure. The second is the index of the classical bit in which the
result will be stored. For example, calling `readout(2, 4)` generates an
`instruction` that tells the QPU to measure qubit 2 and store the result in classical bit 4.
In the previous circuit, the first readout instruction indicates that qubit 1 is measured
and that the result is written to bit 1. The second readout instruction tells the QPU to
repeat this process for qubit 2 and bit 2.

In Snowflurry, `readout` instructions can involve the measurement of any qubit and the
storing of results in any bit. However, there are some restrictions:
- Every `readout` instruction must be the final instruction that is applied to the target
   qubit.
  - We plan to lift this restriction in future versions of Snowflurry.
- Distinct `readout` instructions must write to distinct result bits.

Now that we've added `readout` instructions to our circuit, let's run it on the virtual QPU
for 100 shots:
```julia
shots_count = 100
result, qpu_time = run_job(qpu_v, c, shots_count)
```

The `result` object is a `Dict{String, Int64}` that indicates how many times each state was
measured on the QPU:

```julia
print(result)

Dict("00" => 53, "11" => 47)
```
Here, we see that the classical bits were set to "00" in 53 of the 100 shots while they
were set to "11" in the other 47 shots. **Only non-zero entries are stored in the `result`
object.**

!!! note "Qubit and bit ordering convention"
	In Snowflurry, the leftmost qubit in a state is associated with the first qubit in a
      circuit. For example, if a circuit is in state $|01\rangle$, it means that qubit 1 is
      in state $|0\rangle$ and qubit 2 is in state $|1\rangle$. The same convention is
      used for classical bits.

!!! note "Statistical uncertainty"
	The reason why the number of "00" and "11" bit strings is not equal is due to the fact
      that the `VirtualQPU` tries to mimic the statistical nature of real QPUs. The
      statistical uncertainty can be reduced by increasing the `shots_count` in the
      simulation. A simulation with more shots should provide stronger indications that the
      probability of obtaining "00" and "11" is equal.


The virtual QPU currently mimics an ideal hardware with no errors. The probability of
measuring states $\left|01\right\rangle$ or $\left|10\right\rangle$ in the
previous example was, therefore, zero. Noise models should be added in future versions of
`Snowflurry` for noise sources such as crosstalk, thermal noise, and more.

In the [next tutorial](anyon_qpu.md), we will show how to submit a job to real quantum
processing hardware.
