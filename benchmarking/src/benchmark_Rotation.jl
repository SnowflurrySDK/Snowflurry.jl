using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "Rotation" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, rotation(target_qubit_1,θ,ϕ)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,datapath,"Rotation")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"Rotation_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["Rotation"]["times"],
    label="Rotation",
    yaxis=:log, 
    color="blue",
    dpi=dpi 
)

scatter!(
    nqubits,
    benchmarks["Rotation"]["times"],
    label=nothing,
    color="blue",
    dpi=dpi
)

savefig(joinpath(outputpath,"plot_Rotation_$(time_stamp).png"))
