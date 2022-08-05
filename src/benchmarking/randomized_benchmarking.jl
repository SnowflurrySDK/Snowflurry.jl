@with_kw struct RandomizedBenchmarkingProperties
    num_qubits_on_device::Int; @assert num_qubits_on_device > 0
    num_bits_on_device::Int = 0; @assert num_bits_on_device >= 0
    target_qubits::Array{Int} = 1:num_qubits_on_device
    num_shots_per_circuit::Int = 100; @assert num_shots_per_circuit > 0
    sequence_length_list::Array{Int}; @assert all(x->(x>0), sequence_length_list)
    num_circuits_per_length::Array{Int} = 100*ones(Int, length(sequence_length_list));
        @assert all(x->(x>0), num_circuits_per_length)
        @assert length(sequence_length_list) == length(num_circuits_per_length)
end

function run_randomized_benchmarking(simulate_shots, transpile!,
    properties::RandomizedBenchmarkingProperties)
    
    sequence_fidelities = get_sequence_fidelities(simulate_shots, transpile!,
        properties)
end

function get_sequence_fidelities(simulate_shots, transpile!,
    properties::RandomizedBenchmarkingProperties)

    circuit_list = QuantumCircuit[]
    for i_length in 1:length(properties.sequence_length_list)
        circuit_list_for_length =
            get_random_clifford_circuits(i_length, transpile!, properties)
        append!(circuit_list, circuit_list_for_length)
    end
    
    shots_list = simulate_shots(circuit_list, properties.num_shots_per_circuit)
    sequence_fidelity_list = []
    circuit_id = 1
    for i_length in 1:length(properties.sequence_length_list)
        survival_probability_sum = 0
        num_circuits_for_length = properties.num_circuits_per_length[i_length]
        for j_circuit_for_length = 1:num_circuits_for_length
            survival_probability_sum += get_survival_probability(shots_list[circuit_id],
                properties.target_qubits)
            circuit_id += 1
        end
        sequence_fidelity = survival_probability_sum/num_circuits_for_length
        push!(sequence_fidelity_list, sequence_fidelity)
    end
    return sequence_fidelity_list
end

function get_survival_probability(shots, target_qubits)
    num_successes = 0
    num_target_qubits = length(target_qubits)
    for measurement in shots
        trimmed_measurement = measurement[target_qubits]
        if trimmed_measurement == "0"^num_target_qubits
            num_successes += 1
        end
    end
    survival_probability = num_successes/length(shots)
    return survival_probability
end

function get_random_clifford_circuits(sequence_length_id, transpile!,
    properties::RandomizedBenchmarkingProperties)

    circuit_list = []
    num_target_qubits = length(properties.target_qubits)
    qubit_map = Dict(zip(1:num_target_qubits, properties.target_qubits))

    for i_circuit in 1:properties.num_circuits_per_length[sequence_length_id]
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
