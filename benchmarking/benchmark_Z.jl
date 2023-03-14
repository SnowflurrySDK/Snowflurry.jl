using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "Z" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, sigma_z(target_qubit_1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,"data_Z")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"data_Z_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["Z"]["times"],
    label="Z",
    yaxis=:log, 
    color="blue"
)

scatter!(
    nqubits,
    benchmarks["Z"]["times"],
    label=nothing, 
    color="blue"
)

savefig(joinpath(outputpath,"plot_Z_$(time_stamp).png"))