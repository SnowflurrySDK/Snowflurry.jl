# Running a Circuit on Real Hardware

In the [previous tutorial](virtual_qpu.md), we learnt how to run a quantum circuit on a virtual QPU. We also learnt that every QPU driver should adhere to the `AbstractQPU` API.

In this tutorial, we will learn how to submit a job to real hardware. At the moment, we have only implemented the driver for Anyon's quantum processors but we welcome contributions from other members of the community, as well as other hardware vendors to use `Snowflurry` with a variety of machines.

## Anyon QPU

!!! note
	This tutorial is written for the selected partners and users who have been granted access to Anyon's hardware.

The current release of `Snowflurry` supports Anyon's Yukon quantum processor (see [`AnyonYukonQPU`](@ref)) which is made from an array of 6 tunable superconducting transmon qubits interleaved with 5 tunable couplers.
The following generation of QPU, called [`AnyonYamaskaQPU`](@ref) is also implemented, in which 12 qubits are arranged in a lattice, along with 14 couplers. 

We can start by defining a `qpu` variable to point to the host computer that will queue jobs on the quantum processor and provide it with user credentials. A valid project_id is also required to submit jobs on Anyon infrastructure:

```jldoctest anyon_qpu_tutorial; output = false
using Snowflurry

user = ENV["THUNDERHEAD_USER"]
token = ENV["THUNDERHEAD_API_TOKEN"]
host = ENV["THUNDERHEAD_HOST"]
project = ENV["THUNDERHEAD_PROJECT_ID"]
realm = ENV["THUNDERHEAD_REALM"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token, project_id = project, realm = realm)

# output
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   project_id:    test-project
   qubit_count:   6
   connectivity_type:  linear
   realm:         test-realm

```

!!! danger "Keep your credentials safe!"
	If you plan to make your code public or work in a shared environment, it is best to use environment variables to set the user credentials rather than hardcoding them!


We can now print the `qpu` object to print further information about the hardware:

```jldoctest anyon_qpu_tutorial
println(qpu)

# output

Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   project_id:    test-project
   qubit_count:   6
   connectivity_type:  linear
   realm:         test-realm
```

Alternatively, one can use the `get_metadata` function to obtain a `Dict` object corresponding to the QPU information:

```jldoctest anyon_qpu_tutorial
get_metadata(qpu)

# output

Dict{String, Union{Int64, String, Vector{Int64}}} with 8 entries:
  "qubit_count"        => 6
  "generation"         => "Yukon"
  "manufacturer"       => "Anyon Systems Inc."
  "realm"              => "test-realm"
  "serial_number"      => "ANYK202201"
  "project_id"         => "test-project"
  "connectivity_type"  => "linear"
  "excluded_positions" => Int64[]
```

We now continue to build a small circuit to create a Bell state as was presented in the previous tutorials:

```jldoctest anyon_qpu_tutorial; output = true
c = QuantumCircuit(qubit_count = 2)
push!(c, hadamard(1), control_x(1, 2), readout(1, 1), readout(2, 2))
# output
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2
q[1]:──H────*────✲───────
            |            
q[2]:───────X─────────✲──
```

## Circuit Transpilation

The circuit above cannot be directly executed on the quantum processor. This is because the quantum processor only implements a set of *native gates*. This means that any arbitrary gate should first be *transpiled* into a set of *native* gates that can run on the QPU.

If you examine the `src/anyon/anyon.jl` file, you notice that Anyon Yukon Processor implements the following set of native gates:
```
 set_of_native_gates=[
        PhaseShift,
        Pi8,
        Pi8Dagger,
        SigmaX,
        SigmaY,
        SigmaZ,
        X90,
        XM90,
        Y90,
        YM90,
        Z90,
        ZM90,
        ControlZ,
    ]
```

Snowflurry is designed to allow users to design and use their own transpilers for different QPUs. Alternatively, a user may opt not to use the default transpilers that are implemented for each QPU driver.

Let's see how we can transpile the above circuit, `c`, to a circuit that can run on Anyon's QPU. We first define a `transpiler` object that refers to the default transpiler for AnyonYukonQPU which shipped with `Snowflurry`:

```jldoctest anyon_qpu_tutorial; output = false
transpiler = get_transpiler(qpu)

# output
SequentialTranspiler(Transpiler[CircuitContainsAReadoutTranspiler(), ReadoutsDoNotConflictTranspiler(), UnsupportedGatesTranspiler(), DecomposeSingleTargetSingleControlGatesTranspiler(), CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), CastRootZZToZ90AndCZGateTranspiler(), SwapQubitsForAdjacencyTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), CastSwapToCZGateTranspiler(), CompressSingleQubitGatesTranspiler(), SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), ReadoutsAreFinalInstructionsTranspiler(), RejectNonNativeInstructionsTranspiler(LineConnectivity{6}
1──2──3──4──5──6
)])
```

Next, let's transpile the original circuit:

```julia
c_transpiled = transpile(transpiler, c)

# output

Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2
q[1]:──Z_90────────────X_90────Z_90────────────────────*────────────────────────────✲───────
                                                       |                                    
q[2]:──────────Z_90────────────────────X_90────Z_90────Z────Z_90────X_90────Z_90─────────✲──
```

The final circuit `c_transpiled` is now ready to be submitted to the QPU:

```julia
shot_count = 200
result = run_job(qpu, c_transpiled, shot_count)
println(result)
```
which should print something like:
```julia
Dict("11" => 97, "00" => 83, "01" => 11, "10" => 9)
```

The results show that the samples are mostly sampled between state $\left|00\right\rangle$ and $\left|11\right\rangle$. We do see some finite population in $\left|01\right\rangle$ and $\left|10\right\rangle$ that are due to the error in the computation. (The qubit ordering convention used is qubit number 1 on the left, with each following qubit to the right of it.)


!!! note
	The user can skip the explicit transpiling step by using the `transpile_and_run_job` function. This function will use the default transpiler of the QPU and then submit the job to the machine.
