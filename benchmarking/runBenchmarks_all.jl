using Dates

# this timestamp will propagate to all benchmarks output files
time_stamp=Dates.format(now(),"dd-mm-YYYY_HHhMM")

for file in readlines(joinpath(@__DIR__, "benchmarkList"))
    include(file * ".jl")
end
