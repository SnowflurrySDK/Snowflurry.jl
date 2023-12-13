using Snowflurry

"""
    AnyonYukonQPU

A data structure to represent an Anyon System's Yukon generation QPU.  
# Fields
- `client                  ::Client` -- Client to the QPU server.
- `status_request_throttle ::Function` -- Used to rate-limit job status requests.


# Example
```jldoctest
julia>  qpu = AnyonYukonQPU(host="example.anyonsys.com",user="test_user",access_token="not_a_real_access_token")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6 
   connectivity_type:  linear
```
"""
struct AnyonYukonQPU <: AbstractQPU
    client::Client
    status_request_throttle::Function
    connectivity::LineConnectivity

    AnyonYukonQPU(
        client::Client;
        status_request_throttle = default_status_request_throttle,
    ) = new(client, status_request_throttle, LineConnectivity(6))
    AnyonYukonQPU(;
        host::String,
        user::String,
        access_token::String,
        status_request_throttle = default_status_request_throttle,
    ) = new(
        Client(host = host, user = user, access_token = access_token),
        status_request_throttle,
        LineConnectivity(6),
    )
end


get_metadata(qpu::AnyonYukonQPU) = Dict{String,Union{String,Int}}(
    "manufacturer" => "Anyon Systems Inc.",
    "generation" => "Yukon",
    "serial_number" => "ANYK202201",
    "qubit_count" => get_num_qubits(qpu.connectivity),
    "connectivity_type" => get_connectivity_label(qpu.connectivity),
)

"""
    AnyonYamaskaQPU

A data structure to represent an Anyon System's Yamaska generation QPU.  
# Fields
- `client                  ::Client` -- Client to the QPU server.
- `status_request_throttle ::Function` -- Used to rate-limit job status requests.


# Example
```jldoctest
julia>  qpu = AnyonYamaskaQPU(host="example.anyonsys.com",user="test_user",access_token="not_a_real_access_token")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yamaska
   serial_number: ANYK202301
   qubit_count:   12 
   connectivity_type:  2D-lattice
```
"""
struct AnyonYamaskaQPU <: AbstractQPU
    client::Client
    status_request_throttle::Function
    connectivity::LatticeConnectivity

    AnyonYamaskaQPU(
        client::Client;
        status_request_throttle = default_status_request_throttle,
    ) = new(client, status_request_throttle, LatticeConnectivity(4, 3))
    AnyonYamaskaQPU(;
        host::String,
        user::String,
        access_token::String,
        status_request_throttle = default_status_request_throttle,
    ) = new(
        Client(host = host, user = user, access_token = access_token),
        status_request_throttle,
        LatticeConnectivity(4, 3),
    )
end

get_metadata(qpu::AnyonYamaskaQPU) = Dict{String,Union{String,Int}}(
    "manufacturer" => "Anyon Systems Inc.",
    "generation" => "Yamaska",
    "serial_number" => "ANYK202301",
    "qubit_count" => get_num_qubits(qpu.connectivity),
    "connectivity_type" => get_connectivity_label(qpu.connectivity),
)

get_client(qpu_service::AbstractQPU) = qpu_service.client

UnionAnyonQPU = Union{AnyonYukonQPU,AnyonYamaskaQPU}

get_num_qubits(qpu::UnionAnyonQPU) = get_num_qubits(qpu.connectivity)

get_connectivity(qpu::UnionAnyonQPU) = qpu.connectivity

print_connectivity(qpu::AbstractQPU, io::IO = stdout) =
    print_connectivity(get_connectivity(qpu), Int[], io)

function Base.show(io::IO, qpu::UnionAnyonQPU)
    metadata = get_metadata(qpu)

    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(metadata["manufacturer"])")
    println(io, "   generation:    $(metadata["generation"])")
    println(io, "   serial_number: $(metadata["serial_number"])")
    println(io, "   qubit_count:   $(metadata["qubit_count"])")
    println(io, "   connectivity_type:  $(metadata["connectivity_type"])")
end


set_of_native_gates = [
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

julia> connectivity = LatticeConnectivity(6,4)
LatticeConnectivity{6,4}
              1 ──  2 
              |     | 
        3 ──  4 ──  5 ──  6 
        |     |     |     | 
  7 ──  8 ──  9 ── 10 ── 11 ── 12 
        |     |     |     |     | 
       13 ── 14 ── 15 ── 16 ── 17 ── 18 
              |     |     |     | 
             19 ── 20 ── 21 ── 22 
                    |     | 
                   23 ── 24 


julia> get_qubits_distance(3, 24, connectivity)
7

```

"""
get_qubits_distance(target_1::Int, target_2::Int, ::LineConnectivity)::Int =
    abs(target_1 - target_2)

function get_qubits_distance(
    target_1::Int,
    target_2::Int,
    connectivity::LatticeConnectivity,
)::Int
    # Manhattan distance
    return maximum([0, length(path_search(target_1, target_2, connectivity)) - 1])
end

function is_native_instruction(qpu::UnionAnyonQPU, gate::Gate)::Bool
    if gate isa Gate{ControlZ}
        # on ControlZ gates are native only if targets are adjacent

        targets = get_connected_qubits(gate)

        return (get_qubits_distance(targets[1], targets[2], get_connectivity(qpu)) == 1)
    end

    return (typeof(get_gate_symbol(gate)) in set_of_native_gates)
end

is_native_instruction(qpu::UnionAnyonQPU, readout::Readout)::Bool = true

function is_native_circuit(qpu::UnionAnyonQPU, circuit::QuantumCircuit)::Tuple{Bool,String}
    qubit_count_circuit = get_num_qubits(circuit)
    qubit_count_qpu = get_num_qubits(qpu)
    if qubit_count_circuit > qubit_count_qpu
        return (
            false,
            "Circuit qubit count $qubit_count_circuit exceeds $(typeof(qpu)) qubit count: $qubit_count_qpu",
        )
    end

    for instr in get_circuit_instructions(circuit)
        if !is_native_instruction(qpu, instr)
            return (
                false,
                "Instruction type $(typeof(instr)) with targets $(get_connected_qubits(instr)) is not native on $(typeof(qpu))",
            )
        end
    end

    return (true, "")
end

"""
    transpile_and_run_job(qpu::AnyonYukonQPU, circuit::QuantumCircuit,shot_count::Integer;transpiler::Transpiler=get_transpiler(qpu))

This method first transpiles the input circuit using either the default
transpiler, or any other transpiler passed as a key-word argument.
The transpiled circuit is then run on the AnyonYukonQPU, repeatedly for the
specified number of repetitions (shot_count).

Returns the histogram of the completed circuit calculations, or an error
message.

# Example

```jldoctest  
julia> qpu=AnyonYukonQPU(client_anyon);

julia> transpile_and_run_job(qpu,QuantumCircuit(qubit_count=3,instructions=[sigma_x(3),control_z(2,1), readout(3, 3)]) ,100)
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

    (passed, message) = is_native_circuit(qpu, transpiled_circuit)

    if !passed
        throw(DomainError(qpu, message))
    end

    return run_job(qpu, transpiled_circuit, shot_count)
end

"""
    run_job(qpu::AnyonYukonQPU, circuit::QuantumCircuit, shot_count::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified
number of repetitions (shot_count).

Returns the histogram of the completed circuit calculations, or an error
message.

# Example

```jldoctest  
julia> qpu=AnyonYukonQPU(client);

julia> run_job(qpu,QuantumCircuit(qubit_count=3,instructions=[sigma_x(3),control_z(2,1)]) ,100)
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

    circuitID = submit_circuit(client, circuit, shot_count)

    status = poll_for_status(client, circuitID, qpu.status_request_throttle)

    status_type = get_status_type(status)

    if status_type == failed_status
        throw(ErrorException(get_status_message(status)))
    elseif status_type == cancelled_status
        throw(ErrorException(cancelled_status))
    else
        @assert status_type == succeeded_status (
            "Server returned an unrecognized status type: $status_type"
        )
        return get_result(client, circuitID)
    end
end

# 100ms between queries to host by default
const default_status_request_throttle = (seconds = 0.1) -> sleep(seconds)

function poll_for_status(
    client::Client,
    circuitID::String,
    request_throttle::Function,
)::Status
    status = get_status(client, circuitID)
    while get_status_type(status) in [queued_status, running_status]
        request_throttle()
        status = get_status(client, circuitID)
    end

    return status
end

"""
    get_transpiler(qpu::AbstractQPU)::Transpiler

Returns the transpiler associated with this QPU.

# Example

```jldoctest  
julia> qpu=AnyonYukonQPU(client);

julia> get_transpiler(qpu)
SequentialTranspiler(Transpiler[CircuitContainsAReadoutTranspiler(), CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), SwapQubitsForAdjacencyTranspiler(LineConnectivity{6}
1──2──3──4──5──6
), CastSwapToCZGateTranspiler(), CompressSingleQubitGatesTranspiler(), SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), ReadoutsAreFinalInstructionsTranspiler(), UnsupportedGatesTranspiler()])
```
"""
function get_transpiler(qpu::UnionAnyonQPU; atol = 1e-6)::Transpiler
    return SequentialTranspiler([
        CircuitContainsAReadoutTranspiler(),
        CastToffoliToCXGateTranspiler(),
        CastCXToCZGateTranspiler(),
        CastISwapToCZGateTranspiler(),
        SwapQubitsForAdjacencyTranspiler(get_connectivity(qpu)),
        CastSwapToCZGateTranspiler(),
        CompressSingleQubitGatesTranspiler(),
        SimplifyTrivialGatesTranspiler(atol),
        CastUniversalToRzRxRzTranspiler(),
        SimplifyRxGatesTranspiler(atol),
        CastRxToRzAndHalfRotationXTranspiler(),
        CompressRzGatesTranspiler(),
        SimplifyRzGatesTranspiler(atol),
        ReadoutsAreFinalInstructionsTranspiler(),
        UnsupportedGatesTranspiler(),
    ])
end
