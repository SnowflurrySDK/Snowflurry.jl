"""
Represnts a Quantum Processing Unit (QPU).
**Fields**
- `manufacturer:: String` -- qpu manufacturer (e.g. "anyon")
- `generation:: String` -- qpu generation (e.g. "yukon")
- `serial_number:: String` -- qpu serial_number (e.g. "ANYK202201")
- `host:: String` -- the remote host url address to send the jobs to
- `qubit_count:: Int` -- number of physical qubits on the machine
- `connectivity::SparseArrays.SparseMatrixCSC{Int}` -- a matrix describing the connectivity between qubits
- `native_gates:: Vector{String}` -- the vector of native gates symbols supported by the qpu architecture
```
"""
Base.@kwdef struct QPU
    manufacturer::String
    generation::String
    serial_number::String
    host::String
    qubit_count::Int
    connectivity::SparseArrays.SparseMatrixCSC{Int}
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
    println(io, "   connectivity = $(qpu.connectivity)")
end

"""
    create_virtual_qpu(qubit_count::Int, connectivity::Matrix{Int},
        native_gates::Vector{String}, host = "localhost:5600")
Creates a virtual quantum processor with `qubit_count` number of qubits,
a `connectivity` matrix, and a vector of `native_gates`. 
The return value is a QPU stucture (see  [`QPU`](@ref)).

# Examples
To generate a QPU structure, the connectivity must be specified. Let's assume that we have a
3-qubit device where there is connectivity between qubits 2 and 1 as well as between
qubits 2 and 3. If qubit 2 can only be a control qubit, the connectivity matrix corresponds
to:

```jldoctest create_virtual_qpu
julia> connectivity = [1 0 0
                       1 1 1
                       0 0 1]
3×3 Matrix{Int64}:
 1  0  0
 1  1  1
 0  0  1
```

Here, the ones in the diagonal indicate that all qubits can perform single-qubit gates.
If there is a one in an off-diagonal entry with row i and column j, it indicates that
a two-qubit gate with control qubit i and target qubit j can be applied.

If the native gates are the Pauli-X gate, the Hadamard gate, and the control-X gate,
the QPU can be created as follows: 

```jldoctest create_virtual_qpu
julia> qpu = create_virtual_qpu(3, connectivity, ["x", "h", "cx"])
Quantum Processing Unit:
   manufacturer: none
   generation: none 
   serial_number: 00 
   host: localhost:5600 
   qubit_count: 3 
   native_gates: ["x", "h", "cx"] 
   connectivity = sparse([1, 2, 2, 2, 3], [1, 1, 2, 3, 3], [1, 1, 1, 1, 1], 3, 3)
```
"""
function create_virtual_qpu(qubit_count::Int, connectivity::Matrix{Int}, native_gates::Vector{String}, host = "localhost:5600")
    return create_virtual_qpu(qubit_count, SparseArrays.sparse(connectivity), native_gates, host)
end

function create_virtual_qpu(qubit_count::Int, connectivity::SparseArrays.SparseMatrixCSC{Int}, native_gates::Vector{String}, host = "localhost:5600")
    return QPU(
        manufacturer = "none",
        generation = "none",
        serial_number = "00",
        host = host,
        native_gates = native_gates,
        qubit_count = qubit_count,
        connectivity = connectivity
    )
end


function is_circuit_native_on_qpu(c::QuantumCircuit, qpu::QPU)
    for step in c.pipeline
        for gate in step
            if !(gate.instruction_symbol in qpu.native_gates)
                return false, gate.instruction_symbol
            end
        end
    end
    return true, nothing
end

function does_circuit_satisfy_qpu_connectivity(c::QuantumCircuit, qpu::QPU)
    #this function makes sure all gates satisfy the qpu connectivity
    connectivity_dense = Array(qpu.connectivity)# TODO: all operations should be done in Sparse matrix format.
    for step in c.pipeline
        for gate in step
            i_row = gate.target[1]
            for target_qubit in gate.target
                if (connectivity_dense[i_row,target_qubit]==0)
                    return false, gate
                end
            end
        end
    end        
    return true, nothing
end