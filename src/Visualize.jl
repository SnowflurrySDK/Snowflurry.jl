# using PyPlot
using Plots
export histogram
function histogram(circuit::Circuit, shots_count::Int)
    data = simulateShots(circuit, shots_count)
    datamap = proportionmap(data)

    labels = String[]
    for (key, value) in datamap
        push!(labels, key)
    end

    Plots.bar((x -> datamap[x]).(labels), xticks=(1:length(data), labels), legends=false, ylabel="probabilities")  
end
