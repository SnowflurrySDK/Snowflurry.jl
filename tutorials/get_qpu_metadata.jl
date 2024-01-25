using Snowflurry

user = ENV["THUNDERHEAD_USER"]
token = ENV["THUNDERHEAD_TOKEN"]
host = ENV["THUNDERHEAD_HOST"]
project_id = ENV["THUNDEHEAD_PROJECT_ID"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token, project_id = project_id)

println("AnyonYukonQPU metadata:")
for (key, value) in get_metadata(qpu)
    println("    $(key): $(value)")
end
