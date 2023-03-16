using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "TOFFOLI" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, toffoli(control_qubit_1, control_qubit_2, target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_TOFFOLI")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_TOFFOLI_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["TOFFOLI"]["times"],
    label="TOFFOLI",
    yaxis=:log, 
    color="blue" 
)

scatter!(
    nqubits,
    benchmarks["TOFFOLI"]["times"],
    label=nothing,
    color="blue"
)


savefig(joinpath(outputpath,"plot_TOFFOLI_$(time_stamp).png"))