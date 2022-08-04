@with_kw struct RandomizedBenchmarkingProperties
    num_qubits_on_device::Int; @assert num_qubits_on_device>0
    num_bits_on_device::Int = 0; @assert num_bits_on_device>=0
    target_qubits::Array{Int} = 1:num_qubits_on_device
    sequence_length_list::Array{Int}; @assert all(x->(x>0), sequence_length_list)
    num_sequences_per_length::Array{Int} = 100*ones(Int, length(sequence_length_list));
        @assert all(x->(x>0), num_sequences_per_length)
        @assert length(sequence_length_list) == length(num_sequences_per_length)
end

function run_randomized_benchmarking(circuit_simulator,
    properties::RandomizedBenchmarkingProperties)
    
    for sequence_length in properties.sequence_length_list
        for i in 1:properties.num_sequences_per_length

        end
    end
end

function get_survival_probability(circuit_simulator, sequence_length,
    properties::RandomizedBenchmarkingProperties)


end

function get_random_clifford_circuits(sequence_length_id, transpile!,
    properties::RandomizedBenchmarkingProperties)

    circuit_list = []
    num_target_qubits = length(properties.target_qubits)
    qubit_map = Dict(zip(1:num_target_qubits, properties.target_qubits))

    for i_sequence in 1:properties.num_sequences_per_length[sequence_length_id]
        old_clifford = get_random_clifford(num_target_qubits)
        circuit = get_transpiled_circuit(old_clifford, properties, qubit_map, transpile!)
        clifford_product = old_clifford

        for j_length = 2:properties.sequence_length_list[sequence_length_id]
            new_clifford = get_random_clifford(num_target_qubits)
            new_circuit = get_transpiled_circuit(new_clifford, properties, qubit_map,
                transpile!)
            append!(circuit, new_circuit)
            clifford_product = clifford_product*new_clifford
            old_clifford = new_clifford
        end
        inverse_clifford = inv(clifford_product)
        inverse_circuit = get_transpiled_circuit(inverse_clifford, properties,
            qubit_map, transpile!)
        append!(circuit, inverse_circuit)
        push!(circuit_list, circuit)
    end  
    return circuit_list
end

function get_transpiled_circuit(clifford, properties, qubit_map, transpile!)
    num_target_qubits = length(qubit_map)
    clifford_circuit = QuantumCircuit(qubit_count=num_target_qubits,
            bit_count=properties.num_bits_on_device)
    push_clifford!(clifford_circuit, clifford)
    reordered_circuit = get_reordered_circuit(clifford_circuit, qubit_map)
    circuit = get_wider_circuit(reordered_circuit, properties.num_qubits_on_device)
    transpile!(circuit)
end
