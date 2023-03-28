"""
    plot_histogram(circuit::QuantumCircuit, shots_count::Int)

Plots a histogram showing the measurement output distribution of a `circuit`.
    
The number of shots taken is specified by `shots_count`.
    
# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count=2, bit_count=0);

julia> push_gate!(circuit, [hadamard(1), sigma_x(2)])
Quantum Circuit Object:
   id: c9ebdf08-f0ba-11ec-0c5e-8ff2bf2f3825 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H──
          
q[2]:──X──


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

function viz_wigner(ρ, x, y)
    return Plots.contour(x, y, (x,y) -> wigner(ρ, x, y), fill = true)
end
