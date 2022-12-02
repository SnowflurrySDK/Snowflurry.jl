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
using Parameters
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
    BlochSphere,
    AnimatedBlochSphere,

    # Functions
    commute, 
    anticommute, 
    get_embed_operator,
    fock,
    spin_up,
    spin_down,
    coherent,
    create,
    destroy,
    number_op,
    ishermitian,
    eigen,
    ket2dm,
    fock_dm,
    expected_value,
    get_num_qubits,
    get_num_bodies,
    normalize!,
    wigner, 
    viz_wigner, 
    sesolve,
    mesolve,
    tr,
    get_inverse,
    push_gate!,
    pop_gate!,
    simulate,
    simulate_shots,
    plot_histogram,
    plot_bloch_sphere,
    plot_bloch_sphere_animation,
    submit_circuit,
    get_circuit_status,
   
    create_virtual_qpu,
    is_circuit_native_on_qpu,
    does_circuit_satisfy_qpu_connectivity,
    transpile,

    apply_gate!,

    # Gates
    sigma_x,
    sigma_y,
    sigma_z,
    sigma_p,
    sigma_m,
    hadamard,
    x_90,
    rotation,
    rotation_x,
    rotation_y,
    rotation_z,
    phase_shift,
    universal,
    iswap,
    iswap_dagger,
    pi_8,
    pi_8_dagger,
    phase,
    phase_dagger,
    eye,
    control_z,
    control_x,
    toffoli,
    STD_GATES,
    PAULI_GATES,
    

    #  Enums
    JobStatus

include("core/qobj.jl")
include("core/dynamic_system.jl")
include("core/quantum_gate.jl")
include("core/quantum_circuit.jl")
include("core/qpu.jl")
include("core/transpile.jl")
include("core/visualize.jl")
include("remote/circuit_jobs.jl")




end # end module
