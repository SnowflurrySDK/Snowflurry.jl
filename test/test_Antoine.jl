using Snowflurry

user = ENV["THUNDERHEAD_USER"]
token = ENV["THUNDERHEAD_API_TOKEN"]
host = ENV["THUNDERHEAD_HOST"]
project_id = ENV["THUNDERHEAD_PROJECT_ID"]
realm = ENV["THUNDERHEAD_REALM"]

# user = "test-user-with-expired-token"
# token = "nonsense"
# host = ENV["THUNDERHEAD_HOST"]
# project_id = "default"
# realm = ENV["THUNDERHEAD_REALM"]

qpu = AnyonYamaskaQPU(
    host = host,
    user = user,
    access_token = token,
    project_id = project_id,
    realm = realm,
)

shot_counts = 100
nb_qubit = 9
c = QuantumCircuit(qubit_count=nb_qubit)
push!(c, hadamard(1), hadamard(5), hadamard(9))
push!(c, control_x(5,1))
push!(c, hadamard(1))
push!(c, hadamard(1), hadamard(5), sigma_z(9))
push!(c, toffoli(1,5,9))
push!(c, hadamard(1), hadamard(5), sigma_z(9))
push!(c, readout(1,1))
push!(c, readout(5,2))
push!(c, readout(9,3))
for i in 1:2
    result, time = transpile_and_run_job(qpu,c,shot_counts)
    println(result)
end