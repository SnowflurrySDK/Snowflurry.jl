using Snowflurry

circuit = QuantumCircuit(qubit_count = 1)

push!(circuit, sigma_x(1))
push!(circuit, readout(1, 1))

user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token)

shot_count = 200
result = run_job(qpu, circuit, shot_count)

println(result)
