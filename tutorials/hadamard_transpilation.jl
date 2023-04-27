using Snowflake

circuit = QuantumCircuit(qubit_count = 1)

push!(circuit, hadamard(1))

user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

qpu = AnyonQPU(host=host, user=user, access_token=token)

transpiler = get_transpiler(qpu)
transpiled_circuit = transpile(transpiler, circuit)

num_repetitions = 200
result = run_job(qpu, circuit, num_repetitions)

println(result)
