using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "ISWAP" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, iswap(target_qubit_1,target_qubit_2)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_ISWAP")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_ISWAP_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["ISWAP"]["times"],
    label="ISWAP",
    yaxis=:log, 
    color="blue" 
)

scatter!(
    nqubits,
    benchmarks["ISWAP"]["times"],
    label=nothing,
    color="blue"
)

savefig(joinpath(outputpath,"plot_ISWAP_$(time_stamp).png"))