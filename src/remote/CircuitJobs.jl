include("../../protobuf/AnyonClients.jl")
using LinearAlgebra: getproperty
using UUIDs
using .AnyonClients
using gRPCClient

export JobStatus, JobStatusMap, submitCircuit, getCircuitStatus

@enum JobStatus UNKNOWN = 0 QUEUED = 1 RUNNING = 2 SUCCEEDED = 3 FAILED = 4 CANCELED = 5
JobStatusMap = Dict(UNKNOWN=>"UNKNOWN", QUEUED=>"QUEUED", RUNNING=>"RUNNING", SUCCEEDED=>"SUCCEEDED", FAILED=>"FAILED", CANCELED=>"CANCELED")

function Base.string(status::JobStatus)
    return JobStatusMap[status]
end

function submitCircuit(circuit::Circuit; owner::String, token::String, shots::Int, host::String = "localhost:60051")
    client = AnyonClients.CircuitAPIClient(host)
    # client = AnyonClients.CircuitAPIBlockingClient(host)
    request = createJobRequest(circuit, owner = owner, token = token, shots = shots)
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

function createJobRequest(circuit::Circuit; owner::String, token::String, shots::Int)
    pipeline = []
    for step in circuit.pipeline
        should_add_identity = fill(true, circuit.qubit_count)
        for gate in step

            # flag if the qubit is being operated on in this step
            for i_qubit in gate.target
                should_add_identity[i_qubit] = false
            end

            ##TODO: add classical bit targets and parameters
            push!(pipeline, AnyonClients.Instruction(symbol = gate.instruction_symbol, qubits = gate.target))
        end

        for i_qubit in range(1, length = (circuit.qubit_count))
            if (should_add_identity[i_qubit])
                push!(pipeline, AnyonClients.Instruction(symbol = "i", qubits = [i_qubit]))
            end
        end

    end

    circuit_api = AnyonClients.anyon.thunderhead.qpu.Circuit(instructions = pipeline)
    request = AnyonClients.SubmitJobRequest(owner = owner, token = token, shots_count = shots, circuit = circuit_api)

    return request
end

function getCircuitStatus(job_uuid::String; owner::String = "", token::String = "", host = "localhost:60051")
    client = AnyonClients.CircuitAPIClient(host)
    request = AnyonClients.JobStatusRequest(job_uuid = job_uuid, owner = owner, token = token)
    try
        reply = getJobStatus(client, request)
        job_uuid = getproperty(reply[1], :job_uuid)
        status_obj = getproperty(reply[1], :status)
        msg = getproperty(status_obj, :message)
        status = getproperty(status_obj, :_type)


        return job_uuid, status, msg
    catch e
        println(e)
        return e
    end
end
