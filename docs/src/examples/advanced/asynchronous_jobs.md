# Asynchronous jobs

```@meta
DocTestSetup = quote
    ENV["ANYON_QUANTUM_USER"] = "test-user"
    ENV["ANYON_QUANTUM_TOKEN"] = "not-a-real-token"
    ENV["ANYON_QUANTUM_HOST"] = "yukon.anyonsys.com"
end
```

This example is going to how to run jobs asynchronously using Julia tasks. Asynchronous jobs allow users to continue other work while waiting for the quantum resources.

## Julia tasks

Communication with a quantum computer happens over a network. Any requests sent to a quantum computer are sent over the network. After the request is sent, we can only continue the job execution when we get a response from the quantum computer.

If we absolutely have to have the job's result, we have no choice but to wait. Often, other work can be done while waiting for the quantum job to complete. We want to be able to suspend the `run_job` so that we can continue with other work until we are ready to use the result. This type of control flow is called asynchronous control flow. We recommend you read [Julia's page on asynchronous programming](https://docs.julialang.org/en/v1/manual/asynchronous-programming/) if you are unfamiliar with it.

A quantum job communicating with a quantum computer will [yield](https://docs.julialang.org/en/v1/base/parallel/#Base.yield) execution every time it waits for a response from the quantum computer. This gives you the opportunity to perform work while the quantum computer is running your job.


## Code

To give you maximum flexibility, Snowflake does not impose any restrictions on how you parallelize your code. We cannot know what will be best for your code. That is up to you!

We will start by importing Snowflake, building our circuit, and defining our QPU.


```jldoctest asynchronous_job; output = false
using Snowflake

circuit = QuantumCircuit(qubit_count=2, gates=[
    hadamard(1),
    control_x(1, 2),
])

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
   qubit_count:   6
   connectivity_type:  linear
```

Next we are going to define and [schedule](https://docs.julialang.org/en/v1/base/parallel/#Base.schedule) our task.

```jldoctest asynchronous_job; output = false, setup = :(qpu = VirtualQPU()), filter = r".*"
num_repetitions = 200
task = Task(() -> run_job(qpu, circuit, num_repetitions))
schedule(task)

# output

```

We must remember to schedule the task; otherwise, Julia will not know that it should start running your task! Next, we need to yield execution of the current thread to the newly scheduled task to ensure that the scheduler starts with the task. Otherwise, the task will be scheduled, but it might not submit a job to the quantum computer any time soon! After yielding once, we can continue to do work before we [fetch](https://docs.julialang.org/en/v1/base/parallel/#Base.fetch-Tuple{task}) the results from that task.


```jldoctest asynchronous_job; output = false
yieldto(task)

# Simulate work by calculating the nth Fibonacci number slowly
function fibonacci(n)
  if n <= 2
    return 1
  end
  return fibonacci(n - 1) + fibonacci(n - 2)
end

fibonacci(30)

# output

832040

```

After we are done with our work, we can fetch the result of our job.

```jldoctest asynchronous_job; output = false, filter = r".*"
result = fetch(task)
println(result)

# output

```

The results show that our circuit was run, and we got the expected result!

```text
Dict("00" => 104, "11" => 96)
```

## Summary

In this example, we've gone over how to use asynchronous programming to do work while waiting for quantum jobs to complete.

The full code is avilable at [examples/asynchronous\_jobs.jl](https://github.com/anyonlabs/Snowflake.jl/blob/main/examples/asynchronous_jobs.jl)
