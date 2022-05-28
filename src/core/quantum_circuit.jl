
"""
        QuantumCircuit(qubit_count = .., bit_count = ...)

A data structure to represnts a *quantum circuit*.  
**Fields**
- `qubit_count::Int` -- number of qubits (i.e. quantum register size).
- `bit_count::Int` -- number of classical bits (i.e. classical register size).
- `id::UUID` -- a universally unique identifier for the circuit. This id is automatically generated one an instance is created. 
- `pipeline::Array{Array{Gate}}` -- the pipeline of gates to operate on qubits.

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0)
Quantum Circuit Object:
   id: b2d2be56-7af2-11ec-31a6-ed9e71cb3360 
   qubit_count: 2 
   bit_count: 0 
q[1]:
     
q[2]:
```
"""
Base.@kwdef struct QuantumCircuit
    qubit_count::Int
    bit_count::Int
    id::UUID = UUIDs.uuid1()
    pipeline::Array{Array{Gate}} = []
end

"""
        push_gate!(circuit::QuantumCircuit, gate::Gate)
        push_gate!(circuit::QuantumCircuit, gates::Array{Gate})

Pushes a single gate or an array of gates to the `circuit` pipeline. This function is mutable. 

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

julia> push_gate!(c, [hadamard(1),sigma_x(2)])
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:--X----X--
```
"""
function push_gate!(circuit::QuantumCircuit, gate::Gate)
    push!(circuit.pipeline, [gate])
    return circuit
end

function push_gate!(circuit::QuantumCircuit, gates::Array{Gate})
    push!(circuit.pipeline, gates)
    return circuit
end

"""
        pop_gate!(circuit::QuantumCircuit)

Removes the last gate from `circuit.pipeline`. 

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

julia> push_gate!(c, [hadamard(1),sigma_x(2)])
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:--X----X--

julia> pop_gate!(c)
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--
```
"""
function pop_gate!(circuit::QuantumCircuit)
    pop!(circuit.pipeline)
    return circuit
end

function Base.show(io::IO, circuit::QuantumCircuit)
    println(io, "Quantum Circuit Object:")
    println(io, "   id: $(circuit.id) ")
    println(io, "   qubit_count: $(circuit.qubit_count) ")
    println(io, "   bit_count: $(circuit.bit_count) ")

    wire_count = 2 * circuit.qubit_count
    circuit_layout = fill("", (wire_count, length(circuit.pipeline) + 1))

    for i_qubit in range(1, length = circuit.qubit_count)
        id_wire = 2 * (i_qubit - 1) + 1
        circuit_layout[id_wire, 1] = "q[$i_qubit]:"
        circuit_layout[id_wire+1, 1] = String(fill(' ', length(circuit_layout[id_wire, 1])))
    end

    i_step = 1
    for step in circuit.pipeline
        i_step += 1 # the first elemet of the layout is the qubit tag
        for i_qubit in range(1, length = circuit.qubit_count)
            id_wire = 2 * (i_qubit - 1) + 1
            # qubit wire
            circuit_layout[id_wire, i_step] = "-----"
            # spacer line
            circuit_layout[id_wire+1, i_step] = "     "
        end

        for gate in step
            for i_qubit in range(1, length = circuit.qubit_count)
                if (i_qubit in gate.target)
                    id_wire = 2 * (i_qubit - 1) + 1
                    id = findfirst(isequal(i_qubit), gate.target)
                    circuit_layout[id_wire, i_step] = "--$(gate.display_symbol[id])--"
                    if length(gate.target) > 1 && gate.target[1] == i_qubit
                        circuit_layout[id_wire+1, i_step] = "  |  "
                    end
                end
            end
        end
    end


    # circuit_layout[id_wire] = circuit_layout[id_wire] * ".\n"
    # circuit_layout[id_wire + 1] = circuit_layout[id_wire + 1] * ".\n"

    for i_wire in range(1, length = wire_count)
        for i_step in range(1, length = length(circuit.pipeline) + 1)
            # print(io, circuit_layout[i_wire, i_step])
            # println(io, "  i_wire=", i_wire, " i_step=", i_step)
            print(io, circuit_layout[i_wire, i_step])

        end
        println(io, "")
    end
end

"""
        simulate(circuit::QuantumCircuit)

Simulates and returns the wavefunction of the quantum device after running `circuit`. 

# Examples
```jldoctest
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

julia> push_gate!(c, hadamard(1))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:-----
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:-------X--
               


julia> ket = simulate(c);

julia> print(ket)
4-element Ket:
0.7071067811865475 + 0.0im
0.0 + 0.0im
0.0 + 0.0im
0.7071067811865475 + 0.0im


```
"""
function simulate(circuit::QuantumCircuit)
    hilbert_space_size = 2^circuit.qubit_count
    system = MultiBodySystem(circuit.qubit_count, 2)
    # initial state 
    ψ = fock(0, hilbert_space_size)
    for step in circuit.pipeline
        # U is the matrix corresponding the operations happening this step
        #        U = Operator(Matrix{Complex}(1.0I, hilbert_space_size, hilbert_space_size))  
        for gate in step
            # if single qubit gate, get the embedded operator
            # TODO: make sure embedding works for multi qubit system
            S =
                (length(gate.target) == 1) ?
                get_embed_operator(gate.operator, gate.target[1], system) : gate
            ψ = S * ψ
        end

    end
    return ψ
end

"""
        simulate_shots(c::QuantumCircuit, shots_count::Int = 100)

Emulates the function of a quantum computer by running a circuit for given number of shots and return measurement results.

# Examples
```jldoctest simulate_shots; filter = r"00|11"
julia> c = Snowflake.QuantumCircuit(qubit_count = 2, bit_count = 0);

julia> push_gate!(c, hadamard(1))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:-----
          


julia> push_gate!(c, control_x(1,2))
Quantum Circuit Object:
   id: 57cf5de2-7ba7-11ec-0e10-05c6faaf91e9 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:-------X--
               


julia> simulate_shots(c, 99)
99-element Vector{String}:
 "11"
 "00"
 "11"
 "11"
 "11"
 "11"
 "11"
 "00"
 "00"
 "11"
 ⋮
 "00"
 "00"
 "11"
 "00"
 "00"
 "00"
 "00"
 "00"
 "00"
```
"""
function simulate_shots(c::QuantumCircuit, shots_count::Int = 100)
    # return simulateShots(c, shots_count)
    ψ = simulate(c)
    amplitudes = real.(ψ .* ψ)
    weights = Float32[]

    for a in amplitudes
        push!(weights, a)
    end

    ##preparing the labels
    labels = String[]
    for i in range(0, length = length(ψ))
        s = bitstring(i)
        n = length(s)
        s_trimed = s[n-c.qubit_count+1:n]
        push!(labels, s_trimed)
    end

    data = StatsBase.sample(labels, StatsBase.Weights(weights), shots_count)
    return data
end
