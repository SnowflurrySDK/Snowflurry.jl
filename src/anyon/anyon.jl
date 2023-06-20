using Snowflurry

abstract type AbstractConnectivity end

struct LineConnectivity <:AbstractConnectivity 
    dimension   ::Int
end

struct LatticeConnectivity <:AbstractConnectivity 
    dimension   ::Tuple{Int,Int} # (nrows,ncols)
end

get_connectivity_label(connectivity::AbstractConnectivity) =
    throw(NotImplementedError(:get_connectivity_label,connectivity))

const line_connectivity_label = "linear"
const lattice_connectivity_label = "2D-lattice"

get_connectivity_label(::LineConnectivity) = line_connectivity_label
get_connectivity_label(::LatticeConnectivity) = lattice_connectivity_label

get_num_qubits(conn::AbstractConnectivity) = *(conn.dimension...)

function print_connectivity(connectivity::LineConnectivity,io::IO=stdout)
    dim = connectivity.dimension

    diagram = [string(n) * "──" for n in 1:dim-1]
    push!(diagram,string(dim))

    output_str=*(diagram...)

    println(io,output_str)
end

function print_connectivity(connectivity::LatticeConnectivity, io::IO = stdout)
    dims = connectivity.dimension

    qubit_count = get_num_qubits(connectivity)

    max_qubit_num_length = length(string(qubit_count))

    nrows = dims[1]
    ncols = dims[2]

    # create string template for ncols: 
    # e.g.: ""%s──%s──%s"" for 3 columns
    line_segments = ["%s──" for _ in 1:ncols-1]
    push!(line_segments, "%s")
    str_template = *(line_segments...)

    # create float specifier of correct precision: 
    # e.g.: "%2.f ──%2.f ──%2.f " for 3 columns, precision=2
    precisionStr = string(" %", max_qubit_num_length, ".f ")
    precisionArray = [precisionStr for _ in 1:ncols]
    str_template_float = Snowflake.formatter(str_template, precisionArray...)
    
    #vertical lines
    right_padding = string([" " for _ in 1:div(max_qubit_num_length+1, 2)]...)
    left_padding =  string([" " for _ in 1:div(max_qubit_num_length+2, 2)]...)

    padded_vertical_symbol = left_padding * "|" * right_padding
    vertical_lines = Snowflake.formatter(
        replace(str_template, "──" => "  "),
        [padded_vertical_symbol for _ in 1:ncols]...
    )

    for irow in 1:nrows
        #insert qubit numbers into str_template_float
        qubit_numbers_in_row = [v + (irow-1)*ncols for v in  1:ncols]
        line_printout = Snowflake.formatter(str_template_float, qubit_numbers_in_row...)
        println(io, line_printout)
        if irow < nrows
            println(io, vertical_lines)
        end
    end
end

print_connectivity(connectivity::AbstractConnectivity,io::IO=stdout) =
    throw(NotImplementedError(:print_connectivity,connectivity))

abstract type AbstractAnyonQPU <: AbstractQPU end

"""
    AnyonYukonQPU

A data structure to represent a Anyon System's QPU.  
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
struct AnyonYukonQPU <: AbstractAnyonQPU
    client                  ::Client
    status_request_throttle ::Function
    connectivity            ::AbstractConnectivity

    AnyonYukonQPU(client::Client; status_request_throttle=default_status_request_throttle) = new(client, status_request_throttle,LineConnectivity(6))
    AnyonYukonQPU(; host::String, user::String, access_token::String, status_request_throttle=default_status_request_throttle) = new(Client(host=host, user=user, access_token=access_token), status_request_throttle,LineConnectivity(6))
end


get_metadata(qpu::AnyonYukonQPU) = Dict{String,Union{String,Int}}(
    "manufacturer"  =>"Anyon Systems Inc.",
    "generation"    =>"Yukon",
    "serial_number" =>"ANYK202201",
    "qubit_count"   =>get_num_qubits(qpu.connectivity),
    "connectivity_type"  =>get_connectivity_label(qpu.connectivity)
)

struct AnyonMonarqQPU <: AbstractAnyonQPU
    client                  ::Client
    status_request_throttle ::Function
    connectivity            ::AbstractConnectivity

    AnyonMonarqQPU(client::Client; status_request_throttle=default_status_request_throttle) = new(client, status_request_throttle,LatticeConnectivity((3,4)))
    AnyonMonarqQPU(; host::String, user::String, access_token::String, status_request_throttle=default_status_request_throttle) = new(Client(host=host, user=user, access_token=access_token), status_request_throttle,LatticeConnectivity((3,4)))
end

get_metadata(qpu::AnyonMonarqQPU) = Dict{String,Union{String,Int}}(
    "manufacturer"  =>"Anyon Systems Inc.",
    "generation"    =>"MonarQ",
    "serial_number" =>"ANYK202301",
    "qubit_count"   =>get_num_qubits(qpu.connectivity),
    "connectivity_type"  =>get_connectivity_label(qpu.connectivity)
)

get_client(qpu_service::AbstractAnyonQPU)=qpu_service.client

get_num_qubits(qpu::AbstractAnyonQPU)=get_metadata(qpu)["qubit_count"]

print_connectivity(qpu::AbstractAnyonQPU,io::IO=stdout)=print_connectivity(qpu.connectivity,io)

function Base.show(io::IO, qpu::AbstractAnyonQPU)
    metadata=get_metadata(qpu)

    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer:  $(metadata["manufacturer"])")
    println(io, "   generation:    $(metadata["generation"])")
    println(io, "   serial_number: $(metadata["serial_number"])")
    println(io, "   qubit_count:   $(metadata["qubit_count"])")
    println(io, "   connectivity_type:  $(metadata["connectivity_type"])")
end


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

get_qubits_distance(target_1::Int, target_2::Int, ::LineConnectivity)::Int = 
    abs(target_1 - target_2)

function get_qubits_distance(target_1::Int, target_2::Int, connectivity::Snowflake.LatticeConnectivity)::Int
    dims = connectivity.dimension

    ncols = dims[2]

    target_1_row = div(target_1 - 1, ncols) + 1
    target_1_col = (target_1 - 1) % ncols + 1

    target_2_row = div(target_2 - 1, ncols) + 1
    target_2_col = (target_2 - 1) % ncols + 1

    # Manhattan distance
    return abs(target_1_row - target_2_row)+abs(target_1_col - target_2_col)
end

function is_native_gate(qpu::AbstractAnyonQPU,gate::AbstractGate)::Bool
    if is_gate_type(gate, ControlZ)
        # on ControlZ gates are native only if targets are adjacent
            
        targets=get_connected_qubits(gate)

        return (get_qubits_distance(targets[1],targets[2],qpu.connectivity)==1)        
    end
        
    return (get_gate_type(gate) in set_of_native_gates)
end

function is_native_circuit(qpu::AbstractAnyonQPU,circuit::QuantumCircuit)::Tuple{Bool,String}
    qubit_count_circuit=get_num_qubits(circuit)
    qubit_count_qpu    =get_num_qubits(qpu)
    if qubit_count_circuit>qubit_count_qpu 
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

julia> transpile_and_run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function transpile_and_run_job(
    qpu::AnyonYukonQPU,
    circuit::QuantumCircuit,
    shot_count::Integer;
    transpiler::Transpiler=get_transpiler(qpu)
    )::Dict{String,Int}

    
    transpiled_circuit=transpile(transpiler,circuit)

    (passed,message)=is_native_circuit(qpu,transpiled_circuit)

    if !passed
        throw(DomainError(qpu, message))
    end

    return run_job(qpu,transpiled_circuit,shot_count)
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

julia> run_job(qpu,QuantumCircuit(qubit_count=3,gates=[sigma_x(3),control_z(2,1)]) ,100)
Dict{String, Int64} with 1 entry:
  "001" => 100

```
"""
function run_job(
    qpu::AnyonYukonQPU,
    circuit::QuantumCircuit,
    shot_count::Integer
    )::Dict{String,Int}
    
    client=get_client(qpu)

    circuitID=submit_circuit(client,circuit,shot_count)

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
    get_transpiler(qpu::AnyonYukonQPU)::Transpiler

Returns the transpiler associated with this QPU.

# Example

```jldoctest  
julia> qpu=AnyonYukonQPU(client);

julia> get_transpiler(qpu)
SequentialTranspiler(Transpiler[CastToffoliToCXGateTranspiler(), CastCXToCZGateTranspiler(), CastISwapToCZGateTranspiler(), SwapQubitsForLineConnectivityTranspiler(), CastSwapToCZGateTranspiler(), CompressSingleQubitGatesTranspiler(), SimplifyTrivialGatesTranspiler(1.0e-6), CastUniversalToRzRxRzTranspiler(), SimplifyRxGatesTranspiler(1.0e-6), CastRxToRzAndHalfRotationXTranspiler(), CompressRzGatesTranspiler(), SimplifyRzGatesTranspiler(1.0e-6), UnsupportedGatesTranspiler()])

```
"""
function get_transpiler(::AnyonYukonQPU;atol=1e-6)::Transpiler
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
        UnsupportedGatesTranspiler(),
    ])
end
