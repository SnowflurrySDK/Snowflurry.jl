using Snowflake

"""
    AnyonQPU

A data structure to represent a Anyon System's QPU.  
# Fields
- `client       ::Client` -- Client to the QPU server.


# Example
```jldoctest
julia>  qpu = AnyonQPU(host="example.anyonsys.com",user="test_user",access_token="not_a_real_access_token")
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon
   serial_number: ANYK202201
   qubit_count:   6 

```
"""
struct AnyonQPU <: AbstractQPU
    client        ::Client

    AnyonQPU(client::Client) = new(client)
    AnyonQPU(; host::String, user::String, access_token::String) = new(Client(host=host, user=user, access_token=access_token))
end

get_metadata(::AnyonQPU) = Dict{String,Union{String,Int}}(
    "manufacturer"  =>"Anyon Systems Inc.",
    "generation"    =>"Yukon",
    "serial_number" =>"ANYK202201",
    "qubit_count"   =>6,
)

get_client(qpu_service::AnyonQPU)=qpu_service.client

get_num_qubits(qpu::AnyonQPU)=get_metadata(qpu)["qubit_count"]

function Base.show(io::IO, qpu::AnyonQPU)
    metadata=get_metadata(qpu)

    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(metadata["manufacturer"])")
    println(io, "   generation:    $(metadata["generation"])")
    println(io, "   serial_number: $(metadata["serial_number"])")
    println(io, "   qubit_count:   $(metadata["qubit_count"])")
end

get_native_gate_types(::AnyonQPU)=[
    Snowflake.PhaseShift,
    Snowflake.Pi8,
    Snowflake.Pi8Dagger,
    Snowflake.SigmaX,
    Snowflake.SigmaY,
    Snowflake.SigmaZ,
    Snowflake.X90,
    Snowflake.XM90,
    Snowflake.Y90,
    Snowflake.YM90,
    Snowflake.Z90,
    Snowflake.ZM90,
    Snowflake.ControlZ,
    Snowflake.Swap,
]

"""
    run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified 
number of repetitions (num_repetitions). Returns the histogram of the 
completed circuit calculations, or an error message.

# Example

```jldoctest  
julia> qpu=AnyonQPU(client_anyon);

julia> run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(
    qpu::AnyonQPU, 
    circuit::QuantumCircuit,
    num_repetitions::Integer;
    transpiler::Transpiler=get_transpiler(qpu)
    )::Dict{String,Int}
    
    qubit_count_circuit=get_num_qubits(circuit)
    qubit_count_qpu    =get_num_qubits(qpu)
    if qubit_count_circuit>=qubit_count_qpu 
        throw(
            DomainError(
                qpu,
                "Circuit qubit count $qubit_count_circuit exceeds $(typeof(qpu)) qubit count: $qubit_count_qpu"
            )
        )
    end

    set_of_native_gates=get_native_gate_types(qpu)

    transpiled_circuit=transpile(transpiler,circuit)

    for gate in get_circuit_gates(transpiled_circuit)
        if !(typeof(gate) in set_of_native_gates)
            throw(
                DomainError(
                    qpu,
                    "Gate type $(typeof(gate)) is not native on $(typeof(qpu))"
                )
            )
        end
    end

    client=get_client(qpu)

    circuitID=submit_circuit(client,transpiled_circuit,num_repetitions)

    status=get_status(client,circuitID;)
 
    ref_time_query=Base.time_ns()
    query_delay=100/1e6 #100 ms between queries to host

    while true        
        current_time=Base.time_ns()

        if (current_time-ref_time_query)>query_delay
            status=get_status(client,circuitID;)
            ref_time_query=current_time
        end
           
        if !(get_status_type(status) in [queued_status,running_status])
            break
        end

    end
    
    status_type=get_status_type(status)

    if status_type == failed_status       
        return Dict("error_msg"=>get_status_message(status))

    elseif status_type == cancelled_status       
        return Dict("error_msg"=>cancelled_status)
    
    else 
        @assert status_type == succeeded_status ("Server returned an unrecognized status type: $status_type")
        return get_result(client,circuitID)
    end
end

"""
    get_transpiler(qpu::AnyonQPU)::Transpiler

Returns the transpiler associated with this QPU.

# Example

```jldoctest  
julia> qpu=AnyonQPU(client);

julia> get_transpiler(qpu)
SequentialTranspiler(Transpiler[CastToffoliToCXGateTranspiler(), CastSwapToCZGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), CompressSingleQubitGatesTranspiler(), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), SwapQubitsForLineConnectivityTranspiler()])

```
"""
function get_transpiler(::AnyonQPU;atol=1e-6)::Transpiler
    return SequentialTranspiler([
        CastToffoliToCXGateTranspiler(),
        CastSwapToCZGateTranspiler(),
        CastCXToCZGateTranspiler(),
        CastISwapToCZGateTranspiler(),
        CompressSingleQubitGatesTranspiler(),
        CastUniversalToRzRxRzTranspiler(),
        SimplifyRxGatesTranspiler(),
        CastRxToRzAndHalfRotationXTranspiler(),
        CompressRzGatesTranspiler(),
        SimplifyRzGatesTranspiler(),
        SwapQubitsForLineConnectivityTranspiler(),
    ])
end
