module Snowflake
using Base:String
using Plots:size

# using .AnyonClients: CircuitAPIClient, SubmitJobRequest, SubmitJobReply, Instruction, Instruction_Parameter, Circuit

include("QObj.jl")
include("Gate.jl")
include("Circuit.jl")
include("remote/CircuitJobs.jl")
include("Visualize.jl")


end # end module
