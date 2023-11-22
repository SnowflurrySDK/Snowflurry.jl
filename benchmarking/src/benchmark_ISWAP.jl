using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "ISWAP" nqubits = nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, iswap(target_qubit_1, target_qubit_2)) setup =
            (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "ISWAP")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "ISWAP_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["ISWAP"]["times"],
    label = "ISWAP",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(nqubits, benchmarks["ISWAP"]["times"], label = nothing, color = "blue", dpi = dpi)

savefig(joinpath(outputpath, "plot_ISWAP_$(time_stamp).png"))
