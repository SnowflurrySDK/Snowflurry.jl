using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "Z" nqubits = nqubits begin
    map(nqubits) do k
        t = @benchmark apply_instruction!(ψ, sigma_z(target_qubit_1)) setup = (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "Z")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "Z_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["Z"]["times"],
    label = "Z",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(nqubits, benchmarks["Z"]["times"], label = nothing, color = "blue", dpi = dpi)

savefig(joinpath(outputpath, "plot_Z_$(time_stamp).png"))
