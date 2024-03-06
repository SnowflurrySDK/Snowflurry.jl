# Asynchronous jobs

```@meta
DocTestSetup = quote
    ENV["THUNDERHEAD_USER"] = "test-user"
    ENV["THUNDERHEAD_API_TOKEN"] = "not-a-real-token"
    ENV["THUNDERHEAD_HOST"] = "thunderhead.anyonsys.com"
    ENV["THUNDERHEAD_PROJECT_ID"] = "test-project"
    ENV["THUNDERHEAD_REALM"] = "test-realm"
end
```

In this tutorial we will learn how to run jobs asynchronously using [Julia tasks](https://docs.julialang.org/en/v1/base/parallel/). Asynchronous jobs allow for the code to continue with other computation while waiting for the quantum resources.

## Julia tasks

Practical applications of quantum computing typically involve both classical and quantum computation. A quantum processor is indeed a hardware accelerator in this paradigm. In such scenarios, it might take some time for the quantum computer to run the circuit that was submitted to it.

In many cases, it is desirable to be able to continue with some classical computation while the program waits for the quantum hardware to complete its task. This is an example of asynchronous programming. We recommend you consult [Julia's page on asynchronous programming](https://docs.julialang.org/en/v1/manual/asynchronous-programming/) if you are unfamiliar with this concept.

In `Snowflurry`, communicating with a quantum processor will [yield](https://docs.julialang.org/en/v1/base/parallel/#Base.yield) execution every time it waits for a response from the quantum computer. This gives you the opportunity to perform work while the quantum computer is running your job.


## Code

To provide maximum flexibility, Snowflurry does not impose any restrictions on how you parallelize your code. We cannot know what will be best for your code. That is up to you!

We will start by importing Snowflurry, building our circuit and defining our QPU as demonstrated in the [Running a Circuit on a Real Hardware](../anyon_qpu.md) tutorial.


```jldoctest asynchronous_job; output = false
using Snowflurry

circuit = QuantumCircuit(qubit_count = 2, instructions = [
    hadamard(1),
    control_x(1, 2),
    readout(1, 1),
    readout(2, 2),
])

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

Next, we are going to define and [schedule](https://docs.julialang.org/en/v1/base/parallel/#Base.schedule) our task.

```jldoctest asynchronous_job; output = false, setup = :(qpu = VirtualQPU()), filter = r".*"
shot_count = 200
task = Task(() -> run_job(qpu, circuit, shot_count))
schedule(task)

# output

```

!!! warning
    Note the last line above. It is important to `schedule` the `task`; otherwise, Julia will not know that it should start it!

Next, we need to yield execution of the current thread to the newly scheduled task to ensure that the scheduler starts with the task. Otherwise, the task will be scheduled, but it might not submit a job to the quantum computer any time soon! After yielding once, we can continue to do work before we [fetch](https://docs.julialang.org/en/v1/base/parallel/#Base.fetch-Tuple{task}) the results from that task.


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

The full code is available at [tutorials/asynchronous\_jobs.jl](https://github.com/SnowflurrySDK/Snowflurry.jl/blob/main/tutorials/asynchronous_jobs.jl)
