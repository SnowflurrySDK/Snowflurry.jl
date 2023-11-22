using BenchmarkTools
using Snowflurry
using JSON
using Plots

include("SnowflurryBenchmarking.jl")

@task "TOFFOLI" nqubits = nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(
            ψ,
            toffoli(control_qubit_1, control_qubit_2, target_qubit_1),
        ) setup = (ψ = rand_state($k))
        minimum(t).time
    end
end

outputpath = joinpath(commonpath, datapath, "TOFFOLI")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath, "TOFFOLI_$(time_stamp).json"), JSON.json(benchmarks))

plot(
    nqubits,
    benchmarks["TOFFOLI"]["times"],
    label = "TOFFOLI",
    yaxis = :log,
    color = "blue",
    dpi = dpi,
)

scatter!(
    nqubits,
    benchmarks["TOFFOLI"]["times"],
    label = nothing,
    color = "blue",
    dpi = dpi,
)


savefig(joinpath(outputpath, "plot_TOFFOLI_$(time_stamp).png"))
