# syntax: proto3
using ProtoBuf
import ProtoBuf.meta

const CircuitJobStatus_CircuitJobStatusType = (;[
    Symbol("UNKNOWN") => Int32(0),
    Symbol("QUEUED") => Int32(1),
    Symbol("RUNNING") => Int32(2),
    Symbol("COMPLETED") => Int32(3),
    Symbol("FAILED") => Int32(4),
    Symbol("CANCELED") => Int32(5),
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

mutable struct SubmitJobRequest <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function SubmitJobRequest(; kwargs...)
        obj = new(meta(SubmitJobRequest), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct SubmitJobRequest
const __meta_SubmitJobRequest = Ref{ProtoMeta}()
function meta(::Type{SubmitJobRequest})
    ProtoBuf.metalock() do
        if !isassigned(__meta_SubmitJobRequest)
            __meta_SubmitJobRequest[] = target = ProtoMeta(SubmitJobRequest)
            allflds = Pair{Symbol,Union{Type,String}}[:circuit => Circuit, :shots_count => UInt64, :owner => AbstractString, :token => AbstractString]
            meta(target, SubmitJobRequest, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_SubmitJobRequest[]
    end
end
function Base.getproperty(obj::SubmitJobRequest, name::Symbol)
    if name === :circuit
        return (obj.__protobuf_jl_internal_values[name])::Circuit
    elseif name === :shots_count
        return (obj.__protobuf_jl_internal_values[name])::UInt64
    elseif name === :owner
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :token
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    else
        getfield(obj, name)
    end
end

mutable struct SubmitJobReply <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function SubmitJobReply(; kwargs...)
        obj = new(meta(SubmitJobReply), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct SubmitJobReply
const __meta_SubmitJobReply = Ref{ProtoMeta}()
function meta(::Type{SubmitJobReply})
    ProtoBuf.metalock() do
        if !isassigned(__meta_SubmitJobReply)
            __meta_SubmitJobReply[] = target = ProtoMeta(SubmitJobReply)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :status => CircuitJobStatus]
            meta(target, SubmitJobReply, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_SubmitJobReply[]
    end
end
function Base.getproperty(obj::SubmitJobReply, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :status
        return (obj.__protobuf_jl_internal_values[name])::CircuitJobStatus
    else
        getfield(obj, name)
    end
end

mutable struct JobStatusRequest <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function JobStatusRequest(; kwargs...)
        obj = new(meta(JobStatusRequest), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct JobStatusRequest
const __meta_JobStatusRequest = Ref{ProtoMeta}()
function meta(::Type{JobStatusRequest})
    ProtoBuf.metalock() do
        if !isassigned(__meta_JobStatusRequest)
            __meta_JobStatusRequest[] = target = ProtoMeta(JobStatusRequest)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :owner => AbstractString, :token => AbstractString]
            meta(target, JobStatusRequest, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_JobStatusRequest[]
    end
end
function Base.getproperty(obj::JobStatusRequest, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :owner
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :token
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    else
        getfield(obj, name)
    end
end

mutable struct JobStatusReply <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function JobStatusReply(; kwargs...)
        obj = new(meta(JobStatusReply), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct JobStatusReply
const __meta_JobStatusReply = Ref{ProtoMeta}()
function meta(::Type{JobStatusReply})
    ProtoBuf.metalock() do
        if !isassigned(__meta_JobStatusReply)
            __meta_JobStatusReply[] = target = ProtoMeta(JobStatusReply)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :status => CircuitJobStatus]
            meta(target, JobStatusReply, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_JobStatusReply[]
    end
end
function Base.getproperty(obj::JobStatusReply, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :status
        return (obj.__protobuf_jl_internal_values[name])::CircuitJobStatus
    else
        getfield(obj, name)
    end
end

mutable struct JobResultRequest <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function JobResultRequest(; kwargs...)
        obj = new(meta(JobResultRequest), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct JobResultRequest
const __meta_JobResultRequest = Ref{ProtoMeta}()
function meta(::Type{JobResultRequest})
    ProtoBuf.metalock() do
        if !isassigned(__meta_JobResultRequest)
            __meta_JobResultRequest[] = target = ProtoMeta(JobResultRequest)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString]
            meta(target, JobResultRequest, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_JobResultRequest[]
    end
end
function Base.getproperty(obj::JobResultRequest, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    else
        getfield(obj, name)
    end
end

mutable struct JobResultReply <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function JobResultReply(; kwargs...)
        obj = new(meta(JobResultReply), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct JobResultReply
const __meta_JobResultReply = Ref{ProtoMeta}()
function meta(::Type{JobResultReply})
    ProtoBuf.metalock() do
        if !isassigned(__meta_JobResultReply)
            __meta_JobResultReply[] = target = ProtoMeta(JobResultReply)
            allflds = Pair{Symbol,Union{Type,String}}[:job_uuid => AbstractString, :results => Base.Vector{Result}, :status => CircuitJobStatus]
            meta(target, JobResultReply, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_JobResultReply[]
    end
end
function Base.getproperty(obj::JobResultReply, name::Symbol)
    if name === :job_uuid
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :results
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{Result}
    elseif name === :status
        return (obj.__protobuf_jl_internal_values[name])::CircuitJobStatus
    else
        getfield(obj, name)
    end
end

# service methods for CircuitAPI
const _CircuitAPI_methods = MethodDescriptor[
        MethodDescriptor("submitJob", 1, SubmitJobRequest, SubmitJobReply),
        MethodDescriptor("getJobStatus", 2, JobStatusRequest, JobStatusReply),
        MethodDescriptor("getJobResult", 3, JobResultRequest, JobResultReply)
    ] # const _CircuitAPI_methods
const _CircuitAPI_desc = ServiceDescriptor("anyon.thunderhead.qpu.CircuitAPI", 1, _CircuitAPI_methods)

CircuitAPI(impl::Module) = ProtoService(_CircuitAPI_desc, impl)

mutable struct CircuitAPIStub <: AbstractProtoServiceStub{false}
    impl::ProtoServiceStub
    CircuitAPIStub(channel::ProtoRpcChannel) = new(ProtoServiceStub(_CircuitAPI_desc, channel))
end # mutable struct CircuitAPIStub

mutable struct CircuitAPIBlockingStub <: AbstractProtoServiceStub{true}
    impl::ProtoServiceBlockingStub
    CircuitAPIBlockingStub(channel::ProtoRpcChannel) = new(ProtoServiceBlockingStub(_CircuitAPI_desc, channel))
end # mutable struct CircuitAPIBlockingStub

submitJob(stub::CircuitAPIStub, controller::ProtoRpcController, inp::SubmitJobRequest, done::Function) = call_method(stub.impl, _CircuitAPI_methods[1], controller, inp, done)
submitJob(stub::CircuitAPIBlockingStub, controller::ProtoRpcController, inp::SubmitJobRequest) = call_method(stub.impl, _CircuitAPI_methods[1], controller, inp)

getJobStatus(stub::CircuitAPIStub, controller::ProtoRpcController, inp::JobStatusRequest, done::Function) = call_method(stub.impl, _CircuitAPI_methods[2], controller, inp, done)
getJobStatus(stub::CircuitAPIBlockingStub, controller::ProtoRpcController, inp::JobStatusRequest) = call_method(stub.impl, _CircuitAPI_methods[2], controller, inp)

getJobResult(stub::CircuitAPIStub, controller::ProtoRpcController, inp::JobResultRequest, done::Function) = call_method(stub.impl, _CircuitAPI_methods[3], controller, inp, done)
getJobResult(stub::CircuitAPIBlockingStub, controller::ProtoRpcController, inp::JobResultRequest) = call_method(stub.impl, _CircuitAPI_methods[3], controller, inp)

export CircuitJobStatus_CircuitJobStatusType, CircuitJobStatus, SubmitJobRequest, SubmitJobReply, JobStatusRequest, JobStatusReply, JobResultRequest, JobResultReply, CircuitAPI, CircuitAPIStub, CircuitAPIBlockingStub, submitJob, getJobStatus, getJobResult
