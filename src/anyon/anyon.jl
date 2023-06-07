using Snowflake

"""
    AnyonQPU

A data structure to represent a Anyon System's QPU.  
# Fields
- `client                  ::Client` -- Client to the QPU server.
- `status_request_throttle ::Function` -- Used to rate-limit job status requests.


# Example
```jldoctest
julia>  qpu = AnyonQPU(host="example.anyonsys.com",user="test_user",access_token="not_a_real_access_token")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6 
   connectivity_type:  linear
```
"""
struct AnyonQPU <: AbstractQPU
    client                  ::Client
    status_request_throttle ::Function

    AnyonQPU(client::Client; status_request_throttle=default_status_request_throttle) = new(client, status_request_throttle)
    AnyonQPU(; host::String, user::String, access_token::String, status_request_throttle=default_status_request_throttle) = new(Client(host=host, user=user, access_token=access_token), status_request_throttle)
end

const line_connectivity_label="linear"

get_metadata(::AnyonQPU) = Dict{String,Union{String,Int}}(
    "manufacturer"  =>"Anyon Systems Inc.",
    "generation"    =>"Yukon",
    "serial_number" =>"ANYK202201",
    "qubit_count"   =>6,
    "connectivity_type"  =>line_connectivity_label
)

get_client(qpu_service::AnyonQPU)=qpu_service.client

get_num_qubits(qpu::AnyonQPU)=get_metadata(qpu)["qubit_count"]

print_connectivity(qpu::AnyonQPU,io::IO=stdout)=println(io, "1──2──3──4──5──6")

function Base.show(io::IO, qpu::AnyonQPU)
    metadata=get_metadata(qpu)

    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(metadata["manufacturer"])")
    println(io, "   generation:    $(metadata["generation"])")
    println(io, "   serial_number: $(metadata["serial_number"])")
    println(io, "   qubit_count:   $(metadata["qubit_count"])")
    println(io, "   connectivity_type:  $(metadata["connectivity_type"])")
end


function is_native_gate(qpu::AnyonQPU,gate::AbstractGate)::Bool
    
    set_of_native_gates=[
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

    if is_gate_type(gate, ControlZ)
        @assert get_metadata(qpu)["connectivity_type"]==line_connectivity_label (
            "Not implemented for connectivity type: $(get_metadata(qpu)["connectivity_type"])"
        )
            
        targets=get_connected_qubits(gate)

        return (abs(targets[1]-targets[2])==1)        
    end
        
    return (get_gate_type(gate) in set_of_native_gates)
end

function is_native_circuit(qpu::AnyonQPU,circuit::QuantumCircuit)::Tuple{Bool,String}
    qubit_count_circuit=get_num_qubits(circuit)
    qubit_count_qpu    =get_num_qubits(qpu)
    if qubit_count_circuit>=qubit_count_qpu 
        return (
            false,
            "Circuit qubit count $qubit_count_circuit exceeds $(typeof(qpu)) qubit count: $qubit_count_qpu"
            )
    end

    for gate in get_circuit_gates(circuit)
        if !is_native_gate(qpu,gate)
            return (false,
            "Gate type $(get_gate_type(gate)) with targets $(get_connected_qubits(gate)) is not native on $(typeof(qpu))"
            )
        end
    end

    return (true,"")
end

"""
    transpile_and_run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer;transpiler::Transpiler=get_transpiler(qpu))

This method first transpiles the input circuit using either the default
transpiler, or any other transpiler passed as a key-word argument.
The transpiled circuit is then run on the AnyonQPU, repeatedly for the
specified number of repetitions (num_repetitions).

Returns the histogram of the completed circuit calculations, or an error
message.

# Example

```jldoctest  
julia> qpu=AnyonQPU(client_anyon);

julia> transpile_and_run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function transpile_and_run_job(
    qpu::AnyonQPU,
    circuit::QuantumCircuit,
    num_repetitions::Integer;
    transpiler::Transpiler=get_transpiler(qpu)
    )::Dict{String,Int}

    
    transpiled_circuit=transpile(transpiler,circuit)

    (passed,message)=is_native_circuit(qpu,transpiled_circuit)

    if !passed
        throw(DomainError(qpu, message))
    end

    return run_job(qpu,transpiled_circuit,num_repetitions)
end

"""
    run_job(qpu::AnyonQPU, circuit::QuantumCircuit, num_repetitions::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified
number of repetitions (num_repetitions).

Returns the histogram of the completed circuit calculations, or an error
message.

# Example

```jldoctest  
julia> qpu=AnyonQPU(client);

julia> run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(
    qpu::AnyonQPU,
    circuit::QuantumCircuit,
    num_repetitions::Integer
    )::Dict{String,Int}
    
    client=get_client(qpu)

    circuitID=submit_circuit(client,circuit,num_repetitions)

    status=poll_for_status(client,circuitID,qpu.status_request_throttle)
    
    status_type=get_status_type(status)

    if status_type == failed_status
        throw(ErrorException(get_status_message(status)))
    elseif status_type == cancelled_status
        throw(ErrorException(cancelled_status))
    else 
        @assert status_type == succeeded_status (
            "Server returned an unrecognized status type: $status_type"
        )
        return get_result(client,circuitID)
    end
end

# 100ms between queries to host by default
const default_status_request_throttle = (seconds=0.1) -> sleep(seconds)

function poll_for_status(client::Client, circuitID::String, request_throttle::Function)::Status
    status=get_status(client,circuitID)
    while get_status_type(status) in [queued_status,running_status]
        request_throttle()
        status=get_status(client,circuitID)
    end

    return status
end

"""
    get_transpiler(qpu::AnyonQPU)::Transpiler

Returns the transpiler associated with this QPU.

# Example

```jldoctest  
julia> qpu=AnyonQPU(client);

julia> get_transpiler(qpu)
SequentialTranspiler(Transpiler[CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), SwapQubitsForLineConnectivityTranspiler(), CastSwapToCZGateTranspiler(), CompressSingleQubitGatesTranspiler(), SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), CastControlledGatesToNativeTranspiler()])

```
"""
function get_transpiler(::AnyonQPU;atol=1e-6)::Transpiler
    return SequentialTranspiler([
        CastToffoliToCXGateTranspiler(),
        CastCXToCZGateTranspiler(),
        CastISwapToCZGateTranspiler(),
        SwapQubitsForLineConnectivityTranspiler(),
        CastSwapToCZGateTranspiler(),
        CompressSingleQubitGatesTranspiler(),
        SimplifyTrivialGatesTranspiler(),
        CastUniversalToRzRxRzTranspiler(),
        SimplifyRxGatesTranspiler(),
        CastRxToRzAndHalfRotationXTranspiler(),
        CompressRzGatesTranspiler(),
        SimplifyRzGatesTranspiler(),
        CastControlledGatesToNativeTranspiler(),
    ])
end
