using Snowflake
using Test

@testset "submit_job_iswap" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    # push_gate!(c, [sigma_x(1)])
    push_gate!(c, [iswap(1, 2)])

    try
        owner = ENV["SNOWFLAKE_ID"]
        token = ENV["SNOWFLAKE_TOKEN"]
        host = ENV["SNOWFLAKE_HOST"]
        job_uuid, status =
            submit_circuit(c, owner = owner, token = token, shots = 101, host = host)
        id, st, msg =
            get_circuit_status(job_uuid, owner = owner, token = token, host = host)
        println("id:" * job_uuid * "  status code:" * string(st) * " message:" * msg)
    catch e
        println(e)

    end
end
