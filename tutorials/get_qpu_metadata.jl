using Snowflurry

user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]
project_id = ENV["ANYON_PROJECT_ID"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token, project_id = project_id)

println("AnyonYukonQPU metadata:")
for (key, value) in get_metadata(qpu)
    println("    $(key): $(value)")
end
