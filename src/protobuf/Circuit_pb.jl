# syntax: proto3
using ProtoBuf
import ProtoBuf.meta

mutable struct CircuitParameters <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function CircuitParameters(; kwargs...)
        obj = new(meta(CircuitParameters), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct CircuitParameters
const __meta_CircuitParameters = Ref{ProtoMeta}()
function meta(::Type{CircuitParameters})
    ProtoBuf.metalock() do
        if !isassigned(__meta_CircuitParameters)
            __meta_CircuitParameters[] = target = ProtoMeta(CircuitParameters)
            allflds = Pair{Symbol,Union{Type,String}}[:name => AbstractString, :value => Float32]
            meta(target, CircuitParameters, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_CircuitParameters[]
    end
end
function Base.getproperty(obj::CircuitParameters, name::Symbol)
    if name === :name
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :value
        return (obj.__protobuf_jl_internal_values[name])::Float32
    else
        getfield(obj, name)
    end
end

mutable struct CircuitOperation <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function CircuitOperation(; kwargs...)
        obj = new(meta(CircuitOperation), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct CircuitOperation
const __meta_CircuitOperation = Ref{ProtoMeta}()
function meta(::Type{CircuitOperation})
    ProtoBuf.metalock() do
        if !isassigned(__meta_CircuitOperation)
            __meta_CircuitOperation[] = target = ProtoMeta(CircuitOperation)
            pack = Symbol[:connected_qubits,:connected_bits]
            allflds = Pair{Symbol,Union{Type,String}}[:_type => AbstractString, :parameters => Base.Vector{CircuitParameters}, :connected_qubits => Base.Vector{UInt64}, :connected_bits => Base.Vector{UInt64}]
            meta(target, CircuitOperation, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, pack, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_CircuitOperation[]
    end
end
function Base.getproperty(obj::CircuitOperation, name::Symbol)
    if name === :_type
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :parameters
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{CircuitParameters}
    elseif name === :connected_qubits
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{UInt64}
    elseif name === :connected_bits
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{UInt64}
    else
        getfield(obj, name)
    end
end

mutable struct Circuit <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function Circuit(; kwargs...)
        obj = new(meta(Circuit), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct Circuit
const __meta_Circuit = Ref{ProtoMeta}()
function meta(::Type{Circuit})
    ProtoBuf.metalock() do
        if !isassigned(__meta_Circuit)
            __meta_Circuit[] = target = ProtoMeta(Circuit)
            allflds = Pair{Symbol,Union{Type,String}}[:operations => Base.Vector{CircuitOperation}]
            meta(target, Circuit, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_Circuit[]
    end
end
function Base.getproperty(obj::Circuit, name::Symbol)
    if name === :operations
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{CircuitOperation}
    else
        getfield(obj, name)
    end
end

export CircuitParameters, CircuitOperation, Circuit
