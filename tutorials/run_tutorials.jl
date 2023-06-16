for file in readlines(joinpath(@__DIR__, "testgroups"))
    filename = file * ".jl"
    @info "Running tutorial: " * filename  
    include(filename)
end
