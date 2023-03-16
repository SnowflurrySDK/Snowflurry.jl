using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "Y" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, sigma_y(target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_Y")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_Y_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["Y"]["times"],
    label="Y",
    yaxis=:log, 
    color="blue" 
)

scatter!(
    nqubits,
    benchmarks["Y"]["times"],
    label=nothing,
    color="blue"
)

savefig(joinpath(outputpath,"plot_Y_$(time_stamp).png"))