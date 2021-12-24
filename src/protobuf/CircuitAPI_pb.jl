# syntax: proto3
using ProtoBuf
import ProtoBuf.meta

const CircuitJobStatus_CircuitJobStatusType = (;[
    Symbol("QUEUED") => Int32(0),
    Symbol("RUNNING") => Int32(1),
    Symbol("COMPLETED") => Int32(2),
    Symbol("FAILED") => Int32(3),
    Symbol("CANCELED") => Int32(4),
]...)

mutable struct CircuitJobStatus <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function CircuitJobStatus(; kwargs...)
        obj = new(meta(CircuitJobStatus), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct CircuitJobStatus
const __meta_CircuitJobStatus = Ref{ProtoMeta}()
function meta(::Type{CircuitJobStatus})
    ProtoBuf.metalock() do
        if !isassigned(__meta_CircuitJobStatus)
            __meta_CircuitJobStatus[] = target = ProtoMeta(CircuitJobStatus)
            allflds = Pair{Symbol,Union{Type,String}}[:_type => Int32, :message => AbstractString]
            meta(target, CircuitJobStatus, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_CircuitJobStatus[]
    end
end
function Base.getproperty(obj::CircuitJobStatus, name::Symbol)
    if name === :_type
        return (obj.__protobuf_jl_internal_values[name])::Int32
    elseif name === :message
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    else
        getfield(obj, name)
    end
end

mutable struct SubmitCircuitJobRequest <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function SubmitCircuitJobRequest(; kwargs...)
        obj = new(meta(SubmitCircuitJobRequest), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct SubmitCircuitJobRequest
const __meta_SubmitCircuitJobRequest = Ref{ProtoMeta}()
function meta(::Type{SubmitCircuitJobRequest})
    ProtoBuf.metalock() do
        if !isassigned(__meta_SubmitCircuitJobRequest)
            __meta_SubmitCircuitJobRequest[] = target = ProtoMeta(SubmitCircuitJobRequest)
            allflds = Pair{Symbol,Union{Type,String}}[:circuit => Circuit, :num_shots => UInt64]
            meta(target, SubmitCircuitJobRequest, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_SubmitCircuitJobRequest[]
    end
end
function Base.getproperty(obj::SubmitCircuitJobRequest, name::Symbol)
    if name === :circuit
        return (obj.__protobuf_jl_internal_values[name])::Circuit
    elseif name === :num_shots
        return (obj.__protobuf_jl_internal_values[name])::UInt64
    else
        getfield(obj, name)
    end
end

mutable struct SubmitCircuitJobResponse <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function SubmitCircuitJobResponse(; kwargs...)
        obj = new(meta(SubmitCircuitJobResponse), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct SubmitCircuitJobResponse
const __meta_SubmitCircuitJobResponse = Ref{ProtoMeta}()
function meta(::Type{SubmitCircuitJobResponse})
    ProtoBuf.metalock() do
        if !isassigned(__meta_SubmitCircuitJobResponse)
            __meta_SubmitCircuitJobResponse[] = target = ProtoMeta(SubmitCircuitJobResponse)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :status => CircuitJobStatus]
            meta(target, SubmitCircuitJobResponse, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_SubmitCircuitJobResponse[]
    end
end
function Base.getproperty(obj::SubmitCircuitJobResponse, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :status
        return (obj.__protobuf_jl_internal_values[name])::CircuitJobStatus
    else
        getfield(obj, name)
    end
end

mutable struct GetCicuitJobStatusRequest <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function GetCicuitJobStatusRequest(; kwargs...)
        obj = new(meta(GetCicuitJobStatusRequest), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct GetCicuitJobStatusRequest
const __meta_GetCicuitJobStatusRequest = Ref{ProtoMeta}()
function meta(::Type{GetCicuitJobStatusRequest})
    ProtoBuf.metalock() do
        if !isassigned(__meta_GetCicuitJobStatusRequest)
            __meta_GetCicuitJobStatusRequest[] = target = ProtoMeta(GetCicuitJobStatusRequest)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString]
            meta(target, GetCicuitJobStatusRequest, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_GetCicuitJobStatusRequest[]
    end
end
function Base.getproperty(obj::GetCicuitJobStatusRequest, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    else
        getfield(obj, name)
    end
end

mutable struct GetCicuitJobStatusResponse <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function GetCicuitJobStatusResponse(; kwargs...)
        obj = new(meta(GetCicuitJobStatusResponse), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct GetCicuitJobStatusResponse
const __meta_GetCicuitJobStatusResponse = Ref{ProtoMeta}()
function meta(::Type{GetCicuitJobStatusResponse})
    ProtoBuf.metalock() do
        if !isassigned(__meta_GetCicuitJobStatusResponse)
            __meta_GetCicuitJobStatusResponse[] = target = ProtoMeta(GetCicuitJobStatusResponse)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :status => CircuitJobStatus]
            meta(target, GetCicuitJobStatusResponse, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_GetCicuitJobStatusResponse[]
    end
end
function Base.getproperty(obj::GetCicuitJobStatusResponse, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :status
        return (obj.__protobuf_jl_internal_values[name])::CircuitJobStatus
    else
        getfield(obj, name)
    end
end

mutable struct GetCircuitJobResultRequest <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function GetCircuitJobResultRequest(; kwargs...)
        obj = new(meta(GetCircuitJobResultRequest), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct GetCircuitJobResultRequest
const __meta_GetCircuitJobResultRequest = Ref{ProtoMeta}()
function meta(::Type{GetCircuitJobResultRequest})
    ProtoBuf.metalock() do
        if !isassigned(__meta_GetCircuitJobResultRequest)
            __meta_GetCircuitJobResultRequest[] = target = ProtoMeta(GetCircuitJobResultRequest)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString]
            meta(target, GetCircuitJobResultRequest, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_GetCircuitJobResultRequest[]
    end
end
function Base.getproperty(obj::GetCircuitJobResultRequest, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    else
        getfield(obj, name)
    end
end

mutable struct GetCircuitJobResultResponse <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function GetCircuitJobResultResponse(; kwargs...)
        obj = new(meta(GetCircuitJobResultResponse), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct GetCircuitJobResultResponse
const __meta_GetCircuitJobResultResponse = Ref{ProtoMeta}()
function meta(::Type{GetCircuitJobResultResponse})
    ProtoBuf.metalock() do
        if !isassigned(__meta_GetCircuitJobResultResponse)
            __meta_GetCircuitJobResultResponse[] = target = ProtoMeta(GetCircuitJobResultResponse)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :result_set => CircuitResultSet, :status => CircuitJobStatus]
            meta(target, GetCircuitJobResultResponse, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_GetCircuitJobResultResponse[]
    end
end
function Base.getproperty(obj::GetCircuitJobResultResponse, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :result_set
        return (obj.__protobuf_jl_internal_values[name])::CircuitResultSet
    elseif name === :status
        return (obj.__protobuf_jl_internal_values[name])::CircuitJobStatus
    else
        getfield(obj, name)
    end
end

mutable struct WaitForCircuitJobStatusChangeRequest <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function WaitForCircuitJobStatusChangeRequest(; kwargs...)
        obj = new(meta(WaitForCircuitJobStatusChangeRequest), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct WaitForCircuitJobStatusChangeRequest
const __meta_WaitForCircuitJobStatusChangeRequest = Ref{ProtoMeta}()
function meta(::Type{WaitForCircuitJobStatusChangeRequest})
    ProtoBuf.metalock() do
        if !isassigned(__meta_WaitForCircuitJobStatusChangeRequest)
            __meta_WaitForCircuitJobStatusChangeRequest[] = target = ProtoMeta(WaitForCircuitJobStatusChangeRequest)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString]
            meta(target, WaitForCircuitJobStatusChangeRequest, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_WaitForCircuitJobStatusChangeRequest[]
    end
end
function Base.getproperty(obj::WaitForCircuitJobStatusChangeRequest, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    else
        getfield(obj, name)
    end
end

mutable struct WaitForCircuitJobStatusChangeResponse <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function WaitForCircuitJobStatusChangeResponse(; kwargs...)
        obj = new(meta(WaitForCircuitJobStatusChangeResponse), Dict{Symbol,Any}(), Set{Symbol}())
        values = obj.__protobuf_jl_internal_values
        symdict = obj.__protobuf_jl_internal_meta.symdict
        for nv in kwargs
            fldname, fldval = nv
            fldtype = symdict[fldname].jtyp
            (fldname in keys(symdict)) || error(string(typeof(obj), " has no field with name ", fldname))
            if fldval !== nothing
                values[fldname] = isa(fldval, fldtype) ? fldval : convert(fldtype, fldval)
            end
        end
        obj
    end
end # mutable struct WaitForCircuitJobStatusChangeResponse
const __meta_WaitForCircuitJobStatusChangeResponse = Ref{ProtoMeta}()
function meta(::Type{WaitForCircuitJobStatusChangeResponse})
    ProtoBuf.metalock() do
        if !isassigned(__meta_WaitForCircuitJobStatusChangeResponse)
            __meta_WaitForCircuitJobStatusChangeResponse[] = target = ProtoMeta(WaitForCircuitJobStatusChangeResponse)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :status => CircuitJobStatus]
            meta(target, WaitForCircuitJobStatusChangeResponse, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_WaitForCircuitJobStatusChangeResponse[]
    end
end
function Base.getproperty(obj::WaitForCircuitJobStatusChangeResponse, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :status
        return (obj.__protobuf_jl_internal_values[name])::CircuitJobStatus
    else
        getfield(obj, name)
    end
end

# service methods for CircuitAPI
const _CircuitAPI_methods = MethodDescriptor[
        MethodDescriptor("submitCircuitJob", 1, SubmitCircuitJobRequest, SubmitCircuitJobResponse),
        MethodDescriptor("getCircuitJobStatus", 2, GetCicuitJobStatusRequest, GetCicuitJobStatusResponse),
        MethodDescriptor("getCircuitJobResult", 3, GetCircuitJobResultRequest, GetCircuitJobResultResponse),
        MethodDescriptor("waitForCircuitJobStatusChange", 4, WaitForCircuitJobStatusChangeRequest, WaitForCircuitJobStatusChangeResponse)
    ] # const _CircuitAPI_methods
const _CircuitAPI_desc = ServiceDescriptor("Anyon.Iris.Proto.CircuitAPI", 1, _CircuitAPI_methods)

CircuitAPI(impl::Module) = ProtoService(_CircuitAPI_desc, impl)

mutable struct CircuitAPIStub <: AbstractProtoServiceStub{false}
    impl::ProtoServiceStub
    CircuitAPIStub(channel::ProtoRpcChannel) = new(ProtoServiceStub(_CircuitAPI_desc, channel))
end # mutable struct CircuitAPIStub

mutable struct CircuitAPIBlockingStub <: AbstractProtoServiceStub{true}
    impl::ProtoServiceBlockingStub
    CircuitAPIBlockingStub(channel::ProtoRpcChannel) = new(ProtoServiceBlockingStub(_CircuitAPI_desc, channel))
end # mutable struct CircuitAPIBlockingStub

submitCircuitJob(stub::CircuitAPIStub, controller::ProtoRpcController, inp::SubmitCircuitJobRequest, done::Function) = call_method(stub.impl, _CircuitAPI_methods[1], controller, inp, done)
submitCircuitJob(stub::CircuitAPIBlockingStub, controller::ProtoRpcController, inp::SubmitCircuitJobRequest) = call_method(stub.impl, _CircuitAPI_methods[1], controller, inp)

getCircuitJobStatus(stub::CircuitAPIStub, controller::ProtoRpcController, inp::GetCicuitJobStatusRequest, done::Function) = call_method(stub.impl, _CircuitAPI_methods[2], controller, inp, done)
getCircuitJobStatus(stub::CircuitAPIBlockingStub, controller::ProtoRpcController, inp::GetCicuitJobStatusRequest) = call_method(stub.impl, _CircuitAPI_methods[2], controller, inp)

getCircuitJobResult(stub::CircuitAPIStub, controller::ProtoRpcController, inp::GetCircuitJobResultRequest, done::Function) = call_method(stub.impl, _CircuitAPI_methods[3], controller, inp, done)
getCircuitJobResult(stub::CircuitAPIBlockingStub, controller::ProtoRpcController, inp::GetCircuitJobResultRequest) = call_method(stub.impl, _CircuitAPI_methods[3], controller, inp)

waitForCircuitJobStatusChange(stub::CircuitAPIStub, controller::ProtoRpcController, inp::WaitForCircuitJobStatusChangeRequest, done::Function) = call_method(stub.impl, _CircuitAPI_methods[4], controller, inp, done)
waitForCircuitJobStatusChange(stub::CircuitAPIBlockingStub, controller::ProtoRpcController, inp::WaitForCircuitJobStatusChangeRequest) = call_method(stub.impl, _CircuitAPI_methods[4], controller, inp)

export CircuitJobStatus_CircuitJobStatusType, CircuitJobStatus, SubmitCircuitJobRequest, SubmitCircuitJobResponse, GetCicuitJobStatusRequest, GetCicuitJobStatusResponse, GetCircuitJobResultRequest, GetCircuitJobResultResponse, WaitForCircuitJobStatusChangeRequest, WaitForCircuitJobStatusChangeResponse, CircuitAPI, CircuitAPIStub, CircuitAPIBlockingStub, submitCircuitJob, getCircuitJobStatus, getCircuitJobResult, waitForCircuitJobStatusChange
