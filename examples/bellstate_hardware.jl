using Snowflake

#Build a two qubit circuit
c = QuantumCircuit(qubit_count = 2, bit_count = 0)

#testing iswap
push_gate!(c, [x_90(2)]);
push_gate!(c, [iswap(1, 2)]);

#User credentials issued by Anyon Systems from envirnoment variables. Change according to your setting.
owner = ENV["SNOWFLAKE_ID"]
token = ENV["SNOWFLAKE_TOKEN"]
host = ENV["SNOWFLAKE_HOST"]
job_uuid, status = submitCircuit(c, owner = owner, token = token, shots = 1001, host = host)


# Checking circuit status and postprocessing. Here we are using a while loop. This is not the recommanded the way. 
# We highly recommand using asynchronous programming when interacting with a remote quantum computer. 
# For more details on async programming, see: https://docs.julialang.org/en/v1/manual/asynchronous-programming/

while true
    id, st, msg = getCircuitStatus(job_uuid, owner = owner, token = token, host = host)
    println("id:" * job_uuid * "  status code:" * string(st) * " message:" * msg)
    if (st == Snowflake.SUCCEEDED)
        println("Good news: Job SUCCEEDED!")
        ## add postprocessing and continue with your calculations.
        break
    end

    if (st == Snowflake.FAILED)
        println("Job failed: " * msg)
        break
    end

    sleep(5) #sleep for 5 seconds before the next try
end
