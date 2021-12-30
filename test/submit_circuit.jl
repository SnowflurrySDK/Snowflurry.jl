using Snowflake
using Test

@testset "submit_job_bellstate" begin
    c = Circuit(qubit_count = 2, bit_count = 0)
    pushGate!(c, [hadamard(1)])
    pushGate!(c, [control_x(1, 2)])

    owner = ENV["SNOWFLAKE_ID"]
    token = ENV["SNOWFLAKE_TOKEN"]
    host = ENV["SNOWFLAKE_HOST"]

    try
        job_uuid, status = submitCircuit(c, owner = owner, token = token, shots = 101, host = host)
        @test status == Int32(Snowflake.QUEUED)
    catch e
        println(e)

    end
end
