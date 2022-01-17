# This file is part of Snowflake package. License is Apache 2: https://github.com/anyonlabs/Snowflake.jl/blob/main/LICENSE  
"""
Snowflake is an open source library for quantum computing using Julia.
Snowflakes allows one to easily design quantum circuits, experiments and applications and run them on real quantum computers and/or classical simulators. 
"""

module Snowflake
using Base: String
using Plots: size
using LinearAlgebra
using StatsBase
using UUIDs
using Printf
using Plots



export

    # Types
    Bra,
    Ket,
    Operator,
    MultiBodySystem,
    QuantumCircuit,
    Gate,
    submit_circuit,
    get_circuit_status,


    # Functions
    get_embed_operator,
    fock,
    push_gate!,
    pop_gate!,
    simulate,
    simulate_shots,
    plot_histogram,

    #  Enums
    JobStatus

include("qobj.jl")
include("quantum_gate.jl")
include("quantum_circuit.jl")
include("remote/circuit_jobs.jl")
include("visualize.jl")


end # end module
