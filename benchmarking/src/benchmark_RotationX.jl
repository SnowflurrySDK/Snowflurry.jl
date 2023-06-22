using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "RotationX" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, rotation_x(target_qubit_1,θ)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,datapath,"RotationX")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"RotationX_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["RotationX"]["times"],
    label="RotationX",
    yaxis=:log, 
    color="blue",
    dpi=dpi 
)

scatter!(
    nqubits,
    benchmarks["RotationX"]["times"],
    label=nothing,
    color="blue",
    dpi=dpi
)

savefig(joinpath(outputpath,"plot_RotationX_$(time_stamp).png"))
