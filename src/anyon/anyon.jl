using Snowflurry

const AnyonYukonConnectivity = LineConnectivity(6)
const AnyonYamaskaConnectivity = LatticeConnectivity([1, 3, 3, 3, 2])
const AnyonYamaska6Connectivity = LineConnectivity(6)

const Metadata = Dict{String,Union{String,Int,Vector{Int}}}

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
julia>  qpu = AnyonYukonQPU(host = "example.anyonsys.com", user = "test_user", access_token = "not_a_real_access_token", project_id = "test-project", realm = "test-realm")
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
        project_id::String;
        status_request_throttle = default_status_request_throttle,
    )
        if project_id == ""
            throw(ArgumentError(error_msg_empty_project_id))
        end
        new(client, status_request_throttle, AnyonYukonConnectivity, project_id, Metadata())
    end

    function AnyonYukonQPU(;
        host::String,
        user::String,
        access_token::String,
        project_id::String,
        realm::String = "",
        status_request_throttle = default_status_request_throttle,
    )
        if project_id == ""
            throw(ArgumentError(error_msg_empty_project_id))
        end
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
consisting of 12 qubits in a 2D lattice arrangement (see [`LatticeConnectivity`](@ref)).
# Fields
- `client                  ::Client` -- Client to the QPU server.
- `status_request_throttle ::Function` -- Used to rate-limit job status requests.
- `project_id              ::String` -- Used to identify which project the jobs sent to this QPU belong to.
- `realm                   ::String` -- Optional: used to identify to which realm on the host server requests are sent to.

# Example
```jldoctest
julia>  qpu = AnyonYamaskaQPU(host = "example.anyonsys.com", user = "test_user", access_token = "not_a_real_access_token", project_id = "test-project", realm = "test_realm")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yamaska
   serial_number: ANYK202301
   project_id:    test-project
   qubit_count:   12 
   connectivity_type:  2D-lattice
   realm:         test_realm
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
        project_id::String;
        status_request_throttle = default_status_request_throttle,
    )
        if project_id == ""
            throw(ArgumentError(error_msg_empty_project_id))
        end
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
        project_id::String,
        realm::String = "",
        status_request_throttle = default_status_request_throttle,
    )
        if project_id == ""
            throw(ArgumentError(error_msg_empty_project_id))
        end

        new(
            Client(host = host, user = user, access_token = access_token, realm = realm),
            status_request_throttle,
            AnyonYamaskaConnectivity,
            project_id,
            Metadata(),
        )
    end
end

"""
    AnyonYamaska6QPU <: AbstractQPU

A data structure to represent an Anyon System's Yamaska generation QPU,
consisting of 12 qubits in a 2D lattice arrangement but configured to act like
a 6 qubit device with linear connectivity.
# Fields
- `client                  ::Client` -- Client to the QPU server.
- `status_request_throttle ::Function` -- Used to rate-limit job status requests.
- `project_id              ::String` -- Used to identify which project the jobs sent to this QPU belong to.
- `realm                   ::String` -- Optional: used to identify to which realm on the host server requests are sent to.

# Example
```jldoctest
julia>  qpu = AnyonYamaska6QPU(host = "example.anyonsys.com", user = "test_user", access_token = "not_a_real_access_token", project_id = "test-project", realm = "test_realm")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yamaska
   serial_number: ANYK202301-6
   project_id:    test-project
   qubit_count:   6
   connectivity_type:  linear
   realm:         test_realm
```
"""
struct AnyonYamaska6QPU <: AbstractQPU
    client::Client
    status_request_throttle::Function
    connectivity::LineConnectivity
    project_id::String
    metadata::Metadata

    function AnyonYamaska6QPU(
        client::Client,
        project_id::String;
        status_request_throttle = default_status_request_throttle,
    )
        if project_id == ""
            throw(ArgumentError(error_msg_empty_project_id))
        end
        new(
            client,
            status_request_throttle,
            AnyonYamaska6Connectivity,
            project_id,
            Metadata(),
        )
    end
    function AnyonYamaska6QPU(;
        host::String,
        user::String,
        access_token::String,
        project_id::String,
        realm::String = "",
        status_request_throttle = default_status_request_throttle,
    )
        if project_id == ""
            throw(ArgumentError(error_msg_empty_project_id))
        end

        new(
            Client(host = host, user = user, access_token = access_token, realm = realm),
            status_request_throttle,
            AnyonYamaska6Connectivity,
            project_id,
            Metadata(),
        )
    end
end

UnionAnyonQPU = Union{AnyonYukonQPU,AnyonYamaskaQPU,AnyonYamaska6QPU}

get_client(qpu_service::UnionAnyonQPU) = qpu_service.client

get_project_id(qpu_service::UnionAnyonQPU) = qpu_service.project_id

get_realm(qpu_service::UnionAnyonQPU) = get_realm(qpu_service.client)

get_num_qubits(qpu::UnionAnyonQPU) = get_num_qubits(qpu.connectivity)

function get_connectivity(qpu::UnionAnyonQPU)
    md = get_metadata(qpu)

    if haskey(md, "excluded_positions")
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

function get_metadata(client::Client, qpu::UnionAnyonQPU)::Metadata

    # TODO: the metadata will eventually be fetched from the host server.
    # It is hardcoded for the time being

    generation = "Yukon"
    serial_number = "ANYK202201"
    excluded_positions = Vector{Int}()

    if qpu isa AnyonYamaskaQPU
        generation = "Yamaska"
        serial_number = "ANYK202301"
    elseif qpu isa AnyonYamaska6QPU
        generation = "Yamaska"
        serial_number = "ANYK202301-6"
    end

    output = Metadata(
        "manufacturer" => "Anyon Systems Inc.",
        "generation" => generation,
        "serial_number" => serial_number,
        "project_id" => get_project_id(qpu),
        "qubit_count" => get_num_qubits(qpu.connectivity),
        "connectivity_type" => get_connectivity_label(qpu.connectivity),
    )

    realm = get_realm(qpu)
    if realm != ""
        output["realm"] = realm
    end

    return output
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
              5 ──  1
              |     |
       13 ──  9 ──  6 ──  2
        |     |     |     |
 21 ── 17 ── 14 ── 10 ──  7 ──  3
        |     |     |     |     |
       22 ── 18 ── 15 ── 11 ──  8 ──  4
              |     |     |     |
             23 ── 19 ── 16 ── 12
                    |     |
                   24 ── 20 


julia> get_qubits_distance(3, 24, connectivity)
5

```

"""
function get_qubits_distance(target_1::Int, target_2::Int, c::LineConnectivity)::Real
    for e in c.excluded_positions
        if target_1 ≤ e ≤ target_2
            return Inf
        end
    end

    abs(target_1 - target_2)
end

function get_qubits_distance(
    target_1::Int,
    target_2::Int,
    connectivity::LatticeConnectivity,
)::Real

    path = path_search(target_1, target_2, connectivity)

    if isempty(path)
        return Inf
    end

    # Manhattan distance
    return length(path) - 1
end

const GeometricConnectivity = Union{LineConnectivity,LatticeConnectivity}

function is_native_instruction(gate::Gate, connectivity::GeometricConnectivity)::Bool
    if any(x -> x in connectivity.excluded_positions, get_connected_qubits(gate))
        return false
    end

    if gate isa Gate{ControlZ}
        # on ControlZ gates are native only if targets are adjacent

        targets = get_connected_qubits(gate)

        return (get_qubits_distance(targets[1], targets[2], connectivity) == 1)
    end

    return (typeof(get_gate_symbol(gate)) in set_of_native_gates)
end

is_native_instruction(readout::Readout, connectivity::GeometricConnectivity)::Bool =
    !any(x -> x in connectivity.excluded_positions, get_connected_qubits(readout))

function is_native_circuit(
    qubit_count_qpu::Int,
    circuit::QuantumCircuit,
    connectivity::GeometricConnectivity,
)::Tuple{Bool,String}
    qubit_count_circuit = get_num_qubits(circuit)
    if qubit_count_circuit > qubit_count_qpu
        return (
            false,
            "Circuit qubit count $qubit_count_circuit exceeds $(typeof(connectivity)) qubit count: $qubit_count_qpu",
        )
    end

    for instr in get_circuit_instructions(circuit)
        if !is_native_instruction(instr, connectivity)
            return (
                false,
                "Instruction type $(typeof(instr)) with targets $(get_connected_qubits(instr))" *
                " is not native on connectivity with excluded_positions: $(get_excluded_positions(connectivity))",
            )
        end
    end

    return (true, "")
end

"""
    transpile_and_run_job(qpu::AnyonYukonQPU, circuit::QuantumCircuit, shot_count::Integer; transpiler::Transpiler = get_transpiler(qpu))

This method first transpiles the input circuit using either the default
transpiler, or any other transpiler passed as a key-word argument.
The transpiled circuit is then run on the AnyonYukonQPU, repeatedly for the
specified number of repetitions (shot_count).

Returns the histogram of the completed circuit calculations, or an error
message.

# Example

```jldoctest  
julia> qpu = AnyonYukonQPU(client_anyon, "project_id");

julia> transpile_and_run_job(qpu, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1), readout(3, 3)]), 100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function transpile_and_run_job(
    qpu::UnionAnyonQPU,
    circuit::QuantumCircuit,
    shot_count::Integer;
    transpiler::Transpiler = get_transpiler(qpu),
)::Dict{String,Int}

    transpiled_circuit = transpile(transpiler, circuit)

    return run_job(qpu, transpiled_circuit, shot_count)
end

"""
    run_job(qpu::AnyonYukonQPU, circuit::QuantumCircuit, shot_count::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified
number of repetitions (shot_count).
Returns the histogram of the completed circuit calculations, or an error
message.
If the circuit received in invalid - for instance, it is missing a `Readout` -
it is not sent to the host, and an error is throw.

# Example

```jldoctest  
julia> qpu = AnyonYukonQPU(client, "project_id");

julia> run_job(qpu, QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1), readout(1, 1)]), 100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(
    qpu::UnionAnyonQPU,
    circuit::QuantumCircuit,
    shot_count::Integer,
)::Dict{String,Int}

    client = get_client(qpu)

    # ensure only valid circuits are sent to the host
    transpiler = SequentialTranspiler([
        CircuitContainsAReadoutTranspiler(),
        ReadoutsDoNotConflictTranspiler(),
        ReadoutsAreFinalInstructionsTranspiler(),
        UnsupportedGatesTranspiler(),
    ])

    # throws error if circuit is invalid
    transpile(transpiler, circuit)

    jobID = submit_job(client, circuit, shot_count, get_project_id(qpu))

    status, histogram = poll_for_results(client, jobID, qpu.status_request_throttle)

    status_type = get_status_type(status)

    if status_type == failed_status
        throw(ErrorException(get_status_message(status)))
    elseif status_type == cancelled_status
        throw(ErrorException(cancelled_status))
    else
        @assert status_type == succeeded_status (
            "Server returned an unrecognized status type: $status_type"
        )
        return histogram
    end
end

# 100ms between queries to host by default
const default_status_request_throttle = (seconds = 0.1) -> sleep(seconds)

function poll_for_results(
    client::Client,
    jobID::String,
    request_throttle::Function,
)::Tuple{Status,Dict{String,Int}}
    (status, histogram) = get_status(client, jobID)
    while get_status_type(status) in [queued_status, running_status]
        request_throttle()
        (status, histogram) = get_status(client, jobID)
    end

    return status, histogram
end

"""
    get_transpiler(qpu::AbstractQPU)::Transpiler

Returns the transpiler associated with this QPU.

# Example

```jldoctest  
julia> qpu = AnyonYukonQPU(client, "project_id");

julia> get_transpiler(qpu)
SequentialTranspiler(Transpiler[CircuitContainsAReadoutTranspiler(), ReadoutsDoNotConflictTranspiler(), UnsupportedGatesTranspiler(), DecomposeSingleTargetSingleControlGatesTranspiler(), CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), SwapQubitsForAdjacencyTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), CastSwapToCZGateTranspiler(), CompressSingleQubitGatesTranspiler(), SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), ReadoutsAreFinalInstructionsTranspiler(), RejectNonNativeInstructionsTranspiler(LineConnectivity{6}
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
    ])
end
