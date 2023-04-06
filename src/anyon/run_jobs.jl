using Snowflake
using JSON
using HTTP

abstract type Requestor end

get_request(requestor::Requestor,::String,::String,::String) = 
    throw(NotImplementedError(:get_request,requestor))
post_request(requestor::Requestor,::String,::String,::String) = 
    throw(NotImplementedError(:post_request,requestor))

struct HTTPRequestor<:Requestor end
struct MockRequestor<:Requestor end

path_circuits="circuits"
path_results="result"
length_circuitID=37

function post_request(
    ::HTTPRequestor,
    url::String,
    access_token::String,
    body::String
    )

    return HTTP.post(
        url, 
        headers=Dict(
            "Authorization"=>"Bearer $access_token",
            "Content-Type"=>"application/json"
            ),
        body=body,
    )
end

function post_request(
    ::MockRequestor,
    url::String,
    access_token::String,
    body::String
    )::HTTP.Response

    expected_url=joinpath("http://example.anyonsys.com",path_circuits)
    expected_access_token="not_a_real_access_token"
    expected_json="{\"num_repititions\":100,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"

    @assert url==expected_url ("received: \n$url, \nexpected: \n$expected_url")
    @assert access_token==expected_access_token  ("received: \n$access_token, expected: \n$expected_access_token")
    @assert body==expected_json  ("received: \n$body, expected: \n$expected_json")

    return HTTP.Response(200, [], 
        body="{\"circuitID\":\"8050e1ed-5e4c-4089-ab53-cccda1658cd0\"}";
    )
end


function get_request(
    ::HTTPRequestor,
    url::String,
    access_token::String,
    )::HTTP.Response

    return HTTP.get(
        url, 
        headers=Dict(
            "Authorization"=>"Bearer $access_token",
            "Content-Type"=>"application/json"
            ),
    )
end

function get_request(
    ::MockRequestor,
    url::String,
    access_token::String
    )

    if endswith(url[1:end-length_circuitID],path_circuits)
        return HTTP.Response(200, [], 
            body="{\"status\":{\"type\":\"succeeded\"}}"
        )
    elseif endswith(url,path_results)
        return HTTP.Response(200, [], 
            body="{\"histogram\":{\"001\":\"100\"}}"
        ) 
    else
        throw(NotImplementedError(:get_request,url))
    end
end


"""
    serialize_circuit(circuit::QuantumCircuit,repetitions::Integer)

Creates a JSON-formatted String containing the circuit configuration to be sent 
to a `QPU` service, along with the number of repetitions requested.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2,gates=[sigma_x(1)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──X──
          
q[2]:─────
          



julia> serialize_circuit(c,10)
"{\\\"num_repititions\\\":10,\\\"circuit\\\":{\\\"operations\\\":[{\\\"parameters\\\":{},\\\"type\\\":\\\"x\\\",\\\"qubits\\\":[0]}]}}"

```
"""
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

"""
    Client

A data structure to represent a *Client* to a QPU service.  
# Fields
- `host::String` -- URL of the QPU server.
- `user::String` -- Username.
- `access_token::String` -- User access token.

# Example
```jldoctest
julia> c = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token")
Client for QPU service:
   host:         http://example.anyonsys.com
   user:         test_user 
   access_token: not_a_real_access_token 
 
  
```
"""
Base.@kwdef struct Client 
    host::String
    user::String
    access_token::String
    requestor::Requestor=HTTPRequestor()
end

function Base.show(io::IO, client::Client)
    println(io, "Client for QPU service:")
    println(io, "   host:         $(client.host)")
    println(io, "   user:         $(client.user) ")
    println(io, "   access_token: $(client.access_token) ")
end

"""
    get_host(Client)

Returns host URL of a `Client` to a `QPU` service.  

# Example
```jldoctest
julia> c = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token");

julia> get_host(c)
"http://example.anyonsys.com"

```
"""
get_host(client::Client)        =client.host
get_access_token(client::Client)=client.access_token
get_requestor(client::Client)   =client.requestor


"""
    submit_circuit(client::Client,circuit::QuantumCircuit,num_repetitions::Integer)

Submit a circuit to a `Client` of `QPU` service, requesting a number of 
repetitions (num_repetitions). Returns circuitID.  

# Example
```jldoctest
julia> c = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token",requestor=MockRequestor());
  
julia> submit_circuit(c,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]),100)
"8050e1ed-5e4c-4089-ab53-cccda1658cd0"

```
"""
function submit_circuit(client::Client,circuit::QuantumCircuit,num_repetitions::Integer)::String

    circuit_json=serialize_circuit(circuit,num_repetitions)
  
    path_url=joinpath(get_host(client),path_circuits)
    
    response=post_request(
        get_requestor(client),
        path_url,
        get_access_token(client),
        circuit_json)

    formatted_response=format_response(response)

    body=JSON.parse(formatted_response["body"])

    return body["circuitID"]
end

"""
    get_status(client::Client,circuitID::String)::Dict{String, String}

Obtain the status of a circuit computation through a `Client` of a `QPU` service.
Returns status::Dict containing status["type"]: 
    -"queued"   : Computation in queue.
    -"running"  : Computation being processed.
    -"failed"   : QPU service has returned an error message.
    -"succeeded": Computation is completed, result is available.

In the case of status["type"]=="failed", the server error is contained in status["message"].

# Example
```jldoctest
julia> client = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token",requestor=MockRequestor());
  
julia> circuitID=submit_circuit(client,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]),100)
"8050e1ed-5e4c-4089-ab53-cccda1658cd0"

julia> get_status(client,circuitID)
Dict{String, String} with 1 entry:
  "type" => "succeeded"

```
"""
function get_status(client::Client,circuitID::String)::Dict{String, String}

    path_url=joinpath(get_host(client),path_circuits,"$circuitID")
    
    response=get_request(
        get_requestor(client),
        path_url,
        get_access_token(client)
        )

    formatted_response=format_response(response)

    body=JSON.parse(formatted_response["body"])

    return body["status"]
end

"""
    get_result(client::Client,circuit::String)::Dict{String, Int}

Get the histogram of a completed circuit calculation, through a `Client` of a `QPU` service, 
by circuit identifier circuitID.

# Example
```jldoctest
julia> client = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token",requestor=MockRequestor());
  
julia> circuitID=submit_circuit(client,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]),100)
"8050e1ed-5e4c-4089-ab53-cccda1658cd0"

julia> get_status(client,circuitID);

julia> get_result(client,circuitID)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function get_result(client::Client,circuitID::String)::Dict{String, Int}

    path_url=joinpath(get_host(client),path_circuits,"$circuitID",path_results)
    
    response=get_request(
        get_requestor(client),
        path_url,
        get_access_token(client)
        )

    formatted_response=format_response(response)

    body=JSON.parse(formatted_response["body"])

    histogram=Dict{String,Int}()
    
    # convert from Dict{String,String} to Dict{String,Int}
    for (key,val) in body["histogram"]
        histogram[key]=parse(Int, val)
    end

    return histogram
end


abstract type AbstractQPU end

"""
    AnyonQPU

A data structure to represent a Anyon System's QPU.  
# Fields
- `client       ::Client` -- Client to the QPU server.
- `manufacturer ::String` -- QPU manufacturer.
- `generation   ::String` -- QPU generation.
- `serial_number::String` -- QPU serial number.
- `printout_delay::Real` -- milliseconds between get_status() printouts


# Example
```jldoctest
julia> c = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token");
  
julia> qpu=AnyonQPU(client=c)
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon 
   serial_number: ANYK202201 


```
"""
Base.@kwdef struct AnyonQPU <: AbstractQPU
    client        ::Client
    manufacturer  ::String  ="Anyon Systems Inc."
    generation    ::String  ="Yukon"
    serial_number ::String  ="ANYK202201"
    printout_delay::Real    =200. # milliseconds between get_status() printouts
end

get_client(qpu_service::AnyonQPU)=qpu_service.client
get_printout_delay(qpu_service::AnyonQPU)=qpu_service.printout_delay

function Base.show(io::IO, qpu::AnyonQPU)
    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(qpu.manufacturer)")
    println(io, "   generation:    $(qpu.generation) ")
    println(io, "   serial_number: $(qpu.serial_number) ")
end

"""
    VirtualQPU

A data structure to represent a Quantum Simulator.  
# Fields
- `developers   ::String`   -- Simulator developers.
- `package      ::String`   -- name of the underlying library package.

# Example
```jldoctest
julia> qpu=VirtualQPU()
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflake.jl


```
"""
Base.@kwdef struct VirtualQPU <: AbstractQPU
    developers  ::String  ="Anyon Systems Inc."
    package     ::String  ="Snowflake.jl"
end

function Base.show(io::IO, qpu::VirtualQPU)
    println(io, "Quantum Simulator:")
    println(io, "   developers:  $(qpu.developers)")
    println(io, "   package:     $(qpu.package)")
end


function format_response(response::HTTP.Messages.Response)
    formatted_response=Dict(
        "version"   =>response.version, 
        "status"    =>response.status, 
        "headers"   =>response.headers, 
    )

    # convert response body from binary to ASCII
    read_buffer=IOBuffer(reinterpret(UInt8, response.body))
    formatted_response["body"]=String(readuntil(read_buffer, 0x00))

    return formatted_response
end

"""
    run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified 
number of repetitions (num_repetitions). Returns the histogram of the 
completed circuit calculations, or an error message.

# Example
```jldoctest
julia> c = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token",requestor=MockRequestor());
  
julia> qpu=AnyonQPU(client=c);

julia> run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Circuit submitted: circuitID returned: 8050e1ed-5e4c-4089-ab53-cccda1658cd0

status: succeeded
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)::Dict{String,Int}
    
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
        return get_result(client,circuitID)
    end
end

"""
    run_job(qpu::VirtualQPU, circuit::QuantumCircuit,num_repetitions::Integer)

Run a circuit computation on a `QPU` simulator, repeatedly for the specified 
number of repetitions (num_repetitions). Returns the histogram of the 
completed circuit calculations.

# Example
```jldoctest 
julia> qpu=VirtualQPU();

julia> run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(qpu::VirtualQPU, circuit::QuantumCircuit,num_repetitions::Integer)::Dict{String,Int}
    
    data=simulate_shots(circuit, num_repetitions)
    
    histogram=Dict{String,Int}()

    for label in data
        if haskey(histogram,label)
            histogram[label]+=1
        else
            histogram[label]=1
        end
    end

    return histogram
end


