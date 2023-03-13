using BenchmarkTools
using Snowflake

using JSON
using LinearAlgebra
using Dates

time_stamp=Dates.format(now(),"dd-mm-YYYY_HH:MM")

BLAS.set_num_threads(1)

const nqubits=4:25
const benchmarks = Dict()

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

@task "X" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, sigma_x(1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

@task "H" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, hadamard(1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

@task "T" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, pi_8(1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

@task "CNOT" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, control_x(1, 2)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end

@task "Y" nqubits=nqubits begin
    map(nqubits) do k
        t = @benchmark apply_gate!(ψ, sigma_y(1)) setup=(ψ=rand_state($k))
        minimum(t).time
    end
end



if !ispath("data")
    mkpath("data")
end

write("benchmarking/data/data_$(time_stamp).json", JSON.json(benchmarks))
