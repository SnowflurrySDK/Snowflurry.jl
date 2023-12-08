using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "RotationY" nqubits = nqubits begin
    map(nqubits) do k
        t = @benchmark apply_instruction!(ψ, rotation_y(target_qubit_1, θ)) setup =
            (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "RotationY")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "RotationY_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["RotationY"]["times"],
    label = "RotationY",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(
    nqubits,
    benchmarks["RotationY"]["times"],
    label = nothing,
    color = "blue",
    dpi = dpi,
)

savefig(joinpath(outputpath, "plot_RotationY_$(time_stamp).png"))
