using BenchmarkTools
using Snowflake
using JSON
using Plots

include("SnowflakeBenchmarking.jl")

@task "X" nqubits=nqubits begin
    map(nqubits) do k

        op=SparseOperator(get_matrix(sigma_x()))
        target_qubit_1

        hilber_space_size_per_qubit = 2
        system = MultiBodySystem(k, hilber_space_size_per_qubit)

        t = @benchmark get_embed_operator($op, target_qubit_1, $system)*ψ setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

outputpath=joinpath(commonpath,datapath,"X")

if !ispath(outputpath)
    mkpath(outputpath)
end

write(joinpath(outputpath,"X_sparse_$(time_stamp).json"), JSON.json(benchmarks))

plot(nqubits,
    benchmarks["X"]["times"],
    label="X",
    yaxis=:log, 
    color="blue",
    dpi=dpi 
)

scatter!(
    nqubits,
    benchmarks["X"]["times"],
    label=nothing,
    color="blue",
    dpi=dpi
)

savefig(joinpath(outputpath,"plot_X_sparse_$(time_stamp).png"))
