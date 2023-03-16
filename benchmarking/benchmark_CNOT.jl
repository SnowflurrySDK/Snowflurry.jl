using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "CNOT" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, control_x(control_qubit_1,target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_CNOT")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_CNOT_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["CNOT"]["times"],
    label="CNOT",
    yaxis=:log, 
    color="blue" 
)

scatter!(
    nqubits,
    benchmarks["CNOT"]["times"],
    label=nothing,
    color="blue"
)

savefig(joinpath(outputpath,"plot_CNOT_$(time_stamp).png"))
