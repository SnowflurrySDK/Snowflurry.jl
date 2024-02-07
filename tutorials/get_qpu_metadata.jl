using Snowflurry

user = ENV["THUNDERHEAD_USER"]
token = ENV["THUNDERHEAD_API_TOKEN"]
host = ENV["THUNDERHEAD_HOST"]
project_id = ENV["THUNDERHEAD_PROJECT_ID"]
realm = ENV["THUNDERHEAD_REALM"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token, project_id = project_id, realm = realm)

println("AnyonYukonQPU metadata:")
for (key, value) in get_metadata(qpu)
    println("    $(key): $(value)")
end
