using LsqFit

"""
    RandomizedBenchmarkingFitProperties(model_order[, initial_parameters])

Properties specifying how to generate a fit of the averaged sequence fidelity for a
randomized benchmarking calculation.

The models for the fit are described in [`RandomizedBenchmarkingFitResults`](@ref). The
fit can have `model_order` 0, 1, or `nothing`. If `nothing` is specified, no fit will be
generated. Optionally, a dictionary of initial fitting parameters can be passed to the
constructor. The dictionary keys are symbols for the fitting parameters (e.g. "p").
"""
struct RandomizedBenchmarkingFitProperties
    model_order::Union{Integer, Nothing}
    initial_parameters::Union{Dict{String, <:Real}, Nothing}

    function RandomizedBenchmarkingFitProperties(model_order::Union{<:Integer, Nothing},
        initial_parameters::Union{Dict{String, <:Real}, Nothing})
        if model_order == 0
            if length(initial_parameters) != 3
                throw(ErrorException("there must be 3 initial parameters for the
                    zeroth-order fit"))
            end
        elseif model_order == 1
            if length(initial_parameters) != 5
                throw(ErrorException("there must be 5 initial parameters for the
                    first-order fit"))
            end
        elseif !(model_order === nothing)
            throw(ErrorException("the model order must be 0, 1, or nothing"))
        end
        new(model_order, initial_parameters)
    end

    function RandomizedBenchmarkingFitProperties(model_order::Union{<:Integer, Nothing})
        initial_parameters = nothing
        if model_order == 0
            initial_parameters = Dict("p"=>0.99, "A0"=>0.99, "B0"=>0.0)
        elseif model_order == 1
            initial_parameters = Dict("p"=>0.99, "q"=>0.99, "A1"=>0.99, "B1"=>0.0,
                "C1"=>0.0)
        elseif !(model_order === nothing)
            throw(ErrorException("the model order must be 0, 1, or nothing"))
        end
        new(model_order, initial_parameters)
    end
end

"""
    RandomizedBenchmarkingFitResults

A fit of the averaged sequence fidelity of a randomized benchmarking calculation. The fit
can have order 0 or 1. Both models are described in greater details by
[Magesan, Gambetta, and Emerson (2012)](http://dx.doi.org/10.1103/PhysRevA.85.042311).

The zeroth-order model is defined as\n
``F_g^{(0)}(m) = A_0 p^m + B_0``,\n
where ``m`` is the sequence length and ``p`` is related to the average fidelity per
Clifford operation. The state-preparation and measurement errors are taken into account by
``A_0`` and ``B_0``.

The first-order model is defined as\n
``F_g^{(1)}(m) = A_1 p^m + B_1 + C_1(m-1)(q-p^2)p^{m-2}``,\n
where ``q-p^2`` quantifies the severity of gate dependence in the errors. The
state-preparation and measurement errors are taken into account by ``A_1``, ``B_1``,
and ``C_1``.

# Fields
- `model_order`: the order of the model used to generate the fit. If no fit was generated, `model_order` will be `nothing`.
- `parameters`: the optimal parameters for the fit, provided as a dictionary.
- `residuals`: the residuals from the method of least squares.
- `jacobian`: the estimated Jacobian at the solution.
- `converged`: indicates if the method of least squares converged.
"""
@with_kw struct RandomizedBenchmarkingFitResults
    model_order::Union{Int, Nothing} = nothing
    parameters::Union{Dict, Nothing} = nothing
    residuals = nothing
    jacobian = nothing
    converged::Bool = false
end

"""
    RandomizedBenchmarkingProperties

The properties specifying the behaviour of a randomized benchmarking calculation. Each
field can be specified as a keyword argument in the constructor.

# Fields
- `num_qubits_on_device::Int`: the total number of qubits on the device. It can be more than the number of target qubits.
- `num_bits_on_device::Int = 0`: the total number of classical bits on the device.
- `target_qubits::Array{Int}`: a list of the qubits on which benchmarking is performed. By default, all qubits on the device are benchmarked.
- `fit_properties`: the [`RandomizedBenchmarkingFitProperties`](@ref) which define the model for fitting the averaged sequence fidelity.
- `sequence_length_list::Array{Int}`: a list indicating the number of Clifford operations in each circuit. For instance, specifying [1, 2] will lead to the generation of multiple circuits with 1 Clifford operation and multiple circuits with 2 Clifford operations.
- `num_circuits_per_length::Array{Int}`: a list defining how many circuits to generate for each sequence length. By default, 100 circuits are generated for each sequence length.
"""
@with_kw struct RandomizedBenchmarkingProperties
    num_qubits_on_device::Int; @assert num_qubits_on_device > 0
    num_bits_on_device::Int = 0; @assert num_bits_on_device >= 0
    target_qubits::Array{Int} = 1:num_qubits_on_device
    fit_properties::RandomizedBenchmarkingFitProperties =
        RandomizedBenchmarkingFitProperties(0)

    sequence_length_list::Array{Int}; @assert all(x->(x>0), sequence_length_list)
    
    num_circuits_per_length::Array{Int} = 100*ones(Int, length(sequence_length_list));
        @assert all(x->(x>0), num_circuits_per_length)
        @assert length(sequence_length_list) == length(num_circuits_per_length)
end

"""
    RandomizedBenchmarkingResults

The results of a randomized benchmarking calculation.

# Fields
- `sequence_length_list`: a list of the sequence lengths for which randomized circuits will be generated.
- `sequence_fidelities`: a list giving the average fidelity for each sequence length.
- `fit_results`: a fit of the averaged sequence fidelity, stored as [`RandomizedBenchmarkingFitResults`](@ref).
- `average_clifford_fidelity`: the average fidelity of a Clifford operation.
"""
struct RandomizedBenchmarkingResults
    sequence_length_list::AbstractVector{<:Integer}
    sequence_fidelities::AbstractVector{<:Real}
    fit_results::RandomizedBenchmarkingFitResults
    average_clifford_fidelity::Union{<:Real, Nothing}
end

"""
    run_randomized_benchmarking(simulate_shots, properties::RandomizedBenchmarkingProperties, transpile! = (f(x)=x))

Conducts randomized benchmarking and returns [`RandomizedBenchmarkingResults`](@ref).

# Arguments
- `simulate_shots`: a function which takes in an array of `QuantumCircuit` and returns an array of bit strings. The function should not transpile the circuits since it could transpile all the gates into a single identity operation. Use the transpile! argument instead.
- `properties`: the [`RandomizedBenchmarkingProperties`](@ref) influencing benchmarking such as the list of target qubits and the list of sequence lengths.
- `transpile!`: a function which transpiles a single circuit. It transpiles every Clifford operation individually.
"""
function run_randomized_benchmarking(simulate_shots::Function,
    properties::RandomizedBenchmarkingProperties, transpile!::Function = (f(x)=x))
    
    fit_properties = get_fitting_model_properties(properties)
    sequence_fidelities = get_sequence_fidelities(simulate_shots, transpile!,
        properties)
    fit_results = get_fitting_model_results(sequence_fidelities, properties, fit_properties)
    average_fidelity = get_average_fidelity(fit_results, length(properties.target_qubits))
    return RandomizedBenchmarkingResults(properties.sequence_length_list,
        sequence_fidelities, fit_results, average_fidelity)
end

function get_fitting_model_properties(properties::RandomizedBenchmarkingProperties)
    num_lengths = length(properties.sequence_length_list)
    order = properties.fit_properties.model_order
    if num_lengths < 3 && !(order === nothing)
        @warn "At least 3 sequence lengths are needed to generate a fit! "*
            "No fit will be determined."
        return RandomizedBenchmarkingFitProperties(nothing)
    elseif num_lengths < 5 && order == 1
        @warn "At least 5 sequence lengths are needed to generate a first-order fit! "*
            "A zeroth-order fit will be used instead"
        return RandomizedBenchmarkingFitProperties(0)
    end
    initial_parameters = properties.fit_properties.initial_parameters
    return RandomizedBenchmarkingFitProperties(order, initial_parameters)
end

function get_sequence_fidelities(simulate_shots::Function, transpile!::Function,
    properties::RandomizedBenchmarkingProperties)

    circuit_list = QuantumCircuit[]
    for i_length in 1:length(properties.sequence_length_list)
        circuit_list_for_length =
            get_random_clifford_circuits(i_length, transpile!, properties)
        append!(circuit_list, circuit_list_for_length)
    end
    
    shots_list = simulate_shots(circuit_list)
    sequence_fidelity_list = Real[]
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

function get_survival_probability(shots::AbstractVector{String},
    target_qubits::AbstractVector{<:Integer})

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

function get_random_clifford_circuits(sequence_length_id::Integer, transpile!::Function,
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

function get_transpiled_circuit(clifford::CliffordOperator,
    properties::RandomizedBenchmarkingProperties, qubit_map::Dict{<:Integer, <:Integer},
    transpile!::Function)

    num_target_qubits = length(qubit_map)
    clifford_circuit = QuantumCircuit(qubit_count=num_target_qubits,
            bit_count=properties.num_bits_on_device)
    push_clifford!(clifford_circuit, clifford)
    reordered_circuit = get_reordered_circuit(clifford_circuit, qubit_map)
    circuit = get_wider_circuit(reordered_circuit, properties.num_qubits_on_device)
    transpile!(circuit)
end

function get_fitting_model_results(sequence_fidelities::AbstractVector{<:Real},
    properties::RandomizedBenchmarkingProperties,
    fit_properties::RandomizedBenchmarkingFitProperties)

    order = fit_properties.model_order
    results = RandomizedBenchmarkingFitResults()
    if order == 0
        initial_parameters = [fit_properties.initial_parameters["p"],
            fit_properties.initial_parameters["A0"],
            fit_properties.initial_parameters["B0"]]
        fit = curve_fit(get_zeroth_model, properties.sequence_length_list,
            sequence_fidelities, initial_parameters)
        optimal_parameters = Dict("p"=>fit.param[1], "A0"=>fit.param[2], "B0"=>fit.param[3])
        results = RandomizedBenchmarkingFitResults(model_order=order,
            parameters=optimal_parameters,
            residuals=fit.resid, jacobian=fit.jacobian,
            converged=fit.converged)
    elseif order == 1
        initial_parameters = [fit_properties.initial_parameters["p"],
            fit_properties.initial_parameters["q"],
            fit_properties.initial_parameters["A1"],
            fit_properties.initial_parameters["B1"],
            fit_properties.initial_parameters["C1"]]
        fit = curve_fit(get_first_model, properties.sequence_length_list,
            sequence_fidelities, initial_parameters)
        LsqFit.LsqFitResult
        optimal_parameters = Dict("p"=>fit.param[1], "q"=>fit.param[2], "A1"=>fit.param[3],
            "B1"=>fit.param[4], "C1"=>fit.param[5])
        results = RandomizedBenchmarkingFitResults(model_order=order,
            parameters=optimal_parameters,
            residuals=fit.resid, jacobian=fit.jacobian,
            converged=fit.converged)
    end
    return results
end

function get_zeroth_model(m::AbstractVector{<:Real}, p::AbstractVector{<:Real})
    p1 = fill(p[1], length(m))
    return p[2]*p1.^m.+p[3]
end

function get_first_model(m::AbstractVector{<:Real}, p::AbstractVector{<:Real})
    p1 = fill(p[1], length(m))
    return p[3]*p1.^m.+p[4]+p[5]*(m.-1)*(p[2]-p[1]^2).*p1.^(m.-2)
end

function get_average_fidelity(fit_results::RandomizedBenchmarkingFitResults,
    num_target_qubits::Int)
    average_fidelity = nothing
    if !(fit_results.model_order === nothing)
        d = 2^num_target_qubits
        p = fit_results.parameters["p"]
        average_fidelity = p+(1-p)/d
    end
    return average_fidelity
end

"""
    plot_benchmarking(results::RandomizedBenchmarkingResults)

Plots the averaged sequence fidelities and the associated fit, which are generated in a
randomized benchmarking calculation and passed as
[`RandomizedBenchmarkingResults`](@ref).
"""
function plot_benchmarking(results::RandomizedBenchmarkingResults)
    p = plot(results.sequence_length_list, results.sequence_fidelities,
        seriestype = :scatter, label="Computed Sequence Fidelities",
        legend = :bottomleft)
    plot!(p, xaxis = ("Number of Clifford Operations"))
    plot!(p, yaxis = ("Sequence Fidelity", (0,1)))
    order = results.fit_results.model_order
    if order == 0
        optimal_parameters = results.fit_results.parameters
        parameters_vector = [optimal_parameters["p"],
            optimal_parameters["A0"],
            optimal_parameters["B0"]]
        plot_fidelity_model!(p, get_zeroth_model, parameters_vector,
            results.sequence_length_list)
    elseif order == 1
        optimal_parameters = results.fit_results.parameters
        parameters_vector = [optimal_parameters["p"],
            optimal_parameters["q"],
            optimal_parameters["A1"],
            optimal_parameters["B1"],
            optimal_parameters["C1"]]
        plot_fidelity_model!(p, get_first_model, parameters_vector,
            results.sequence_length_list)
    end
    return p
end

function plot_fidelity_model!(plot, get_model::Function,
    parameters_vector::AbstractVector{<:Real},
    sequence_length_list::AbstractVector{<:Integer})

    sequence_lengths_for_plot = 1:last(sequence_length_list)
    fidelity_fit = get_model(sequence_lengths_for_plot, parameters_vector)
    plot!(plot, sequence_lengths_for_plot, fidelity_fit,
        label="Sequence Fidelity Model")
end
