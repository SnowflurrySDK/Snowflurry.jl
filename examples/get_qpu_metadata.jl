using Snowflake

user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

qpu = AnyonQPU(host=host, user=user, access_token=token)

println("AnyonQPU metadata:")
for (key,value) in get_metadata(qpu)
    println("    $(key): $(value)")
end
