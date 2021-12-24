module AnyonClients
using gRPCClient

include("Anyon.jl")
using .Anyon.Iris.Proto

import Base:show

# begin service: Anyon.Iris.Proto.CircuitAPI

export CircuitAPIBlockingClient, CircuitAPIClient

struct CircuitAPIBlockingClient
    controller::gRPCController
    channel::gRPCChannel
    stub::CircuitAPIBlockingStub

    function CircuitAPIBlockingClient(api_base_url::String; kwargs...)
        controller = gRPCController(; kwargs...)
        channel = gRPCChannel(api_base_url)
        stub = CircuitAPIBlockingStub(channel)
        new(controller, channel, stub)
    end
end

struct CircuitAPIClient
    controller::gRPCController
    channel::gRPCChannel
    stub::CircuitAPIStub

    function CircuitAPIClient(api_base_url::String; kwargs...)
        controller = gRPCController(; kwargs...)
        channel = gRPCChannel(api_base_url)
        stub = CircuitAPIStub(channel)
        new(controller, channel, stub)
    end
end

show(io::IO, client::CircuitAPIBlockingClient) = print(io, "CircuitAPIBlockingClient(", client.channel.baseurl, ")")
show(io::IO, client::CircuitAPIClient) = print(io, "CircuitAPIClient(", client.channel.baseurl, ")")

import .Anyon.Iris.Proto:submitCircuitJob
"""
    submitCircuitJob

- input: Anyon.Iris.Proto.SubmitCircuitJobRequest
- output: Anyon.Iris.Proto.SubmitCircuitJobResponse
"""
submitCircuitJob(client::CircuitAPIBlockingClient, inp::Anyon.Iris.Proto.SubmitCircuitJobRequest) = submitCircuitJob(client.stub, client.controller, inp)
submitCircuitJob(client::CircuitAPIClient, inp::Anyon.Iris.Proto.SubmitCircuitJobRequest, done::Function) = submitCircuitJob(client.stub, client.controller, inp, done)

import .Anyon.Iris.Proto:getCircuitJobStatus
"""
    getCircuitJobStatus

- input: Anyon.Iris.Proto.GetCicuitJobStatusRequest
- output: Anyon.Iris.Proto.GetCicuitJobStatusResponse
"""
getCircuitJobStatus(client::CircuitAPIBlockingClient, inp::Anyon.Iris.Proto.GetCicuitJobStatusRequest) = getCircuitJobStatus(client.stub, client.controller, inp)
getCircuitJobStatus(client::CircuitAPIClient, inp::Anyon.Iris.Proto.GetCicuitJobStatusRequest, done::Function) = getCircuitJobStatus(client.stub, client.controller, inp, done)

import .Anyon.Iris.Proto:getCircuitJobResult
"""
    getCircuitJobResult

- input: Anyon.Iris.Proto.GetCircuitJobResultRequest
- output: Anyon.Iris.Proto.GetCircuitJobResultResponse
"""
getCircuitJobResult(client::CircuitAPIBlockingClient, inp::Anyon.Iris.Proto.GetCircuitJobResultRequest) = getCircuitJobResult(client.stub, client.controller, inp)
getCircuitJobResult(client::CircuitAPIClient, inp::Anyon.Iris.Proto.GetCircuitJobResultRequest, done::Function) = getCircuitJobResult(client.stub, client.controller, inp, done)

import .Anyon.Iris.Proto:waitForCircuitJobStatusChange
"""
    waitForCircuitJobStatusChange

- input: Anyon.Iris.Proto.WaitForCircuitJobStatusChangeRequest
- output: Anyon.Iris.Proto.WaitForCircuitJobStatusChangeResponse
"""
waitForCircuitJobStatusChange(client::CircuitAPIBlockingClient, inp::Anyon.Iris.Proto.WaitForCircuitJobStatusChangeRequest) = waitForCircuitJobStatusChange(client.stub, client.controller, inp)
waitForCircuitJobStatusChange(client::CircuitAPIClient, inp::Anyon.Iris.Proto.WaitForCircuitJobStatusChangeRequest, done::Function) = waitForCircuitJobStatusChange(client.stub, client.controller, inp, done)

# end service: Anyon.Iris.Proto.CircuitAPI

end # module AnyonClients
