using Snowflake
using Test

@testset "submit_job_bellstate" begin
    c = Circuit(qubit_count=2, bit_count=0)
    pushGate!(c, [hadamard(1)])
    pushGate!(c, [control_x(1, 2)])
    try
        job_uuid, status_type = submitCircuit(c, owner="test_runner", shots=101)
        @test status_type == 1 # JOB qued        
    catch e
        println(e)

    end
end
