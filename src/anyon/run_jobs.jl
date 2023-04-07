using Snowflake
using JSON
using HTTP

Base.@kwdef struct Status
    type::String
    message::String=""
end

get_status_type(s::Status)=s.type
get_status_message(s::Status)=s.message

function Base.show(io::IO, status::Status)
    if status.message ==""
        println(io, "Status: $(status.type)")
    else
        println(io, "Status: $(status.type)")
        println(io, "Message: $(status.message)")
    end
end

abstract type Requestor end

get_request(requestor::Requestor,::String,::String,::String) = 
    throw(NotImplementedError(:get_request,requestor))
post_request(requestor::Requestor,::String,::String,::String) = 
    throw(NotImplementedError(:post_request,requestor))

struct HTTPRequestor<:Requestor end
struct MockRequestor<:Requestor end

const path_circuits ="circuits"
const path_results  ="result"

const queued_status     ="queued"
const running_status    ="running"
const succeeded_status  ="succeeded"
const failed_status     ="failed"
const cancelled_status  ="cancelled"

const possible_status_list=[
    failed_status,
    succeeded_status,
    running_status,
    queued_status,
    cancelled_status,
]

function post_request(
    ::HTTPRequestor,
    url::String,
    access_token::String,
    body::String
    )::HTTP.Response

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
    )::HTTP.Response

    myregex=Regex("(.*)(/$path_circuits/)(.*)")
    match_obj=match(myregex,url)

    if !isnothing(match_obj)

        myregex=Regex("(.*)(/$path_circuits/)(.*)(/$path_results)")   
        match_obj=match(myregex,url)
                
        if !isnothing(match_obj)
            # caller is :get_result
            return HTTP.Response(200, [], 
                body="{\"histogram\":{\"001\":\"100\"}}"
            ) 
        else
            # caller is :get_status
            return HTTP.Response(200, [], 
                body="{\"status\":{\"type\":\"succeeded\"}}"
            )
        end
    end

    throw(NotImplementedError(:get_request,url))
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
function serialize_circuit(circuit::QuantumCircuit,repetitions::Integer)::String
  
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

    body=JSON.parse(read_response_body(response.body))

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
Status: succeeded

```
"""
function get_status(client::Client,circuitID::String)::Status

    path_url=joinpath(get_host(client),path_circuits,"$circuitID")
    
    response=get_request(
        get_requestor(client),
        path_url,
        get_access_token(client)
        )

    body=JSON.parse(read_response_body(response.body))

    @assert body["status"]["type"] in possible_status_list

    if body["status"]["type"]==failed_status
        return Status(type=body["status"]["type"],message=body["message"])
    else
        return Status(type=body["status"]["type"])
    end
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

    body=JSON.parse(read_response_body(response.body))

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
  
julia> qpu=AnyonQPU(client=c,manufacturer="Anyon Systems Inc.",generation="Yukon",serial_number="ANYK202201")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon 
   serial_number: ANYK202201 


```
"""
Base.@kwdef struct AnyonQPU <: AbstractQPU
    client        ::Client
    manufacturer  ::String
    generation    ::String
    serial_number ::String
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
julia> qpu=VirtualQPU("Anyon Systems Inc.","Snowflake.jl")
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflake.jl


```
"""
struct VirtualQPU <: AbstractQPU
    developers  ::String
    package     ::String
end

function Base.show(io::IO, qpu::VirtualQPU)
    println(io, "Quantum Simulator:")
    println(io, "   developers:  $(qpu.developers)")
    println(io, "   package:     $(qpu.package)")
end

function read_response_body(body::Vector{UInt8})::String
    # convert response body from binary to ASCII
    read_buffer=IOBuffer(reinterpret(UInt8, body))
    body_string=String(readuntil(read_buffer, 0x00))

    if length(body_string)!=length(body)
        throw(ArgumentError("Server returned an erroneous message, with nul terminator before end of string."))
    end

    return body_string
end

"""
    run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified 
number of repetitions (num_repetitions). Returns the histogram of the 
completed circuit calculations, or an error message.

# Example
```jldoctest
julia> c = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token",requestor=MockRequestor());
  
julia> qpu=AnyonQPU(client=c,manufacturer="Anyon Systems Inc.",generation="Yukon",serial_number="ANYK202201");

julia> run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Status: succeeded

Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)::Dict{String,Int}
    
    client=get_client(qpu)

    circuitID=submit_circuit(client,circuit,num_repetitions)

    status=get_status(client,circuitID;)

    ref_time_print=Base.time_ns()
    printout_delay=get_printout_delay(qpu)/1e6 #convert ms to ns
 
    ref_time_query=Base.time_ns()
    query_delay=100/1e6 #100 ms between queries to host

    while true        
        current_time=Base.time_ns()

        if (current_time-ref_time_print)>printout_delay
            println(status)
            ref_time_print=current_time
        end

        if (current_time-ref_time_query)>query_delay
            status=get_status(client,circuitID;)
            ref_time_query=current_time
        end
           
        if !(get_status_type(status) in [queued_status,running_status])
            break
        end

    end
    
    if get_status_type(status) == failed_status       
        return Dict("error_msg"=>get_status_message(status))

    elseif get_status_type(status) == cancelled_status       
        return Dict("error_msg"=>cancelled_status)
    
    else # computation succeeded
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
julia> qpu=VirtualQPU("Anyon Systems Inc.","Snowflake.jl");

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


