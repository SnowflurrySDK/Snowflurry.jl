for file in readlines(joinpath(@__DIR__, "testgroups"))
    include(file * ".jl")
end
