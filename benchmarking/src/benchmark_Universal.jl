using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "Universal" nqubits = nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, universal(target_qubit_1, θ, ϕ, λ)) setup =
            (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "Universal")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "Universal_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["Universal"]["times"],
    label = "Universal",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(
    nqubits,
    benchmarks["Universal"]["times"],
    label = nothing,
    color = "blue",
    dpi = dpi,
)

savefig(joinpath(outputpath, "plot_Universal_$(time_stamp).png"))
