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

num_repetitions = 200
task = Task(() -> run_job(qpu, circuit, num_repetitions))
schedule(task)

yieldto(task)

# Simulate work by calculating the nth Fibonacci number slowly
function fibonacci(n)
  if n <= 2
    return 1
  end
  return fibonacci(n - 1) + fibonacci(n - 2)
end

fibonacci(30)

result = fetch(task)
println(result)
