# Running a Circuit on a Real Hardware

```@meta
using Snowflurry

DocTestSetup = quote
    ENV["ANYON_QUANTUM_USER"] = "test-user"
    ENV["ANYON_QUANTUM_TOKEN"] = "not-a-real-token"
    ENV["ANYON_QUANTUM_HOST"] = "yukon.anyonsys.com"
end
```

In the previous tutorial, we learnt how to run a quantum circuit on a virtual QPU. We also learnt that every QPU driver should adhere to the `AbstractQPU`.

In this tutorial, we will learn how to submit a job to a real hardware. At the moment, we have only implemented the driver for Anyon's quantum processors but we welcome contributions from other members of the community, as well as other hardware vendors to use `Snowflurry` with a variety of machines. 

## Anyon QPU

The current release of `Snowflurry` supports Anyon's Yukon quantum processor which is made from an array of 6 tunable superconducting transmon qubits interleaved with 5 tunable couplers. 



We can start by defining a `qpu` variable to point to the host computer that will queue jobs on the quantum processor and provide it with user credentials:

```jldoctest anyon_qpu_tutorial; output = false
using Snowflurry

qpu=AnyonYukonQPU(host="yukon.anyonsys.com",user="USER_NAME", access_token="API_KEY")

# output
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6
   connectivity_type:  linear

```

!!! warning
    If you plan to make your code public or work in a shared envrinoment, it is best to use environment variables to set the user credentials rather than hardcoding them!


We can now print the `qpu` object to print further information about the hardware:

```jldoctest anyon_qpu_tutorial
println(qpu)

# output

Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6
   connectivity_type:  linear
```

Alternatively, one can use the `get_metadata` function to obtain a `Dict` object corresponding to the QPU information:

```jldoctest anyon_qpu_tutorial
get_metadata(qpu)

# output

Dict{String, Union{Int64, String}} with 5 entries:
  "qubit_count"       => 6
  "generation"        => "Yukon"
  "manufacturer"      => "Anyon Systems Inc."
  "serial_number"     => "ANYK202201"
  "connectivity_type" => "linear"
```

We now continue to build a small circuit to create a Bell state as was presented in the previous tutorials:

```jldoctest anyon_qpu_tutorial; output = true
c=QuantumCircuit(qubit_count=2)
push!(c,hadamard(1),control_x(1,2))
# output
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H────*──
            |  
q[2]:───────X──
``` 

## Circuit Transpilation

The circuit above cannot be directly executed on the quantum processor. This is because the quantum processor only implements a set of *native gates*. This means that any arbitrary gate should first be *transpiled* into a set of *native* gates that can run on the QPU. 

If you examine the `src/anyon/qpu_interface.jl` file, you notice that Anyon Yukon Processor implements the following set of native gates:
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

Snowflurry is designed to allow users to design and use their own transpilers for different QPUs. Alternatively, a use may opt out to use the default transpilers that are implemented for each QPU driver. 

Let's see how can we transpile the above circuit, `c`, to a circuit that can run on Anyon's QPU. We first define a `transpiler` object that refers to the default transpiler for AnyonYukonQPU which shipped with `Snowflurry`:

```jldoctest anyon_qpu_tutorial; output = false
transpiler=get_transpiler(qpu)

# output
SequentialTranspiler(Transpiler[CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), SwapQubitsForAdjacencyTranspiler{LineConnectivity}(LineConnectivity{6}
1──2──3──4──5──6
), CastSwapToCZGateTranspiler(), CompressSingleQubitGatesTranspiler(), SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), UnsupportedGatesTranspiler()])
```

Next, let's transpile the original circuit:

```anyon_qpu_tutorial; output = true
c_transpiled=transpile(transpiler,c)

# output

Quantum Circuit Object:
   qubit_count: 2 
q[1]:──Z_90────────────X_90────Z_90────────────────────*──────────────────────────
                                                       |                          
q[2]:──────────Z_90────────────────────X_90────Z_90────Z────Z_90────X_90────Z_90──
```

The final circuit `c_final` is now ready to be submitted to the QPU:

```julia
shot_count = 200
result = run_job(qpu, c_transpiled, shot_count)
println(result)
```
which should print something like:
```text
Dict("11" => 97, "00" => 83, "01" => 11, "10" => 9)
```

The results show that the samples are mostly sampled between state $\left|00\right\rangle$ and $\left|11\right\rangle$. We do see some finite population in $\left|01\right\rangle$ and $\left|10\right\rangle$ that are due to the error in the computation.


!!! note 
    The user can skip the explicit transpiling step by using the `transpile_and_run` function. This function will use the default transpiler of the QPU and then submit the job to the machine. 
