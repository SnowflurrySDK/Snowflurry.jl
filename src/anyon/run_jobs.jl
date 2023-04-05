using Snowflake
using JSON
using HTTP

commonpath="benchmarking/data"

function serialize_circuit(circuit::QuantumCircuit,repetitions::Integer)
  
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

    circuit_json=JSON.json(circuit_description)

    return circuit_json
end


struct Client 
    host::String
    user::String
    access_token::String
end

get_host(client::Client)= client.host

# submits circuit to host and returns circuitID
function submit_circuit(client::Client,circuit::QuantumCircuit,num_repetitions::Integer) 

    circuit_json=serialize_circuit(circuit,num_repetitions)
  
    path_url=joinpath(get_host(client),"circuits")
    
    response=HTTP.post(
        path_url, 
        headers=Dict(
            "Authorization"=>"Bearer $(client.access_token)",
            "Content-Type"=>"application/json"
            ),
        body=circuit_json,
    )
    
    formatted_response=format_response(response)

    body=JSON.parse(formatted_response["body"])

    return body["circuitID"]
end

function get_status(client::Client,circuitID::String)

    path_url=joinpath(get_host(client),"circuits/$circuitID")
    
    response=HTTP.get(
        path_url, 
        headers=Dict(
            "Authorization"=>"Bearer $(client.access_token)",
            "Content-Type"=>"application/json"
            )
        )

    formatted_response=format_response(response)

    body=JSON.parse(formatted_response["body"])

    return body["status"]
end

function get_result(client::Client,circuitID::String)

    path_url=joinpath(get_host(client),"circuits/$circuitID/result")
    
    response=HTTP.get(
        path_url, 
        headers=Dict(
            "Authorization"=>"Bearer $(client.access_token)",
            "Content-Type"=>"application/json"
            )
        )

    formatted_response=format_response(response)

    body=JSON.parse(formatted_response["body"])

    return body["histogram"]
end


abstract type AbstractQPU end

Base.@kwdef struct AnyonQPU <: AbstractQPU
    client::Client
    manufacturer ::String="Anyon Systems Inc."
    generation   ::String="Yukon"
    serial_number::String="ANYK202201"
    printout_delay::Real=200. # milliseconds between get_status printouts
end

get_client(qpu_service::AnyonQPU)=qpu_service.client
get_printout_delay(qpu_service::AnyonQPU)=qpu_service.printout_delay

function Base.show(io::IO, qpu::AnyonQPU)
    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(qpu.manufacturer)")
    println(io, "   generation:    $(qpu.generation) ")
    println(io, "   serial_number: $(qpu.serial_number) ")
end

function format_response(response::HTTP.Messages.Response)
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

function run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)
    
    client=get_client(qpu)

    circuitID=submit_circuit(client,circuit,num_repetitions)

    println("Circuit submitted: circuitID returned: $circuitID\n")

    status=get_status(client,circuitID;)

    while true
        
        println("status: $(status["type"])")
        
        if !(status["type"] in ["queued","running"])
            break
        end

        sleep(get_printout_delay(qpu)/1000) 
        status=get_status(client,circuitID;)
    end
    
    if status["type"] == "failed"       
        return Dict("error_msg"=>status["message"])
    else
        histogram=get_result(client,circuitID)
    end
end

