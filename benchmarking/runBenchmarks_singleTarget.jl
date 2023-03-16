using Dates

time_stamp=Dates.format(now(),"dd-mm-YYYY_HH:MM")

for file in readlines(joinpath(@__DIR__, "benchmarkList_singleTarget"))
    include(file * ".jl")
end
