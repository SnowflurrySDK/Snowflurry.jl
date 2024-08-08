using Snowflurry

circuit = QuantumCircuit(qubit_count = 3, name = "sigma_x")

push!(circuit, readout(3, 3))

user = ENV["THUNDERHEAD_USER"]
token = ENV["THUNDERHEAD_API_TOKEN"]
host = ENV["THUNDERHEAD_HOST"]
project_id = ENV["THUNDERHEAD_PROJECT_ID"]
realm = ENV["THUNDERHEAD_REALM"]

qpu = AnyonYukonQPU(
    host = host,
    user = user,
    access_token = token,
    project_id = project_id,
    realm = realm,
)

shot_count = 200
result, qpu_time = run_job(qpu, circuit, shot_count)

println(result)
