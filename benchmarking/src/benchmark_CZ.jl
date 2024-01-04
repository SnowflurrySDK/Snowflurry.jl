using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "CZ" nqubits = nqubits begin
    map(nqubits) do k
        t =
            @benchmark apply_instruction!(ψ, control_z(control_qubit_1, target_qubit_1)) setup =
                (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "CZ")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "CZ_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["CZ"]["times"],
    label = "CZ",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(nqubits, benchmarks["CZ"]["times"], label = nothing, color = "blue", dpi = dpi)

savefig(joinpath(outputpath, "plot_CZ_$(time_stamp).png"))
