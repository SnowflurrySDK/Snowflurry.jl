using Snowflake
using JSON
using HTTP

commonpath="benchmarking/data"

function serialize_circuit(circuit::QuantumCircuit,repetitions::Integer;indentation::Integer=4)
  
    circuit_description=Dict(
        "circuit"=>Dict{String,Any}(
                "operations"=>Vector{Dict{String,Any}}()
            ),
        "num_repititions"=>repetitions
    )

    for gate in get_circuit_gates(circuit)
        push!(
            circuit_description["circuit"]["operations"],
            Dict{String,Any}(
                "type"=> get_instruction_symbol(gate),
                #server-side qubit numbering starts at 0
                "qubits"=> [n-1 for n in get_connected_qubits(gate)],
                "parameters"=> get_gate_parameters(gate)  
            )
        )
    end

    if indentation>0
        circuit_json=JSON.json(circuit_description,indentation)
    else
        circuit_json=JSON.json(circuit_description)
    end

    write(
        joinpath(commonpath,"test_circuit.json"), 
        circuit_json
    )

    return circuit_json
end


struct Client 
    host::String
    user::String
    access_token::String
end

get_host(client::Client)= client.host

# submits circuit to host and returns circuitID
function submit_circuit(client::Client,circuit_json::String;verbose=false) 

    path_url=joinpath(get_host(client),"circuits")
    
    response=HTTP.post(
        path_url, 
        headers=Dict(
            "Authorization"=>"Bearer $(client.access_token)",
            "Content-Type"=>"application/json"
            ),
        body=circuit_json,
    )
    
    formatted_response=Dict(response)

    body=JSON.parse(formatted_response["body"])
    
    if verbose
        printout_response(:submit_circuit,formatted_response,typeof(response))
    end

    return body["circuitID"]
end

function printout_response(fname::Symbol,formatted_response::Dict{String,Any},type_response::Type)
    println("\n#############################################")
    println("\n\t$fname() returns: \n")

    println("Response type: $type_response")

    for (key,val) in formatted_response
        println("")
        println("$key :\t$val")
    end

    println("")
end


function get_status(client::Client,circuitID::String;verbose=false)

    path_url=joinpath(get_host(client),"circuits/$circuitID")
    
    response=HTTP.get(
        path_url, 
        headers=Dict(
            "Authorization"=>"Bearer $(client.access_token)",
            "Content-Type"=>"application/json"
            )
        )

    formatted_response=Dict(response)

    body=JSON.parse(formatted_response["body"])
    
    if verbose
        printout_response(:get_status,formatted_response,typeof(response))
    end

    return body["status"]
end

function get_result(client::Client,circuitID::String;verbose=false)

    path_url=joinpath(get_host(client),"circuits/$circuitID/result")
    
    response=HTTP.get(
        path_url, 
        headers=Dict(
            "Authorization"=>"Bearer $(client.access_token)",
            "Content-Type"=>"application/json"
            )
        )

    formatted_response=Dict(response)

    body=JSON.parse(formatted_response["body"])
    
    if verbose
        printout_response(:get_result,formatted_response,typeof(response))
    end

    return body["histogram"]
end


abstract type Service end

struct QPUService <: Service
    client::Client
    qpu::QPU

    function QPUService(client::Client,qpu::QPU)
        if client.host!=qpu.host
            throw(
                ArgumentError(
                    "Client host $(get_host(client)) and qpu host $(get_host(qpu)) do not match."
                    )
                )
        end

        new(client,qpu)
    end
end

get_client(qpu_service::QPUService)=qpu_service.client
get_qpu(qpu_service::QPUService)=qpu_service.qpu

function Base.Dict(response::HTTP.Messages.Response)
    formatted_response=Dict(
        "version"   =>response.version, 
        "status"    =>response.status, 
        "headers"   =>response.headers, 
        "request"   =>response.request
    )

    # convert response body from binary to ASCII
    read_buffer=IOBuffer(reinterpret(UInt8, response.body))
    formatted_response["body"]=String(readuntil(read_buffer, 0x00))

    return formatted_response
end

function run(qpu_service::QPUService, circuit::QuantumCircuit,num_repetitions::Integer;verbose=false)
    circuit_json=serialize_circuit(circuit,num_repetitions)
    
    client=get_client(qpu_service)

    circuitID=submit_circuit(client,circuit_json;verbose=verbose)

    if verbose
        println("Circuit submitted: circuitID returned: $circuitID")
    end

    status=get_status(client,circuitID;)

    while true
        
        if verbose
            println("status: $(status["type"])")
        end
        
        if !(status["type"] in ["queued","running"])
            break
        end

        sleep(0.2) #wait 200ms to minimize printout counts
        status=get_status(client,circuitID;)
    end
    
    if status["type"] == "failed"       
        return Dict("error_msg"=>status["message"])
    else
        histogram=get_result(client,circuitID;verbose=verbose)
    end
end

