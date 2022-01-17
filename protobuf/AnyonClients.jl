module AnyonClients
using gRPCClient

include("anyon.jl")
using .anyon.thunderhead.qpu


struct CircuitAPIClient
    controller::gRPCController
    channel::gRPCChannel
    stub::CircuitAPIBlockingStub

    function CircuitAPIClient(api_base_url::String; kwargs...)
        controller = gRPCController(; kwargs...)
        channel = gRPCChannel(api_base_url)
        stub = CircuitAPIBlockingStub(channel)
        new(controller, channel, stub)
    end
end

Base.show(io::IO, client::CircuitAPIClient) =
    print(io, "CircuitAPIClient(", client.channel.baseurl, ")")

submitJob(client::CircuitAPIClient, request::SubmitJobRequest) =
    anyon.thunderhead.qpu.submitJob(client.stub, client.controller, request)
getJobStatus(client::CircuitAPIClient, request::JobStatusRequest) =
    anyon.thunderhead.qpu.getJobStatus(client.stub, client.controller, request)

export submitJob, getJobStatus

end # module AnyonClients
