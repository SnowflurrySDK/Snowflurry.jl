# syntax: proto3
using ProtoBuf
import ProtoBuf.meta

mutable struct Instruction_Parameter <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function Instruction_Parameter(; kwargs...)
        obj = new(meta(Instruction_Parameter), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct Instruction_Parameter
const __meta_Instruction_Parameter = Ref{ProtoMeta}()
function meta(::Type{Instruction_Parameter})
    ProtoBuf.metalock() do
        if !isassigned(__meta_Instruction_Parameter)
            __meta_Instruction_Parameter[] = target = ProtoMeta(Instruction_Parameter)
            allflds = Pair{Symbol,Union{Type,String}}[:name => AbstractString, :value => Float32]
            meta(target, Instruction_Parameter, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_Instruction_Parameter[]
    end
end
function Base.getproperty(obj::Instruction_Parameter, name::Symbol)
    if name === :name
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :value
        return (obj.__protobuf_jl_internal_values[name])::Float32
    else
        getfield(obj, name)
    end
end

mutable struct Instruction <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function Instruction(; kwargs...)
        obj = new(meta(Instruction), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct Instruction
const __meta_Instruction = Ref{ProtoMeta}()
function meta(::Type{Instruction})
    ProtoBuf.metalock() do
        if !isassigned(__meta_Instruction)
            __meta_Instruction[] = target = ProtoMeta(Instruction)
            pack = Symbol[:qubits,:classical_bits]
            allflds = Pair{Symbol,Union{Type,String}}[:symbol => AbstractString, :parameters => Base.Vector{Instruction_Parameter}, :qubits => Base.Vector{UInt64}, :classical_bits => Base.Vector{UInt64}]
            meta(target, Instruction, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, pack, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_Instruction[]
    end
end
function Base.getproperty(obj::Instruction, name::Symbol)
    if name === :symbol
        return (obj.__protobuf_jl_internal_values[name])::AbstractString
    elseif name === :parameters
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{Instruction_Parameter}
    elseif name === :qubits
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{UInt64}
    elseif name === :classical_bits
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
            allflds = Pair{Symbol,Union{Type,String}}[:instructions => Base.Vector{Instruction}]
            meta(target, Circuit, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_Circuit[]
    end
end
function Base.getproperty(obj::Circuit, name::Symbol)
    if name === :instructions
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{Instruction}
    else
        getfield(obj, name)
    end
end

mutable struct Result <: ProtoType
    __protobuf_jl_internal_meta::ProtoMeta
    __protobuf_jl_internal_values::Dict{Symbol,Any}
    __protobuf_jl_internal_defaultset::Set{Symbol}

    function Result(; kwargs...)
        obj = new(meta(Result), Dict{Symbol,Any}(), Set{Symbol}())
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
end # mutable struct Result
const __meta_Result = Ref{ProtoMeta}()
function meta(::Type{Result})
    ProtoBuf.metalock() do
        if !isassigned(__meta_Result)
            __meta_Result[] = target = ProtoMeta(Result)
            allflds = Pair{Symbol,Union{Type,String}}[:shot_read_out => Base.Vector{AbstractString}]
            meta(target, Result, allflds, ProtoBuf.DEF_REQ, ProtoBuf.DEF_FNUM, ProtoBuf.DEF_VAL, ProtoBuf.DEF_PACK, ProtoBuf.DEF_WTYPES, ProtoBuf.DEF_ONEOFS, ProtoBuf.DEF_ONEOF_NAMES)
        end
        __meta_Result[]
    end
end
function Base.getproperty(obj::Result, name::Symbol)
    if name === :shot_read_out
        return (obj.__protobuf_jl_internal_values[name])::Base.Vector{AbstractString}
    else
        getfield(obj, name)
    end
end

export Instruction_Parameter, Instruction, Circuit, Result
