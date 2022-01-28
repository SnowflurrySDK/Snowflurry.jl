"""
Represnts a Quantum Processing Unit (QPU).
**Fields**
- `manufacturer: String` -- qpu manufacturer (e.g. "anyon")
- `generation: String` -- qpu generation (e.g. "yukon")
- `serial_number: String` -- qpu serial_number (e.g. "ANYK202201")
- `host: String` -- the remote host url address to send the jobs to
- `physical_qubit_count: UInt32` -- number of physical qubits on the machine
- `native_gates: Vector{String}` -- the vector of native gates symbols supported by the qpu architecture
```
"""
Base.@kwdef struct QPU
    manufacturer::String
    generation::String
    serial_number::String
    host::String
    qubit_count::Int
    native_gates::Vector{String}
end

function Base.show(io::IO, qpu::QPU)
    println(io, "Quantum Processing Unit:")
    println(io, "   manufacturer: $(qpu.manufacturer)")
    println(io, "   generation: $(qpu.generation) ")
    println(io, "   serial_number: $(qpu.serial_number) ")
    println(io, "   host: $(qpu.host) ")
    println(io, "   qubit_count: $(qpu.qubit_count) ")
    println(io, "   native_gates: $(qpu.native_gates) ")
end

"""
    create_virtual_qpu(qubit_count::UInt32, native_gates::Array{String}, host = "localhost:5600")

Creates a virtual quantum processor with `qubit_count` number of qubits and `native_gates`. 
The return value is QPU stucture (see  [`QPU`](@ref)).

# Examples
```jldoctest
julia> qpu = create_virtual_qpu(3,["x" "ha"])
Quantum Processing Unit:
   manufacturer: none
   generation: none 
   serial_number: 00 
   host: localhost:5600 
   qubit_count: 3 
   native_gates: ["x" "ha"] 
```
"""
function create_virtual_qpu(qubit_count::Int, native_gates::Vector{String}, host = "localhost:5600")
    return QPU(
        manufacturer = "none",
        generation = "none",
        serial_number = "00",
        host = host,
        native_gates = native_gates,
        qubit_count = qubit_count,
    )
end
