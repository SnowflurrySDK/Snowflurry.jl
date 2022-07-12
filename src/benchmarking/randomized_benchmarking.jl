@with_kw struct RandomizedBenchmarkingProperties
    num_qubits_on_device::Int; @assert num_qubits_on_device>0
    target_qubits::Array{Int} = 1:num_qubits_on_device
    sequence_length_list::Array{Int}; @assert all(x->(x>0), sequence_length_list)
    num_sequences_per_length::Int = 100; @assert num_sequences_per_length>0
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

function get_random_clifford_circuit(sequence_length,
    properties::RandomizedBenchmarkingProperties)

    circuit = QuantumCircuit(qubit_count=properties.num_qubits_on_device,
        bit_count=0)
    
end
