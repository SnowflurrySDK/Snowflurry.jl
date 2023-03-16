using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "CZ" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, control_z(control_qubit_1,target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_CZ")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_CZ_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["CZ"]["times"],
    label="CZ",
    yaxis=:log, 
    color="blue" 
)

scatter!(
    nqubits,
    benchmarks["CZ"]["times"],
    label=nothing,
    color="blue"
)

savefig(joinpath(outputpath,"plot_CZ_$(time_stamp).png"))
