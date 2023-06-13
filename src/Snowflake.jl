# This file is part of Snowflake package. License is Apache 2: https://github.com/anyonlabs/Snowflake.jl/blob/main/LICENSE  
"""
Snowflake is an open source library for quantum computing using Julia.
Snowflakes allows one to easily design quantum circuits, experiments and applications and run them on real quantum computers and/or classical simulators. 
"""

module Snowflake
using Base: String
using Printf
using StaticArrays
using LinearAlgebra
using SparseArrays #SparseMatrixCSC
using Arpack #provides eigen value decomposition for sparse matrices

import StatsBase
import OrdinaryDiffEq



export

    # Types
    Bra,
    Ket,
    AbstractOperator,
    IdentityOperator,
    DenseOperator,
    DiagonalOperator,
    AntiDiagonalOperator,
    SparseOperator,
    SwapLikeOperator,
    MultiBodySystem,
    ShrodingerProblem,
    LindbladProblem,
    QuantumCircuit,
    AbstractGate,
    AbstractControlledGate,
    ControlledGate,
    AnyonYukonQPU,
    VirtualQPU,
    Client,
    Status,
    NotImplementedError,
    Transpiler,
    SequentialTranspiler,
    CastSwapToCZGateTranspiler,
    CastCXToCZGateTranspiler,
    CastISwapToCZGateTranspiler,
    CastToffoliToCXGateTranspiler,
    CompressSingleQubitGatesTranspiler,
    CastToPhaseShiftAndHalfRotationXTranspiler,
    CastRxToRzAndHalfRotationXTranspiler,
    SwapQubitsForLineConnectivityTranspiler,
    CastUniversalToRzRxRzTranspiler,
    SimplifyRxGatesTranspiler,
    SimplifyRzGatesTranspiler,
    SimplifyTrivialGatesTranspiler,
    CompressRzGatesTranspiler,
    TrivialTranspiler,
    RemoveSwapBySwappingGatesTranspiler,
    UnsupportedGatesTranspiler,

    # Functions
    commute, 
    anticommute, 
    get_embed_operator,
    get_matrix,
    get_display_symbol,
    get_instruction_symbol,
    fock,
    spin_up,
    spin_down,
    coherent,
    create,
    destroy,
    number_op,
    is_hermitian,
    sparse,
    eigen,
    ket2dm,
    fock_dm,
    expected_value,
    get_num_qubits,
    get_num_bodies,
    get_connected_qubits,
    get_target_qubits,
    get_control_qubits,
    get_gate_parameters,
    is_gate_type,
    get_gate_type,
    move_gate,
    normalize!,
    get_measurement_probabilities,
    genlaguerre,
    moyal,
    wigner, 
    sesolve,
    lindblad_solve,
    tr,
    get_operator,
    simulate,
    simulate_shots,
    get_num_gates,
    get_num_gates_per_type,
    get_circuit_gates,
    compare_circuits,
    circuit_contains_gate_type,
    compare_kets,
    permute_qubits!,
    permute_qubits,
   
    transpile,
    get_status_type,
    get_status_message,
    read_response_body,
    serialize_job,
    submit_circuit,
    get_client,
    print_connectivity,
    get_host,
    get_status,
    get_result,
    is_native_gate,
    is_native_circuit,
    run_job,
    transpile_and_run_job,
    MockRequestor,
    HTTPRequestor,
    get_request,
    post_request,
    get_metadata,
    get_transpiler,
    apply_gate!,

    get_pauli,
    get_quantum_circuit,
    get_negative_exponent,
    get_imaginary_exponent,

    # Gates
    identity_gate,
    sigma_x,
    sigma_y,
    sigma_z,
    sigma_p,
    sigma_m,
    hadamard,
    x_90,
    x_minus_90,
    y_90,
    y_minus_90,
    z_90,
    z_minus_90,
    rotation,
    rotation_x,
    rotation_y,
    phase_shift,
    universal,
    swap,
    iswap,
    iswap_dagger,
    pi_8,
    pi_8_dagger,
    eye,
    control_z,
    control_x,
    toffoli
    

include("core/qobj.jl")
include("core/dynamic_system.jl")
include("core/quantum_gate.jl")
include("core/quantum_circuit.jl")
include("core/pauli.jl")
include("core/transpile.jl")
include("anyon/qpu_interface.jl")
include("anyon/anyon.jl")




end # end module
