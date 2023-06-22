using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "CNOT" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, control_x(control_qubit_1,target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,datapath,"CNOT")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"CNOT_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["CNOT"]["times"],
    label="CNOT",
    yaxis=:log, 
    color="blue",
    dpi=dpi 
)

scatter!(
    nqubits,
    benchmarks["CNOT"]["times"],
    label=nothing,
    color="blue",
    dpi=dpi
)

savefig(joinpath(outputpath,"plot_CNOT_$(time_stamp).png"))
