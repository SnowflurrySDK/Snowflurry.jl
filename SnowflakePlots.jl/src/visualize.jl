"""
    plot_histogram(circuit::QuantumCircuit, shots_count::Int)

Plots a histogram showing the measurement output distribution of a `circuit`.
    
The number of shots taken is specified by `shots_count`.
    
# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count=2);

julia> push!(circuit, [hadamard(1), sigma_x(2)])
Quantum Circuit Object:
   qubit_count: 2 
q[1]:──H───────
               
q[2]:───────X──


```
```julia
julia> plot = plot_histogram(circuit, 100)

```
![Measurement histogram for circuit](assets/visualize/plot_histogram.png)
"""
function plot_histogram(circuit::QuantumCircuit, shots_count::Int)
    data = simulate_shots(circuit, shots_count)
    datamap = proportionmap(data)

    labels = String[]
    for (key, value) in datamap
        push!(labels, key)
    end

    Plots.bar(
        (x -> datamap[x]).(labels),
        xticks = (1:length(data), labels),
        legends = false,
        ylabel = "probabilities",
    )
end

"""
    viz_wigner(ρ::AbstractOperator,
        x::Union{AbstractRange{<:Real},AbstractVector{<:Real}},
        y::Union{AbstractRange{<:Real},AbstractVector{<:Real}})

Generates a contour plot of the Wigner function of the density matrix `ρ`.
    
The range of the plot is specified by the phase-space coordinates `x` and `y`.
    
# Examples
```jldoctest
julia> ρ = ket2dm(coherent(0.25, 8));

julia> x = y = -3.0:0.1:3.0;

```
```julia
julia> viz_wigner(ρ, x, y)

```
![Wigner function contour plot](assets/visualize/viz_wigner.png)
"""
function viz_wigner(ρ::AbstractOperator,
    x::Union{AbstractRange{<:Real},AbstractVector{<:Real}},
    y::Union{AbstractRange{<:Real},AbstractVector{<:Real}})

    return Plots.contour(x, y, (x,y) -> wigner(ρ, x, y), fill = true)
end
