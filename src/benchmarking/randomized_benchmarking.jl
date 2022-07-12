@with_kw struct RandomizedBenchmarkingProperties
    num_qubits::Int; @assert num_qubits>0
    target_qubits::Array{Int} = 1:num_qubits
    sequence_length_list::Array{Int}; @assert all(x->(x>0), sequence_length_list)
    num_sequences_per_length::Int = 100; @assert num_sequences_per_length>0
end