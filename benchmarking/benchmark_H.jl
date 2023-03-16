using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "H" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, hadamard(target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_H")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_H_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["H"]["times"],
    label="H",
    yaxis=:log, 
    color="blue" 
)

scatter!(
    nqubits,
    benchmarks["H"]["times"],
    label=nothing,
    color="blue"
)

savefig(joinpath(outputpath,"plot_H_$(time_stamp).png"))