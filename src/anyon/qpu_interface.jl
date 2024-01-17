using Snowflurry
using Base64
using HTTP
using JSON
using TOML

Base.@kwdef struct Status
    type::String
    message::String = ""
end

get_status_type(s::Status) = s.type
get_status_message(s::Status) = s.message

function Base.show(io::IO, status::Status)
    if status.message == ""
        println(io, "Status: $(status.type)")
    else
        println(io, "Status: $(status.type)")
        println(io, "Message: $(status.message)")
    end
end

abstract type Requestor end

get_request(requestor::Requestor, ::String, ::String, ::String) =
    throw(NotImplementedError(:get_request, requestor))
post_request(requestor::Requestor, ::String, ::String, ::String, ::String) =
    throw(NotImplementedError(:post_request, requestor))

struct HTTPRequestor <: Requestor
    getter::Function
    poster::Function
end

struct MockRequestor <: Requestor
    request_checker::Function
    post_checker::Function
end

const user_agent_header_key = "User-Agent"

const path_jobs = "jobs"
const path_results = "result"

const queued_status = "QUEUED"
const running_status = "RUNNING"
const succeeded_status = "SUCCEEDED"
const failed_status = "FAILED"
const cancelled_status = "CANCELLED"

project_toml = TOML.parsefile("Project.toml")
@assert haskey(project_toml, "version") "missing version info in Project toml" 
const package_version = project_toml["version"]

const possible_status_list =
    [failed_status, succeeded_status, running_status, queued_status, cancelled_status]

function encode_to_basic_authorization(user::String, password::String)::String
    return "Basic " * base64encode(user * ":" * password)
end

function post_request(
    requestor::HTTPRequestor,
    url::String,
    user::String,
    access_token::String,
    body::String,
)::HTTP.Response

    return requestor.poster(
        url,
        headers = Dict(
            "Authorization" => encode_to_basic_authorization(user, access_token),
            "Content-Type" => "application/json",
            user_agent_header_key => "Snowflurry/$(package_version)",
        ),
        body = body,
    )
end

function post_request(
    mock_requester::MockRequestor,
    url::String,
    user::String,
    access_token::String,
    body::String,
)::HTTP.Response

    return mock_requester.post_checker(url, user, access_token, body)
end

function get_request(
    requestor::HTTPRequestor,
    url::String,
    user::String,
    access_token::String,
)::HTTP.Response

    return requestor.getter(
        url,
        headers = Dict(
            "Authorization" => encode_to_basic_authorization(user, access_token),
            "Content-Type" => "application/json",
            user_agent_header_key => "Snowflurry/$(package_version)",
        ),
    )
end

function get_request(
    mock_requestor::MockRequestor,
    url::String,
    user::String,
    access_token::String,
)::HTTP.Response

    return mock_requestor.request_checker(url, user, access_token)
end

const error_msg_empty_project_id = "project_id cannot be empty"

"""
    serialize_job(circuit::QuantumCircuit,shot_count::Integer,host::String)

Creates a JSON-formatted String containing the circuit configuration to be sent 
to a `QPU` service located at the URL specified by `host`, along with the number of shots requested.

# Examples
```jldoctest
julia> c = QuantumCircuit(qubit_count = 2, instructions = [sigma_x(1)], name = "sigma_x job")
Quantum Circuit Object:
   qubit_count: 2 
   bit_count: 2 
q[1]:──X──
          
q[2]:─────
          
julia> serialize_job(c, 10, "http://example.anyonsys.com", "project_id")
"{\\\"shotCount\\\":10,\\\"name\\\":\\\"sigma_x job\\\",\\\"machineID\\\":\\\"http://example.anyonsys.com\\\",\\\"billingaccountID\\\":\\\"project_id\\\",\\\"type\\\":\\\"circuit\\\",\\\"circuit\\\":{\\\"operations\\\":[{\\\"parameters\\\":{},\\\"type\\\":\\\"x\\\",\\\"qubits\\\":[0]}]}}"

```
"""
function serialize_job(
    circuit::QuantumCircuit,
    shot_count::Integer,
    host::String,
    project_id::String,
)::String

    if project_id == ""
        throw(ArgumentError(error_msg_empty_project_id))
    end

    job_description = Dict(
        "name" => get_name(circuit),
        "type" => "circuit",
        "machineID" => host,
        "billingaccountID" => project_id,
        "circuit" => Dict{String,Any}("operations" => Vector{Dict{String,Any}}()),
        "shotCount" => shot_count,
    )


    for instr in get_circuit_instructions(circuit)
        if instr isa Readout
            encoding = Dict{String,Any}(
                "type" => get_instruction_symbol(instr),
                #server-side qubit numbering starts at 0
                "qubits" => [n - 1 for n in get_connected_qubits(instr)],
                "bits" => [get_destination_bit(instr) - 1],
            )
        else
            params = get_gate_parameters(get_gate_symbol(instr))
            encoding = Dict{String,Any}(
                "type" => get_instruction_symbol(instr),
                #server-side qubit numbering starts at 0
                "qubits" => [n - 1 for n in get_connected_qubits(instr)],
                "parameters" => params,
            )
        end
        push!(job_description["circuit"]["operations"], encoding)
    end

    job_json = JSON.json(job_description)

    return job_json
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
julia> c = Client(host = "http://example.anyonsys.com", user = "test_user", access_token = "not_a_real_access_token")
Client for QPU service:
   host:         http://example.anyonsys.com
   user:         test_user 
 
```
"""
Base.@kwdef struct Client
    host::String
    user::String
    access_token::String
    requestor::Requestor = HTTPRequestor(HTTP.get, HTTP.post)
end

function Base.show(io::IO, client::Client)
    println(io, "Client for QPU service:")
    println(io, "   host:         $(client.host)")
    println(io, "   user:         $(client.user) ")
end

"""
    get_host(Client)

Returns host URL of a `Client` to a `QPU` service.  

# Example
```jldoctest
julia> c = Client(host = "http://example.anyonsys.com", user = "test_user", access_token = "not_a_real_access_token");

julia> get_host(c)
"http://example.anyonsys.com"

```
"""
get_host(client::Client) = client.host
get_requestor(client::Client) = client.requestor


"""
    submit_job(client::Client,circuit::QuantumCircuit,shot_count::Integer)

Submit a circuit to a `Client` of `QPU` service, requesting a number of 
repetitions (shot_count). Returns circuitID.

# Example

```jldoctest mylabel
julia> submit_job(client, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1)]), 100, "project_id")
"8050e1ed-5e4c-4089-ab53-cccda1658cd0"

```
"""
function submit_job(
    client::Client,
    circuit::QuantumCircuit,
    shot_count::Integer,
    project_id::String,
)::String

    job_json = serialize_job(circuit, shot_count, get_host(client), project_id)

    path_url = get_host(client) * "/" * path_jobs

    response = post_request(
        get_requestor(client),
        path_url,
        client.user,
        client.access_token,
        job_json,
    )

    body = JSON.parse(read_response_body(response.body))

    @assert haskey(body, "id") (
        "Server returned an invalid response, without a job ID field."
    )

    return body["id"]
end

"""
    get_status(client::Client,circuitID::String)::Tuple{Status,Dict{String,Int}}

Obtain the status of a circuit computation through a `Client` of a `QPU` service.
Returns status::Dict containing status["type"]: 
    -"QUEUED"   : Computation in queue
    -"RUNNING"  : Computation being processed
    -"FAILED"   : QPU service has returned an error message
    -"SUCCEEDED": Computation is completed, result is available.

In the case of status["type"]=="FAILED", the server error is contained in status["message"].

In the case of status["type"]=="SUCCEEDED", the second element in the return Tuple is 
the histogram of the job results, as computed on the `QPU`.

# Example


```jldoctest
julia> jobID = submit_job(client, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1)]), 100, "project_id")
"8050e1ed-5e4c-4089-ab53-cccda1658cd0"

julia> get_status(client, jobID)
(Status: SUCCEEDED
, Dict("001" => 100))

```
"""
function get_status(client::Client, circuitID::String)::Tuple{Status,Dict{String,Int}}

    path_url = get_host(client) * "/" * path_jobs * "/" * "$circuitID"

    response =
        get_request(get_requestor(client), path_url, client.user, client.access_token)

    body = JSON.parse(read_response_body(response.body))

    @assert haskey(body, "status") "missing \"status\" key in body: $body"
    @assert haskey(body["status"], "type") "missing \"type\" key in body: $body"

    if !(body["status"]["type"] in possible_status_list)
        throw(
            ArgumentError(
                "Server returned unrecognized status type: $(body["status"]["type"])",
            ),
        )
    end

    if body["status"]["type"] == failed_status
        message = if haskey(body["status"], "message")
            body["status"]["message"]
        else
            "no failure information available. raw response: '$(string(body))'"
        end
        return Status(type = failed_status, message = message), Dict{String,Int}()

    elseif body["status"]["type"] == cancelled_status
        return Status(type = body["status"]["type"]), Dict{String,Int}()

    elseif body["status"]["type"] == queued_status ||
           body["status"]["type"] == running_status
        return Status(type = body["status"]["type"]), Dict{String,Int}()

    else
        @assert body["status"]["type"] == succeeded_status
        @assert haskey(body, "result") "missing \"result\" key in body: $body"
        result = body["result"]

        # convert from Dict{String,String} to Dict{String,Int}
        histogram = Dict{String,Int}()
        @assert haskey(result, "histogram") "missing \"histogram\" key in body: $body"
        for (key, val) in result["histogram"]
            histogram[key] = round(Int, val)
        end

        return Status(type = body["status"]["type"]), histogram
    end
end

abstract type AbstractQPU end

get_metadata(qpu::AbstractQPU) = throw(NotImplementedError(:get_metadata, qpu))

is_native_instruction(qpu::AbstractQPU, ::AbstractInstruction) =
    throw(NotImplementedError(:is_native_instruction, qpu))

is_native_circuit(qpu::AbstractQPU, ::QuantumCircuit) =
    throw(NotImplementedError(:is_native_circuit, qpu))

get_transpiler(qpu::AbstractQPU) = throw(NotImplementedError(:get_transpiler, qpu))

run_job(qpu::AbstractQPU, circuit::QuantumCircuit, shot_count::Integer) =
    throw(NotImplementedError(:run_job, qpu))

get_connectivity(qpu::AbstractQPU) = throw(NotImplementedError(:get_connectivity, qpu))

"""
    VirtualQPU

A data structure to represent a Quantum Simulator.  

# Example
```jldoctest
julia> qpu = VirtualQPU()
Quantum Simulator:
   developers:  Anyon Systems Inc.
   package:     Snowflurry.jl


```
"""
struct VirtualQPU <: AbstractQPU end

get_metadata(qpu::VirtualQPU) =
    Dict{String,String}("developers" => "Anyon Systems Inc.", "package" => "Snowflurry.jl")

is_native_instruction(::VirtualQPU, ::AbstractInstruction)::Bool = true

is_native_circuit(::VirtualQPU, ::QuantumCircuit)::Tuple{Bool,String} = (true, "")

get_transpiler(::VirtualQPU) = SequentialTranspiler([
    CircuitContainsAReadoutTranspiler(),
    ReadoutsDoNotConflictTranspiler(),
    ReadoutsAreFinalInstructionsTranspiler(),
])

get_connectivity(::VirtualQPU) = AllToAllConnectivity()
get_connectivity_label(::AllToAllConnectivity) = all2all_connectivity_label


function Base.show(io::IO, qpu::VirtualQPU)
    metadata = get_metadata(qpu)

    println(io, "Quantum Simulator:")
    println(io, "   developers:  $(metadata["developers"])")
    println(io, "   package:     $(metadata["package"])")
end

read_response_body(body::Base.CodeUnits{UInt8,String}) =
    read_response_body(convert(Vector{UInt8}, body))

function read_response_body(body::Vector{UInt8})::String
    # convert response body from binary to ASCII
    read_buffer = IOBuffer(reinterpret(UInt8, body))
    body_string = String(readuntil(read_buffer, 0x00))

    if length(body_string) != length(body)
        throw(
            ArgumentError(
                "Server returned an erroneous message, with nul terminator before end of string.",
            ),
        )
    end

    return body_string
end

"""
    transpile_and_run_job(qpu::VirtualQPU, circuit::QuantumCircuit,shot_count::Integer; transpiler::Transpiler = get_transpiler(qpu))

This method first transpiles the input circuit using either the default transpiler,
or any other transpiler passed as a key-word argument.
The transpiled circuit is then run on a `QPU` simulator, repeatedly for the specified
number of repetitions (shot_count). Returns the histogram of the
completed circuit calculations, or an error message.

# Example
```jldoctest 
julia> qpu=VirtualQPU();

julia> transpile_and_run_job(qpu, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1), readout(1, 1), readout(2, 2), readout(3, 3)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function transpile_and_run_job(
    qpu::VirtualQPU,
    circuit::QuantumCircuit,
    shot_count::Integer;
    transpiler::Transpiler = get_transpiler(qpu),
)::Dict{String,Int}

    transpiled_circuit = transpile(transpiler, circuit)

    (passed, message) = is_native_circuit(qpu, transpiled_circuit)

    @assert passed "All circuits should be native on VirtualQPU"

    return run_job(qpu, transpiled_circuit, shot_count)
end

"""
    run_job(qpu::VirtualQPU, circuit::QuantumCircuit, shot_count::Integer)

Run a circuit computation on a `QPU` simulator, repeatedly for the specified
number of repetitions (shot_count). Returns the histogram of the
completed circuit measurements, as prescribed by the `Readouts` present.

# Example
```jldoctest 
julia> qpu = VirtualQPU();

julia> run_job(qpu, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1), readout(1, 1), readout(2, 2), readout(3, 3)]), 100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(
    qpu::VirtualQPU,
    circuit::QuantumCircuit,
    shot_count::Integer,
)::Dict{String,Int}

    data = simulate_shots(circuit, shot_count)

    histogram = Dict{String,Int}()

    for label in data
        if haskey(histogram, label)
            histogram[label] += 1
        else
            histogram[label] = 1
        end
    end

    return histogram
end
