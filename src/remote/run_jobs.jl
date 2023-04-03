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

    for gate in get_gates(circuit)
        push!(
            circuit_description["circuit"]["operations"],
            Dict{String,Any}(
                "type"=> get_instruction_symbol(gate),
                "qubits"=> get_connected_qubits(gate),
                "parameters"=> get_parameters(gate)  
            )
        )
    end

    circuit_json=JSON.json(circuit_description)
    # circuit_json=JSON3.write(circuit_description)

    # # circuit_dict=JSON.parsefile(joinpath(commonpath,"test_send_cirq.json"))

    # # println("circuit_dict: $circuit_dict")

    # # circuit_json="{'circuit': {'operations': [{'type': 'x', 'qubits': [0], 'parameters': {}}, {'type': 'i', 'qubits': [1], 'parameters': {}}, {'type': 'iswap', 'qubits': [0, 1], 'parameters': {}}]}, 'num_repititions': 200}"

    # # circuit_json=JSON.json(circuit_dict)

    # write(
    #     joinpath(commonpath,"test_circuit.json"), 
    #     circuit_json
    # )

    return circuit_json
end


struct Client 
    host::String
    user::String
    access_token::String
    session::Any

    function Client(host::String, user::String,access_token::String)
        if occursin("8080",host)
            path_url=joinpath(host,"circuits/")
        else
            path_url=host
        end

        println("path_url: ",path_url)
        println("access_token: ",access_token)

        # session = HTTP.get(
        #     path_url,
        #     headers=Dict("Authorization"=>"Bearer $access_token"),
        #     cookies = true,
        # )
        session="none"

        println("session: ",session)

        new(host,user,access_token,session)
    end
end

get_host(client::Client)= client.host

function submit_circuit(client::Client,circuit_json::String) 
    if occursin("8080",host)
        path_url=joinpath(get_host(client),"circuits/")
    else
        path_url=host
    end
    
    HTTP.post(
        path_url, 
        headers=Dict("Authorization"=>"Bearer $(client.access_token)"),
        body=circuit_json
    )

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

function run(qpu_service::QPUService, circuit::QuantumCircuit,num_repetitions::Integer)
    circuit_json=serialize_circuit(circuit,num_repetitions)
        
    response=submit_circuit(get_client(qpu_service),circuit_json)

    println(response)
end

