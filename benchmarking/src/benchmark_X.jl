using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "X" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, sigma_x(target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,datapath,"X")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"X_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["X"]["times"],
    label="X",
    yaxis=:log, 
    color="blue",
    dpi=dpi 
)

scatter!(
    nqubits,
    benchmarks["X"]["times"],
    label=nothing,
    color="blue",
    dpi=dpi
)

savefig(joinpath(outputpath,"plot_X_$(time_stamp).png"))
