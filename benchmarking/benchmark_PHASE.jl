using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "PHASE" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, phase_shift(target_qubit_1,ϕ)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_PHASE")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_PHASE_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["PHASE"]["times"],
    label="PHASE",
    yaxis=:log, 
    color="blue" 
)

scatter!(
    nqubits,
    benchmarks["PHASE"]["times"],
    label=nothing,
    color="blue"
)


savefig(joinpath(outputpath,"plot_PHASE_$(time_stamp).png"))