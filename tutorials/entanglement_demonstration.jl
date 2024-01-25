using Snowflurry

circuit = QuantumCircuit(qubit_count = 2, name = "bell_state")

push!(circuit, hadamard(1))
push!(circuit, control_x(1, 2))
push!(circuit, readout(1, 1))
push!(circuit, readout(2, 2))

user = ENV["THUNDERHEAD_USER"]
token = ENV["THUNDERHEAD_TOKEN"]
host = ENV["THUNDERHEAD_HOST"]
project_id = ENV["THUNDEHEAD_PROJECT_ID"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token, project_id = project_id)

transpiler = get_transpiler(qpu)
transpiled_circuit = transpile(transpiler, circuit)

shot_count = 200
result = run_job(qpu, transpiled_circuit, shot_count)

println(result)
