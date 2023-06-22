using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "T" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, pi_8(target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,datapath,"T")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"T_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["T"]["times"],
    label="T",
    yaxis=:log, 
    color="blue",
    dpi=dpi 
)

scatter!(
    nqubits,
    benchmarks["T"]["times"],
    label=nothing,
    color="blue",
    dpi=dpi
)


savefig(joinpath(outputpath,"plot_T_$(time_stamp).png"))