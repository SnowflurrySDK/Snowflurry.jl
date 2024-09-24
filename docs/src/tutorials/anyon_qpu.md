# Running a Circuit on Real Hardware

In the [previous tutorial](virtual_qpu.md), we learned how to execute a quantum circuit on a
virtual QPU. We also learned that every QPU object should adhere to the `AbstractQPU`
interface.

In this tutorial, we will learn how to submit a job to a real quantum processor. At the
moment, we have only implemented QPU types for Anyon's quantum processors. However, we
welcome contributions from other members of the community. We also invite other hardware
vendors to use `Snowflurry` for their quantum processors.

## Anyon QPU

!!! note
	This tutorial is written for the selected partners and users who have been granted access
      to Anyon's hardware.

The current release of `Snowflurry` supports Anyon's Yukon quantum processor (see
[`AnyonYukonQPU`](@ref)). The processor consists of an array of 6 tunable superconducting
transmon qubits interleaved with 5 tunable couplers. The following generation of QPU, called
Yamaska (see [`AnyonYamaskaQPU`](@ref)), is also supported in `Snowflurry`. This QPU
contains 24 qubits and 35 couplers that are positioned in a two-dimensional lattice. 

We can start by defining a `qpu` variable that points to the host computer that will queue
jobs and submit them to the quantum processor:

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
We should also provide user credentials and a `project_id` if needed. These are required in
order to submit jobs through Thunderhead.

!!! danger "Keep your credentials safe!"
	If you plan to make your code public or work in a shared environment, it is best to use
      environment variables to set the user credentials rather than hardcoding them!

We can now print the `qpu` object to obtain further information about the hardware:

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

Alternatively, we can use the `get_metadata` function to obtain a `Dict` object
that contains information about the `qpu`:

```jldoctest anyon_qpu_tutorial
get_metadata(qpu)

# output

Dict{String, Union{Int64, Vector{Int64}, Vector{Tuple{Int64, Int64}}, String}} with 10 entries:
  "qubit_count"          => 6
  "generation"           => "Yukon"
  "status"               => "online"
  "manufacturer"         => "Anyon Systems Inc."
  "realm"                => "test-realm"
  "excluded_connections" => Tuple{Int64, Int64}[]
  "serial_number"        => "ANYK202201"
  "project_id"           => "test-project"
  "connectivity_type"    => "linear"
  "excluded_positions"   => Int64[]
```

We now build a small circuit that creates a Bell state, as was presented in the previous
[tutorials](basics.md):

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

The previous circuit cannot be directly executed on the quantum processor. This is because
the quantum processor only implements a set of *native gates*. This means that any arbitrary
gate should first be *transpiled* into a set of *native* gates that can run on the QPU.

If we examine the `src/anyon/anyon.jl` file, we notice that the Anyon processors implement
the following set of native gates:
```
set_of_native_gates = [
    Identity,
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

Snowflurry is designed to allow users to design and use their own transpilers for different 
QPUs. Alternatively, a user may opt not to use the default transpilers that are implemented
for each QPU type.

Let's see how we can transpile the above circuit, `c`, to a circuit that can run on one of
Anyon's QPUs. We first define a `transpiler` object that refers to the default transpiler
for the [`AnyonYukonQPU`](@ref):

```jldoctest anyon_qpu_tutorial; output = false
transpiler = get_transpiler(qpu)

# output
SequentialTranspiler(Transpiler[CircuitContainsAReadoutTranspiler(), ReadoutsDoNotConflictTranspiler(), UnsupportedGatesTranspiler(), DecomposeSingleTargetSingleControlGatesTranspiler(), CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), CastRootZZToZ90AndCZGateTranspiler(), SwapQubitsForAdjacencyTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), CastSwapToCZGateTranspiler()  …  SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), ReadoutsAreFinalInstructionsTranspiler(), RejectNonNativeInstructionsTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), RejectGatesOnExcludedPositionsTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), RejectGatesOnExcludedConnectionsTranspiler(LineConnectivity{6}
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

!!! note
	It may be beneficial to select specific qubits on the QPU in order to reduce the impact
      of noise on the results. For instance, one could select qubits 2 and 6 for the
      execution of a two-qubit circuit. This requires setting `qubit_count` to 6 for the
      construction of the `QuantumCircuit` since `qubit_count` represents the largest
      qubit index. Setting `qubit_count` to 2 will not enable the application of a quantum
      gate to qubit 6 even though gates are only applied to two qubits.

The final circuit `c_transpiled` is now ready to be submitted to the QPU

```julia
shot_count = 200
result, qpu_time = run_job(qpu, c_transpiled, shot_count)
println(result)
```
where printing the results yields
```julia
Dict("11" => 97, "00" => 83, "01" => 11, "10" => 9)
```

The results show that states $\left|00\right\rangle$ and $\left|11\right\rangle$ were
measured most often. States $\left|01\right\rangle$ and $\left|10\right\rangle$ were also
measured a few times due to errors in the computation.

!!! note
	The user can skip the explicit transpilation step by using the `transpile_and_run_job`
      function. This function uses the default transpiler of the QPU and submits the job to
      the machine.
