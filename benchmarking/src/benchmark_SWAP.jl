using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "SWAP" nqubits = nqubits begin
    map(nqubits) do k
        t = @benchmark apply_instruction!(ψ, swap(target_qubit_1, target_qubit_2)) setup =
            (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "SWAP")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "SWAP_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["SWAP"]["times"],
    label = "SWAP",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(nqubits, benchmarks["SWAP"]["times"], label = nothing, color = "blue", dpi = dpi)

savefig(joinpath(outputpath, "plot_SWAP_$(time_stamp).png"))
