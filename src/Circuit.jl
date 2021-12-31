using StatsBase
include("../protobuf/AnyonClients.jl")
using LinearAlgebra: getproperty
using UUIDs
using .AnyonClients
using gRPCClient

export Circuit, pushGate!, popGate!, simulate, simulateShots, submitCircuit, createJobRequest, getCircuitStatus, JobStatus, JobStatusMap

@enum JobStatus UNKNOWN = 0 QUEUED = 1 RUNNING = 2 SUCCEEDED = 3 FAILED = 4 CANCELED = 5

JobStatusMap = Dict[UNKNOWN=>"UNKNOWN", QUEUED=>"QUEUED", RUNNING=>"RUNNING", SUCCEEDED=>"SUCCEEDED", FAILED=>"FAILED", CANCELED=>"CANCELED"]


Base.@kwdef struct Circuit
    qubit_count::Int
    bit_count::Int
    id::UUID = UUIDs.uuid1()
    # Circuit(qubit_count, bit_count) = new(qubit_count, bit_count, UUIDs.uuid1(), [])
    pipeline::Array{Array{Gate}} = []
end

function Base.string(status::JobStatus)
    return JobStatusMap[status]
end

function pushGate!(circuit::Circuit, gate::Gate)
    push!(circuit.pipeline, [gate])
    return circuit
end

function pushGate!(circuit::Circuit, gates::Array{Gate})
    push!(circuit.pipeline, gates)
    return circuit
end

function popGate!(circuit::Circuit)
    pop!(circuit.pipeline)
    return circuit
end

function Base.show(io::IO, circuit::Circuit)
    println(io, "Circuit Object:")
    println(io, "   id: $(circuit.id) ")
    println(io, "   qubit_count: $(circuit.qubit_count) ")
    println(io, "   bit_count: $(circuit.bit_count) ")

    wire_count = 2 * circuit.qubit_count
    circuit_layout = fill("", (wire_count, length(circuit.pipeline) + 1))

    for i_qubit in range(1, length = circuit.qubit_count)
        id_wire = 2 * (i_qubit - 1) + 1
        circuit_layout[id_wire, 1] = "q[$i_qubit]:"
        circuit_layout[id_wire+1, 1] = String(fill(' ', length(circuit_layout[id_wire, 1])))
    end

    i_step = 1
    for step in circuit.pipeline
        i_step += 1 # the first elemet of the layout is the qubit tag
        for i_qubit in range(1, length = circuit.qubit_count)
            id_wire = 2 * (i_qubit - 1) + 1
            # qubit wire
            circuit_layout[id_wire, i_step] = "-----"
            # spacer line
            circuit_layout[id_wire+1, i_step] = "     "
        end

        for gate in step
            for i_qubit in range(1, length = circuit.qubit_count)
                if (i_qubit in gate.target)
                    id_wire = 2 * (i_qubit - 1) + 1
                    id = findfirst(isequal(i_qubit), gate.target)
                    circuit_layout[id_wire, i_step] = "--$(gate.display_symbol[id])--"
                    if length(gate.target) > 1 && gate.target[1] == i_qubit
                        circuit_layout[id_wire+1, i_step] = "  |  "
                    end
                end
            end
        end
    end


    # circuit_layout[id_wire] = circuit_layout[id_wire] * ".\n"
    # circuit_layout[id_wire + 1] = circuit_layout[id_wire + 1] * ".\n"

    for i_wire in range(1, length = wire_count)
        for i_step in range(1, length = length(circuit.pipeline) + 1)
            # print(io, circuit_layout[i_wire, i_step])
            # println(io, "  i_wire=", i_wire, " i_step=", i_step)
            print(io, circuit_layout[i_wire, i_step])

        end
        println(io, "")
    end
end

function simulate(circuit::Circuit)
    hilbert_space_size = 2^circuit.qubit_count
    system = MultiBodySystem(circuit.qubit_count, 2)
    ψ = fock(hilbert_space_size, 1)
    for step in circuit.pipeline
        # U is the matrix corresponding the operations happening this step
        #        U = Operator(Matrix{Complex}(1.0I, hilbert_space_size, hilbert_space_size))  
        for gate in step
            # if single qubit gate, get the embedded operator
            # TODO: make sure embedding works for multi qubit system
            S = (length(gate.target) == 1) ? getEmbedOperator(gate.operator, gate.target[1], system) : gate
            ψ = S * ψ
        end

    end
    return ψ
end

function simulateShots(c::Circuit, shots_count::Int = 100)
    # return simulateShots(c, shots_count)
    ψ = simulate(c)
    amplitudes = real.(ψ .* ψ)
    weights = Float32[]

    for a in amplitudes
        push!(weights, a)
    end

    ##preparing the labels
    labels = String[]
    for i in range(0, length = length(ψ))
        s = bitstring(i)
        n = length(s)
        s_trimed = s[n-c.qubit_count+1:n]
        push!(labels, s_trimed)
    end

    data = StatsBase.sample(labels, StatsBase.Weights(weights), shots_count)
    return data
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




