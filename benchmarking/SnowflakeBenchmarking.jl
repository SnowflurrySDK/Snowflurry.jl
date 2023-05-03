using Snowflake
using Dates
using LinearAlgebra

if ~(@isdefined(time_stamp)) 
    # enables time_stamp to be common for all benchmarks done through runBenchmarks.jl
    # or for individual benchmarks to be run seperately.
    time_stamp=Dates.format(now(),"dd-mm-YYYY_HHhMM")
end

BLAS.set_num_threads(1)

nqubits=4:25

target_qubit_1=1
target_qubit_2=2
control_qubit_1=3
control_qubit_2=4

ϕ=π/4 # for phase_shift()

benchmarks = Dict()

commonpath="benchmarking/data/"

rand_state(nQubits::Int,T::Type{<:Complex}=ComplexF64)= Ket(randn(T, 2^nQubits)) # not normalized

macro task(name::String, nqubits_ex, body)
    nqubits = nqubits_ex.args[2]
    msg = "benchmarking $name"
    quote
        @info $msg
        benchmarks[$(name)] = Dict()
        benchmarks[$(name)]["nqubits"] = $(esc(nqubits))
        benchmarks[$(name)]["times"] = $(esc(body))
    end
end

