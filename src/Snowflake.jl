module Snowflake
include("../protobuf/AnyonClients.jl")
using LinearAlgebra:getproperty
using UUIDs
using .AnyonClients
# using .AnyonClients: CircuitAPIClient, SubmitJobRequest, SubmitJobReply, Instruction, Instruction_Parameter, Circuit

include("QObj.jl")
include("Gate.jl")
include("Circuit.jl")
include("Visualize.jl")


function submitCircuit(circuit::Circuit; host::String="localhost:50051")
    client = AnyonClients.CircuitAPIClient(host)
    request = createJobRequest(circuit)
    try
        reply = submitJob(client, request) 
        job_uuid = getproperty(reply[1], :job_uuid)
        status = getproperty(reply[1], :status)
        message = getproperty(status, :message)
        status_type = getproperty(status, :_type)
        return job_uuid, status_type
    catch e
        println(e)
        return e
    end
end

function createJobRequest(circuit::Circuit)
    

    pipeline = []

    for step in circuit.pipeline
        should_add_identity = fill(true, circuit.qubit_count)
        for gate in step
            
            # flag if the qubit is being operated on in this step
            for i_qubit in gate.target  
                should_add_identity[i_qubit] = false 
            end

            ##TODO: add classical bit targets and parameters
            push!(pipeline, AnyonClients.Instruction(symbol=gate.instruction_symbol, qubits=gate.target))
        end  

        for i_qubit in range(1, length=(circuit.qubit_count))
            if (should_add_identity[i_qubit])
                push!(pipeline, AnyonClients.Instruction(symbol="i", qubits=[i_qubit]))
            end
        end

    end

    circuit_api = AnyonClients.anyon.thunderhead.qpu.Circuit(instructions=pipeline)
    request = AnyonClients.SubmitJobRequest(owner="alireza@anyonsys.com", shots_count=1000, circuit=circuit_api)

    return request
end


export submitCircuit
end # end module
