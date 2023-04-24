using Snowflake

user = ENV["ANYON_QUANTUM_USER"]
token = ENV["ANYON_QUANTUM_TOKEN"]
host = ENV["ANYON_QUANTUM_HOST"]

client = Client(host=host, user=user, access_token=token)
qpu = AnyonQPU(client)

println("AnyonQPU metadata:")
for (key,value) in get_metadata(qpu)
    println("    $(key): $(value)")
end
