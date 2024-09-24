using Snowflurry

const AnyonYukonConnectivity = LineConnectivity(6)
const AnyonYamaskaConnectivity = LatticeConnectivity(6, 4)

const Metadata = Dict{String,Union{String,Int,Vector{Int},Vector{Tuple{Int,Int}}}}

"""
    AnyonYukonQPU <: AbstractQPU

A data structure to represent an Anyon System's Yukon generation QPU, 
consisting of 6 qubits in a linear arrangement (see [`LineConnectivity`](@ref)). 
# Fields
- `client                  ::Client` -- Client to the QPU server.
- `status_request_throttle ::Function` -- Used to rate-limit job status requests.
- `project_id              ::String` -- Used to identify which project the jobs sent to this QPU belong to.
- `realm                   ::String` -- Optional: used to identify to which realm on the host server requests are sent to.

# Example
```jldoctest
julia>  qpu = AnyonYukonQPU(host = "http://example.anyonsys.com", user = "test_user", access_token = "not_a_real_access_token", project_id = "test-project", realm = "test-realm")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   project_id:    test-project
   qubit_count:   6 
   connectivity_type:  linear
   realm:         test-realm
```
"""
struct AnyonYukonQPU <: AbstractQPU
    client::Client
    status_request_throttle::Function
    connectivity::LineConnectivity
    project_id::String
    metadata::Metadata

    function AnyonYukonQPU(
        client::Client,
        project_id::String = "";
        status_request_throttle = default_status_request_throttle,
    )
        new(client, status_request_throttle, AnyonYukonConnectivity, project_id, Metadata())
    end

    function AnyonYukonQPU(;
        host::String,
        user::String,
        access_token::String,
        project_id::String = "",
        realm::String = "",
        status_request_throttle = default_status_request_throttle,
    )
        new(
            Client(host = host, user = user, access_token = access_token, realm = realm),
            status_request_throttle,
            AnyonYukonConnectivity,
            project_id,
            Metadata(),
        )
    end
end

"""
    AnyonYamaskaQPU <: AbstractQPU

A data structure to represent an Anyon System's Yamaska generation QPU, 
consisting of 24 qubits in a 2D lattice arrangement (see [`LatticeConnectivity`](@ref)).
# Fields
- `client                  ::Client` -- Client to the QPU server.
- `status_request_throttle ::Function` -- Used to rate-limit job status requests.
- `project_id              ::String` -- Used to identify which project the jobs sent to this QPU belong to.
- `realm                   ::String` -- Optional: used to identify to which realm on the host server requests are sent to.

# Example
```jldoctest
julia>  qpu = AnyonYamaskaQPU(host = "http://example.anyonsys.com", user = "test_user", access_token = "not_a_real_access_token", project_id = "test-project", realm = "test-realm")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yamaska
   serial_number: ANYK202301
   project_id:    test-project
   qubit_count:   24 
   connectivity_type:  2D-lattice
   realm:         test-realm
```
"""
struct AnyonYamaskaQPU <: AbstractQPU
    client::Client
    status_request_throttle::Function
    connectivity::LatticeConnectivity
    project_id::String
    metadata::Metadata

    function AnyonYamaskaQPU(
        client::Client,
        project_id::String = "";
        status_request_throttle = default_status_request_throttle,
    )
        new(
            client,
            status_request_throttle,
            AnyonYamaskaConnectivity,
            project_id,
            Metadata(),
        )
    end
    function AnyonYamaskaQPU(;
        host::String,
        user::String,
        access_token::String,
        project_id::String = "",
        realm::String = "",
        status_request_throttle = default_status_request_throttle,
    )
        new(
            Client(host = host, user = user, access_token = access_token, realm = realm),
            status_request_throttle,
            AnyonYamaskaConnectivity,
            project_id,
            Metadata(),
        )
    end
end

UnionAnyonQPU = Union{AnyonYukonQPU,AnyonYamaskaQPU}

const AnyonYukonMachineName = "yukon"
const AnyonYamaskaMachineName = "yamaska"
const AnyonVirtualMachineName = "virtual"

get_machine_name(::AnyonYukonQPU)::String = AnyonYukonMachineName
get_machine_name(::AnyonYamaskaQPU)::String = AnyonYamaskaMachineName
get_machine_name(::VirtualQPU)::String = AnyonVirtualMachineName

get_client(qpu_service::UnionAnyonQPU) = qpu_service.client

get_project_id(qpu_service::UnionAnyonQPU) = qpu_service.project_id

get_realm(qpu_service::UnionAnyonQPU) = get_realm(qpu_service.client)

get_num_qubits(qpu::UnionAnyonQPU) = get_num_qubits(qpu.connectivity)

function get_connectivity(qpu::UnionAnyonQPU)
    md = get_metadata(qpu)

    if length(md["excluded_positions"]) > 0
        return with_excluded_positions(qpu.connectivity, md["excluded_positions"])
    end

    return qpu.connectivity
end

print_connectivity(qpu::AbstractQPU, io::IO = stdout) =
    print_connectivity(get_connectivity(qpu), Int[], io)

get_excluded_positions(qpu::UnionAnyonQPU) = get_excluded_positions(get_connectivity(qpu))

function get_metadata(qpu::UnionAnyonQPU)::Metadata
    if isempty(qpu.metadata)
        for (k, v) in get_metadata(qpu.client, qpu)
            qpu.metadata[k] = v
        end
    end
    return qpu.metadata
end

function Base.show(io::IO, qpu::UnionAnyonQPU)
    metadata = get_metadata(qpu)

    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(metadata["manufacturer"])")
    println(io, "   generation:    $(metadata["generation"])")
    println(io, "   serial_number: $(metadata["serial_number"])")
    println(io, "   project_id:    $(metadata["project_id"])")
    println(io, "   qubit_count:   $(metadata["qubit_count"])")
    println(io, "   connectivity_type:  $(metadata["connectivity_type"])")

    if haskey(metadata, "realm")
        println(io, "   realm:         $(metadata["realm"])")
    end
end


set_of_native_gates = [
    Identity,
    PhaseShift,
    Pi8,
    Pi8Dagger,
    SigmaX,
    SigmaY,
    SigmaZ,
    X90,
    XM90,
    Y90,
    YM90,
    Z90,
    ZM90,
    ControlZ,
]

const PATH_MACHINES = "machines"

function assert_expected_entry(
    metadata::Dict{String,Any},
    expected_key::String,
    expected_value::Any,
)
    @assert haskey(metadata, expected_key) "key \"$expected_key\" missing from returned metadata"
    @assert metadata[expected_key] == expected_value "expected: \"$expected_value\", received \"$(metadata[expected_key])\" in returned metadata key \"$(expected_key)\""
end

function get_metadata(client::Client, qpu::UnionAnyonQPU)::Metadata

    path_url = get_host(client) * "/" * PATH_MACHINES

    response = get_request(
        get_requestor(client),
        path_url,
        client.user,
        client.access_token,
        get_realm(client),
        Dict{String,String}("machineName" => get_machine_name(qpu)),
    )

    raw_body = read_response_body(response.body)

    @assert length(raw_body) > 2 "cannot parse response: $(response.body)"

    body = JSON.parse(raw_body)

    @assert body["total"] == 1 "invalid server response, should only return metadata for a single machine. Received: $body"

    @assert length(body["items"]) > 0 "no metadata exists for machine with name $(get_machine_name(qpu))"
    @assert length(body["items"]) == 1 "invalid server response, should only return metadata for a single machine. Received: $body"

    machineMetadata = body["items"][1]
    serial_number = ""

    if qpu isa AnyonYukonQPU
        assert_expected_entry(machineMetadata, "name", "yukon")
        assert_expected_entry(machineMetadata, "type", "quantum-computer")
        assert_expected_entry(machineMetadata, "qubitCount", 6)
        assert_expected_entry(machineMetadata, "bitCount", 6)
        assert_expected_entry(machineMetadata, "connectivity", "linear")

        generation = "Yukon"
    else
        # qpu isa AnyonYamaskaQPU
        assert_expected_entry(machineMetadata, "name", "yamaska")
        assert_expected_entry(machineMetadata, "type", "quantum-computer")
        assert_expected_entry(machineMetadata, "qubitCount", 24)
        assert_expected_entry(machineMetadata, "bitCount", 24)
        assert_expected_entry(machineMetadata, "connectivity", "lattice")

        generation = "Yamaska"
    end

    @assert haskey(machineMetadata, "status") "key \"status\" missing from returned metadata"

    if haskey(machineMetadata, "metadata")
        if haskey(machineMetadata["metadata"], "Serial Number")
            serial_number = machineMetadata["metadata"]["Serial Number"]
        end
    end

    output = Metadata(
        "manufacturer" => "Anyon Systems Inc.",
        "generation" => generation,
        "serial_number" => serial_number,
        "project_id" => get_project_id(qpu),
        "qubit_count" => get_num_qubits(qpu.connectivity),
        "connectivity_type" => get_connectivity_label(qpu.connectivity),
        "status" => machineMetadata["status"],
    )

    if haskey(machineMetadata, "disconnectedQubits")
        output["excluded_positions"] =
            convert(Vector{Int}, machineMetadata["disconnectedQubits"])
    else
        output["excluded_positions"] = Vector{Int}()
    end

    if haskey(machineMetadata, "disconnectedConnections")
        raw_excluded_connections =
            convert(Vector{Vector{Int}}, machineMetadata["disconnectedConnections"])
        output["excluded_connections"] =
            convert_excluded_connections(raw_excluded_connections)
    else
        output["excluded_connections"] = Vector{Tuple{Int,Int}}()
    end

    realm = get_realm(qpu)
    if realm != ""
        output["realm"] = realm
    end

    return output
end

function convert_excluded_connections(
    excluded_connections::Vector{Vector{Int}},
)::Vector{Tuple{Int,Int}}

    num_connections = length(excluded_connections)
    converted_connections = Vector{Tuple{Int,Int}}(undef, num_connections)

    for (i_connection, connection) in enumerate(excluded_connections)
        if length(connection) != 2
            throw(ErrorException("the coupler $connection does not involve 2 qubits"))
        end
        converted_connections[i_connection] = (connection[1], connection[2])
    end

    return converted_connections
end

"""
    get_qubits_distance(target_1::Int, target_2::Int, ::AbstractConnectivity) 

Find the length of the shortest path between target qubits in terms of 
Manhattan distance, using the Breadth-First Search algorithm, on any 
`connectivity::AbstractConnectivity`.

# Example
```jldoctest
julia>  connectivity = LineConnectivity(6)
LineConnectivity{6}
1──2──3──4──5──6


julia> get_qubits_distance(2, 5, connectivity)
3

julia> connectivity = LatticeConnectivity(6, 4)
LatticeConnectivity{6,4}
              1 
              | 
        9 ──  5 ──  2 
        |     |     | 
 17 ── 13 ── 10 ──  6 ──  3 
  |     |     |     |     | 
 21 ── 18 ── 14 ── 11 ──  7 ──  4 
        |     |     |     |     | 
       22 ── 19 ── 15 ── 12 ──  8 
              |     |     | 
             23 ── 20 ── 16 
                    | 
                   24 


julia> get_qubits_distance(3, 24, connectivity)
5

```

"""
function get_qubits_distance(
    target_1::Int,
    target_2::Int,
    connectivity::Union{LineConnectivity,LatticeConnectivity},
)::Real

    path = path_search(target_1, target_2, connectivity)

    if isempty(path)
        return Inf
    end

    # Manhattan distance
    return length(path) - 1
end

"""
    is_native_instruction(
        gate::Union{Gate},
        connectivity::Union{LineConnectivity,LatticeConnectivity},
        native_gates::Vector{DataType} = set_of_native_gates,
    )::Bool

Returns `true` if the `gate` is a native instruction for the `connectivity` and the list of
possible `native_gates`. The native gates for the Anyon QPUs are used by default.

A native instruction is defined as an instruction that is in `native_gates` and that
satisifies the `connectivity`. It does not check to determine if the `gate` is placed at
the `excluded_positions` or `excluded_connections` of the `connectivity`. The gate must
operate on less than three qubits.

# Example

```jldoctest  
julia> connectivity = LineConnectivity(3)
LineConnectivity{3}
1──2──3


julia> is_native_instruction(control_z(1, 2), connectivity)
true

julia> is_native_instruction(control_z(1, 3), connectivity)
false

julia> is_native_instruction(control_x(1, 2), connectivity)
false

julia> is_native_instruction(control_x(1, 2), connectivity, [Snowflurry.ControlX])
true

julia> is_native_instruction(toffoli(1, 2, 3), connectivity, [Snowflurry.Toffoli])
false

```
"""
function is_native_instruction(
    gate::Gate,
    connectivity::GeometricConnectivity,
    native_gates::Vector{DataType} = set_of_native_gates,
)::Bool

    num_qubits = get_num_qubits(connectivity)
    qubits = get_connected_qubits(gate)
    if any(x -> (x > num_qubits), qubits)
        return false
    end

    num_connected_qubits = length(qubits)
    if num_connected_qubits == 2
        distance = get_qubits_distance(qubits[1], qubits[2], connectivity)
        if distance != 1
            return false
        end
    end

    if num_connected_qubits > 2
        return false
    end

    return (typeof(get_gate_symbol(gate)) in native_gates)
end

function is_native_instruction(gate::Gate, connectivity::AllToAllConnectivity)::Bool
    throw(NotImplementedError(:is_native_instruction, connectivity))
end

"""
    is_native_instruction(
        readout::Readout,
        connectivity::Union{LineConnectivity,LatticeConnectivity},
        native_gates::Vector{DataType} = set_of_native_gates,
    )::Bool

Returns `true` if the `readout` satisfies the connectivity.

It does not check to determine if the `gate` is placed at the `excluded_positions` of the
`connectivity`.

# Example

```jldoctest  
julia> connectivity = LineConnectivity(3)
LineConnectivity{3}
1──2──3


julia> is_native_instruction(readout(2, 2), connectivity)
true

julia> is_native_instruction(readout(4, 4), connectivity)
false

```
"""
function is_native_instruction(
    readout::Readout,
    connectivity::GeometricConnectivity,
    native_gates::Vector{DataType} = set_of_native_gates,
)::Bool

    num_qubits = get_num_qubits(connectivity)
    return readout.connected_qubit <= num_qubits
end

"""
    is_native_circuit(
        circuit::QuantumCircuit,
        connectivity::GeometricConnectivity,
        native_gates::Vector{DataType} = set_of_native_gates,
    )::Tuple{Bool,String}

Returns `(true, "")` if the `circuit` only contains native instructions for the
`connectivity` and the list of possible `native_gates`. It returns
`(false, "error_message")` otherwise. The native gates for the Anyon QPUs are used by
default.

See [`is_native_instruction`](@ref) for more details about the identification of native
instructions.

# Example

```jldoctest is_native_instruction
julia> connectivity = LineConnectivity(3)
LineConnectivity{3}
1──2──3


julia> native_circuit = QuantumCircuit(
           qubit_count = 3,
           instructions = [sigma_x(1), control_z(2, 3)]
       )
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X───────
               
q[2]:───────*──
            |  
q[3]:───────Z──
               

julia> is_native_circuit(native_circuit, connectivity)
(true, "")

julia> foreign_circuit = QuantumCircuit(
                  qubit_count = 3,
                  instructions = [sigma_x(1), control_x(2, 3)]
              )
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X───────
               
q[2]:───────*──
            |  
q[3]:───────X──
               

julia> is_native_circuit(foreign_circuit, connectivity)
(false, "Instruction type Gate{Snowflurry.ControlX} with targets [2, 3] is not native on the connectivity")

julia> is_native_circuit(
            foreign_circuit,
            connectivity,
            [Snowflurry.ControlX, Snowflurry.SigmaX]
        )
(true, "")

```

The folowing circuit is not native because the Toffoli gate is applied to more than two
qubits:
```jldoctest is_native_instruction
julia> foreign_circuit = QuantumCircuit(
           qubit_count = 3,
           instructions = [sigma_x(1), toffoli(1, 2, 3)]
       )
Quantum Circuit Object:
   qubit_count: 3 
   bit_count: 3 
q[1]:──X────*──
            |  
q[2]:───────*──
            |  
q[3]:───────X──
               

julia> is_native_circuit(
            foreign_circuit,
            connectivity,
            [Snowflurry.Toffoli, Snowflurry.SigmaX]
        )
(false, "Instruction type Gate{Snowflurry.Toffoli} with targets [1, 2, 3] is not native on the connectivity")

```
"""
function is_native_circuit(
    circuit::QuantumCircuit,
    connectivity::GeometricConnectivity,
    native_gates::Vector{DataType} = set_of_native_gates,
)::Tuple{Bool,String}

    qubit_count_circuit = get_num_qubits(circuit)
    qubit_count_qpu = get_num_qubits(connectivity)
    if qubit_count_circuit > qubit_count_qpu
        return (
            false,
            "Circuit qubit count $qubit_count_circuit exceeds $(typeof(connectivity)) qubit count: $qubit_count_qpu",
        )
    end

    for instr in get_circuit_instructions(circuit)
        if !is_native_instruction(instr, connectivity, native_gates)
            return (
                false,
                "Instruction type $(typeof(instr)) with targets $(get_connected_qubits(instr))" *
                " is not native on the connectivity",
            )
        end
    end

    return (true, "")
end

function is_native_circuit(
    circuit::QuantumCircuit,
    connectivity::AllToAllConnectivity,
    native_gates::Vector{DataType} = set_of_native_gates,
)::Tuple{Bool,String}

    throw(NotImplementedError(:is_native_circuit, connectivity))
end

"""
    transpile_and_run_job(qpu::AnyonYukonQPU, circuit::QuantumCircuit, shot_count::Integer; transpiler::Transpiler = get_transpiler(qpu))

This method first transpiles the input circuit using either the default
transpiler, or any other transpiler passed as a key-word argument.
The transpiled circuit is then run on the AnyonYukonQPU, repeatedly for the
specified number of repetitions (shot_count).

Returns the histogram of the completed circuit calculations, along with the job's 
execution time on the `QPU` (in milliseconds), or an error message.

# Example

```jldoctest  
julia> qpu = AnyonYukonQPU(client_anyon, "project_id");

julia> transpile_and_run_job(qpu, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1), readout(3, 3)]), 100)
(Dict("001" => 100), 542)

```
"""
function transpile_and_run_job(
    qpu::UnionAnyonQPU,
    circuit::QuantumCircuit,
    shot_count::Integer;
    transpiler::Transpiler = get_transpiler(qpu),
)::Tuple{Dict{String,Int},Int}

    transpiled_circuit = transpile(transpiler, circuit)

    return run_job(qpu, transpiled_circuit, shot_count)
end

"""
    run_job(qpu::AnyonYukonQPU, circuit::QuantumCircuit, shot_count::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified
number of repetitions (shot_count).
Returns the histogram of the completed circuit calculations, along with the 
simulation's execution time (in milliseconds) or an error
message.
If the circuit received in invalid - for instance, it is missing a `Readout` -
it is not sent to the host, and an error is throw.

# Example

```jldoctest  
julia> qpu = AnyonYukonQPU(client, "project_id")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   project_id:    project_id
   qubit_count:   6 
   connectivity_type:  linear
   realm:         test-realm

julia> run_job(qpu, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1), readout(1, 1)]), 100)
(Dict("001" => 100), 542)

```
"""
function run_job(
    qpu::UnionAnyonQPU,
    circuit::QuantumCircuit,
    shot_count::Integer,
)::Tuple{Dict{String,Int},Int}

    # ensure only valid circuits are sent to the host
    transpiler = SequentialTranspiler([
        CircuitContainsAReadoutTranspiler(),
        ReadoutsDoNotConflictTranspiler(),
        ReadoutsAreFinalInstructionsTranspiler(),
        UnsupportedGatesTranspiler(),
    ])

    # throws error if circuit is invalid
    transpile(transpiler, circuit)

    return submit_with_retries(submit_and_fetch_result, circuit, shot_count, qpu)
end

function submit_with_retries(f::Function, args...)::Tuple{Dict{String,Int},Int}
    attempts = 3

    while attempts > 0
        status, histogram, qpu_time = f(args...)

        status_type = get_status_type(status)

        if status_type == failed_status
            attempts -= 1
            if attempts == 0
                throw(
                    ErrorException(
                        "job has failed with the following message: $(get_status_message(status))",
                    ),
                )
            end
        elseif status_type == cancelled_status
            throw(ErrorException("job was cancelled"))
        else
            @assert status_type == succeeded_status (
                "Server returned an unrecognized status type: $status_type"
            )
            return histogram, qpu_time
        end
    end
end

function submit_and_fetch_result(
    circuit::QuantumCircuit,
    shot_count::Int,
    qpu::UnionAnyonQPU,
)::Tuple{Status,Dict{String,Int},Int}

    machineMetadata = get_metadata(qpu)
    @assert machineMetadata["status"] == "online" "cannot submit jobs to: $(get_machine_name(qpu)); current status is : \"$(machineMetadata["status"])\""

    client = get_client(qpu)

    jobID =
        submit_job(client, circuit, shot_count, get_project_id(qpu), get_machine_name(qpu))

    status, histogram, qpu_time =
        poll_for_results(client, jobID, qpu.status_request_throttle)

    status_type = get_status_type(status)

    if status_type == failed_status
        throw(ErrorException(get_status_message(status)))
    elseif status_type == cancelled_status
        throw(ErrorException(cancelled_status))
    else
        @assert status_type == succeeded_status (
            "Server returned an unrecognized status type: $status_type"
        )
        return status, histogram, qpu_time
    end
end

# 100ms between queries to host by default
const default_status_request_throttle = (seconds = 0.1) -> sleep(seconds)

function poll_for_results(
    client::Client,
    jobID::String,
    request_throttle::Function,
)::Tuple{Status,Dict{String,Int},Int}
    (status, histogram, qpu_time) = get_status(client, jobID)
    while get_status_type(status) in [queued_status, running_status]
        request_throttle()
        (status, histogram, qpu_time) = get_status(client, jobID)
    end

    return status, histogram, qpu_time
end

"""
    get_transpiler(qpu::AbstractQPU)::Transpiler

Returns the transpiler associated with this QPU.

# Example

```jldoctest  
julia> qpu = AnyonYukonQPU(client, "project_id");

julia> get_transpiler(qpu)
SequentialTranspiler(Transpiler[CircuitContainsAReadoutTranspiler(), ReadoutsDoNotConflictTranspiler(), UnsupportedGatesTranspiler(), DecomposeSingleTargetSingleControlGatesTranspiler(), CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), CastRootZZToZ90AndCZGateTranspiler(), SwapQubitsForAdjacencyTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), CastSwapToCZGateTranspiler()  …  SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), ReadoutsAreFinalInstructionsTranspiler(), RejectNonNativeInstructionsTranspiler(LineConnectivity{6}
1──2──3──4──5──6
, DataType[Snowflurry.Identity, Snowflurry.PhaseShift, Snowflurry.Pi8, Snowflurry.Pi8Dagger, Snowflurry.SigmaX, Snowflurry.SigmaY, Snowflurry.SigmaZ, Snowflurry.X90, Snowflurry.XM90, Snowflurry.Y90, Snowflurry.YM90, Snowflurry.Z90, Snowflurry.ZM90, Snowflurry.ControlZ]), RejectGatesOnExcludedPositionsTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), RejectGatesOnExcludedConnectionsTranspiler(LineConnectivity{6}
1──2──3──4──5──6
)])
```
"""
get_transpiler(qpu::UnionAnyonQPU; atol = 1e-6)::Transpiler =
    get_anyon_transpiler(atol = atol, connectivity = get_connectivity(qpu))

function get_anyon_transpiler(;
    atol = 1e-6,
    connectivity = get_connectivity(qpu),
)::Transpiler
    return SequentialTranspiler([
        CircuitContainsAReadoutTranspiler(),
        ReadoutsDoNotConflictTranspiler(),
        UnsupportedGatesTranspiler(),
        DecomposeSingleTargetSingleControlGatesTranspiler(),
        CastToffoliToCXGateTranspiler(),
        CastCXToCZGateTranspiler(),
        CastISwapToCZGateTranspiler(),
        CastRootZZToZ90AndCZGateTranspiler(),
        SwapQubitsForAdjacencyTranspiler(connectivity),
        CastSwapToCZGateTranspiler(),
        CompressSingleQubitGatesTranspiler(),
        SimplifyTrivialGatesTranspiler(atol),
        CastUniversalToRzRxRzTranspiler(),
        SimplifyRxGatesTranspiler(atol),
        CastRxToRzAndHalfRotationXTranspiler(),
        CompressRzGatesTranspiler(),
        SimplifyRzGatesTranspiler(atol),
        ReadoutsAreFinalInstructionsTranspiler(),
        RejectNonNativeInstructionsTranspiler(connectivity),
        RejectGatesOnExcludedPositionsTranspiler(connectivity),
        RejectGatesOnExcludedConnectionsTranspiler(connectivity),
    ])
end
