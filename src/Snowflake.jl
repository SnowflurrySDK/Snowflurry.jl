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
import SparseArrays



export

    # Types
    Bra,
    Ket,
    Operator,
    MultiBodySystem,
    QuantumCircuit,
    Gate,
    QPU,

    # Functions
    get_embed_operator,
    fock,
    push_gate!,
    pop_gate!,
    simulate,
    simulate_shots,
    plot_histogram,
    submit_circuit,
    get_circuit_status,
   
    create_virtual_qpu,
    is_circuit_native_on_qpu,
    does_circuit_satisfy_qpu_connectivity,
    transpile,

    # Gates
    sigma_x,
    sigma_y,
    sigma_z,
    hadamard,
    x_90,
    iswap,
    pi_8,
    phase,
    eye,
    control_z,
    control_x,
    STD_GATES,
    PAULI_GATES,
    

    #  Enums
    JobStatus

include("qobj.jl")
include("quantum_gate.jl")
include("quantum_circuit.jl")
include("qpu.jl")
include("transpile.jl")
include("remote/circuit_jobs.jl")
include("visualize.jl")



end # end module
