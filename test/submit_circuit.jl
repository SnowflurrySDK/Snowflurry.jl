using Snowflake
using Test

@testset "submit_job_iswap" begin
    c = Circuit(qubit_count = 2, bit_count = 0)
    pushGate!(c, [sigma_x(1)])
    pushGate!(c, [iswap(1, 2)])

    owner = ENV["SNOWFLAKE_ID"]
    token = ENV["SNOWFLAKE_TOKEN"]
    host = ENV["SNOWFLAKE_HOST"]

    try
        job_uuid, status = submitCircuit(c, owner = owner, token = token, shots = 101, host = host)
        id, st, msg = getCircuitStatus(job_uuid, owner = owner, token = token, host = host)
        println("id:" * job_uuid * "  status code:" * string(st) * " message:" * msg)
    catch e
        println(e)

    end
end
