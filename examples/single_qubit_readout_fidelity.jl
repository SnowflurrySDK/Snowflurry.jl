using Snowflake

circuit = QuantumCircuit(qubit_count = 1)

user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

client = Client(host=host, user=user, access_token=token)
qpu = AnyonQPU(client)

num_repititions = 200
result = run_job(qpu, circuit, num_repititions)

println(result)
