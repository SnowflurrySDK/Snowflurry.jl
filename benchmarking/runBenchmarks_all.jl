using Dates

time_stamp=Dates.format(now(),"dd-mm-YYYY_HH:MM")

for file in readlines(joinpath(@__DIR__, "benchmarkList"))
    include(file * ".jl")
end
