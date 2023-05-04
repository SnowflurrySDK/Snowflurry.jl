using Dates

time_stamp=Dates.format(now(),"dd-mm-YYYY_HHhMM")

for file in readlines(joinpath(@__DIR__, "benchmark_list_single_target"))
    include(file * ".jl")
end
