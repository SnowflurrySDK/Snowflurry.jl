using Snowflurry
using Dates
using LinearAlgebra

if ~(@isdefined(time_stamp))
    # enables time_stamp to be common for all benchmarks launched from 
    # run_benchmarks_all.jl or run_benchmarks_single_target.jl, 
    # or for individual benchmarks to be run seperately.
    time_stamp = Dates.format(now(), "dd-mm-YYYY_HHhMM")
end

# ensure single-threaded operation
BLAS.set_num_threads(1)

# define range of qubit counts for the benchmarks on each gate
min_qubit_count = 4
max_qubit_count = 25

nqubits = min_qubit_count:max_qubit_count

target_qubit_1 = 1
target_qubit_2 = 2
control_qubit_1 = 3
control_qubit_2 = 4

# for parameterized gates
θ = π / 5
ϕ = π / 4
λ = π / 7

benchmarks = Dict()

commonpath = "benchmarking"
datapath = "data"

dpi = 400 # dots per inch in plots

rand_state(nQubits::Int, T::Type{<:Complex} = ComplexF64) = Ket(randn(T, 2^nQubits)) # not normalized

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
