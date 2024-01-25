using Snowflurry

circuit = QuantumCircuit(qubit_count = 1, name = "fidelity")

push!(circuit, readout(1, 1))

user = ENV["THUNDERHEAD_USER"]
token = ENV["THUNDERHEAD_TOKEN"]
host = ENV["THUNDERHEAD_HOST"]
project_id = ENV["THUNDEHEAD_PROJECT_ID"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token, project_id = project_id)

shot_count = 200
result = run_job(qpu, circuit, shot_count)

println(result)
