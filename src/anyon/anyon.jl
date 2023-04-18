using Snowflake

"""
    AnyonQPU

A data structure to represent a Anyon System's QPU.  
# Fields
- `client       ::Client` -- Client to the QPU server.


# Example
```jldoctest
julia> c = Client(host="http://example.anyonsys.com",user="test_user",access_token="not_a_real_access_token");
  
julia> qpu=AnyonQPU(c)
Quantum Processing Unit:
   manufacturer:  Anyon Systems Inc.
   generation:    Yukon 
   serial_number: ANYK202201 


```
"""
struct AnyonQPU <: AbstractQPU
    client        ::Client
end

get_metadata(qpu::AnyonQPU) = Dict{String,String}(
    "manufacturer"  =>"Anyon Systems Inc.",
    "generation"    =>"Yukon",
    "serial_number" =>"ANYK202201",
)


get_client(qpu_service::AnyonQPU)=qpu_service.client

function Base.show(io::IO, qpu::AnyonQPU)
    metadata=get_metadata(qpu)

    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(metadata["manufacturer"])")
    println(io, "   generation:    $(metadata["generation"])")
    println(io, "   serial_number: $(metadata["serial_number"])")
end

"""
    run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)

Run a circuit computation on a `QPU` service, repeatedly for the specified 
number of repetitions (num_repetitions). Returns the histogram of the 
completed circuit calculations, or an error message.

# Example

```jldoctest  
julia> qpu=AnyonQPU(client);

julia> run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(qpu::AnyonQPU, circuit::QuantumCircuit,num_repetitions::Integer)::Dict{String,Int}
    
    client=get_client(qpu)

    circuitID=submit_circuit(client,circuit,num_repetitions)

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
SequentialTranspiler(Transpiler[CastToffoliToCXGateTranspiler(), CastSwapToCZGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), Snowflake.CompressSingleQubitGatesTranspiler(), Snowflake.CastToPhaseShiftAndHalfRotationX()])

```
"""
function get_transpiler(::AnyonQPU)::Transpiler
    return SequentialTranspiler([
        Snowflake.CastToffoliToCXGateTranspiler(),
        Snowflake.CastSwapToCZGateTranspiler(),
        Snowflake.CastCXToCZGateTranspiler(),
        Snowflake.CastISwapToCZGateTranspiler(),
        Snowflake.CompressSingleQubitGatesTranspiler(),
        Snowflake.CastToPhaseShiftAndHalfRotationX(),
        Snowflake.PlaceOperationsOnLine(),
    ])
end
