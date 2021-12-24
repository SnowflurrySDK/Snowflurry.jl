# syntax: proto3
using ProtoBuf
import ProtoBuf.meta

mutable struct CircuitResult <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function CircuitResult(; kwargs...)
        obj = new(meta(CircuitResult), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct CircuitResult
const __meta_CircuitResult = Ref{ProtoMeta}()
function meta(::Type{CircuitResult})
    ProtoBuf.metalock() do
        if !isassigned(__meta_CircuitResult)
            __meta_CircuitResult[] = target = ProtoMeta(CircuitResult)
            pack = Symbol[:bits]
            allflds = Pair{Symbol,Union{Type,String}}[:bits => Base.Vector{Bool}, :count => UInt64]
            meta(target, CircuitResult, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, pack, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_CircuitResult[]
    end
end
function Base.getproperty(obj::CircuitResult, name::Symbol)
    if name === :bits
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{Bool}
    elseif name === :count
        return (obj.__protobuf_jl_internal_values[name])::UInt64
    else
        getfield(obj, name)
    end
end

mutable struct CircuitResultSet <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function CircuitResultSet(; kwargs...)
        obj = new(meta(CircuitResultSet), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct CircuitResultSet
const __meta_CircuitResultSet = Ref{ProtoMeta}()
function meta(::Type{CircuitResultSet})
    ProtoBuf.metalock() do
        if !isassigned(__meta_CircuitResultSet)
            __meta_CircuitResultSet[] = target = ProtoMeta(CircuitResultSet)
            allflds = Pair{Symbol,Union{Type,String}}[:results => Base.Vector{CircuitResult}]
            meta(target, CircuitResultSet, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_CircuitResultSet[]
    end
end
function Base.getproperty(obj::CircuitResultSet, name::Symbol)
    if name === :results
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{CircuitResult}
    else
        getfield(obj, name)
    end
end

export CircuitResult, CircuitResultSet
