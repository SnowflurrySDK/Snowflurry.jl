using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "H" nqubits = nqubits begin
    map(nqubits) do k
        t = @benchmark apply_instruction!(ψ, hadamard(target_qubit_1)) setup =
            (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "H")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "H_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["H"]["times"],
    label = "H",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(nqubits, benchmarks["H"]["times"], label = nothing, color = "blue", dpi = dpi)

savefig(joinpath(outputpath, "plot_H_$(time_stamp).png"))
