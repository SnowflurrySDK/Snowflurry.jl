# Get QPU metadata example

```@meta
using Snowflake

DocTestSetup = quote
    ENV["ANYON_QUANTUM_USER"] = "test-user"
    ENV["ANYON_QUANTUM_TOKEN"] = "not-a-real-token"
    ENV["ANYON_QUANTUM_HOST"] = "yukon.anyonsys.com"
end
```

This example is going to teach you what a QPU object is. Also, we are going to show you how to construct an AnyonQPU object which can be used to interact with Anyon's quantum hardware. Finally, this example will show you how to get metadata from a QPU object.

## Code

A QPU object is an object which implements the `AbstractQPU` interface. This interface gives you a unified way to write code that is agnostic of the quantum service you are using. The interface dictates how to get metadata about the QPU, how to run a quantum circuit on the QPU, and more. 

We are going to start by importing Snowflake.

```jldoctest get_qpu_metadata_example; output = false
using Snowflake

# output

```

Next, we are going to create the QPU object. We want to interact with Anyon's Quantum Computers, so we are going to construct an `AnyonQPU`. Three things are needed to construct an `AnyonQPU`. We need the username and access token to authenticate with the quantum computer and the hostname where the quantum computer can be found. The easiest way to get these parameters is by reading them from environment variables.

```jldoctest get_qpu_metadata_example; output = false
user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

# output

"yukon.anyonsys.com"
```

When we have the environment variables, we can construct our `AnyonQPU` object.

```jldoctest get_qpu_metadata_example; output = false
qpu = AnyonQPU(host=host, user=user, access_token=token)

# output

Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6
   connectivity_type:  linear
```

Now that we have an `AnyonQPU` object, we want to get the machine's metadata to see what we're dealing with. We do this using the `get_metadata` function.

```jldoctest get_qpu_metadata_example; output = false
println("AnyonQPU metadata:")
for (key,value) in get_metadata(qpu)
    println("    $(key): $(value)")
end

# output
AnyonQPU metadata:
    qubit_count: 6
    generation: Yukon
    manufacturer: Anyon Systems Inc.
    serial_number: ANYK202201
    connectivity_type: linear
```

After printing out all the metadata you should see something similar to what is shown below.

```text
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6
   connectivity_type:  linear
```

## Summary

In this example, we've gone over what a QPU object is. We've also shown how to construct an `AnyonQPU` object and how to retrieve its metadata.

The full code for this example is available at [examples/get\_qpu\_metadata.jl](https://github.com/anyonlabs/Snowflake.jl/blob/main/examples/get_qpu_metadata.jl)
