using Snowflake
using Test
using StaticArrays

@testset "diagonal_gate" begin

    qubit_count=3
    target=1
    
    ϕ=π  
    ψ = Ket([v for v in 1:2^qubit_count])

    phase_gate=Snowflake.phase_shift_diag(target,ϕ)

    println(get_operator(phase_gate))

    apply_gate!(ψ, phase_gate)
    
    ψ_z = Ket([v for v in 1:2^qubit_count])

    ZGate=sigma_z(target)
    apply_gate!(ψ_z, ZGate)

    @test ψ≈ψ_z

    ##############################################
    # DiagonalOperator

    diag_op=DiagonalOperator([1.,2.])

    println(diag_op)

    # Ctor from Real-valued array
    @test DiagonalOperator([1.,2.])==DiagonalOperator(SVector{2,ComplexF64}([1.,2.]))

    # Ctor from adjoint
    @test adjoint(DiagonalOperator(SVector{2,ComplexF64}([1.0+im,2.0-im])))==
        DiagonalOperator(SVector{2,ComplexF64}([1.0-im,2.0+im]))

    
    ###############################################
    ### different code path in apply_operator when target is last qubit

    target=3
    
    ψ = Ket([v for v in 1:2^qubit_count])

    phase_gate=Snowflake.phase_shift_diag(target,ϕ)
    apply_gate!(ψ, phase_gate)
    
    ψ_z = Ket([v for v in 1:2^qubit_count])

    ZGate=sigma_z(target)
    apply_gate!(ψ_z, ZGate)

    @test ψ≈ψ_z

    ###############################################
    # T gate (PhaseGate with π/8 phase) test

    target=1

    ψ = Ket([v for v in 1:2^qubit_count])

    T_gate=Snowflake.pi_8_diag(target)
    apply_gate!(ψ, T_gate)
    
    ψ_result = Ket([
        1.0 + 0.0im,
        2.0 + 0.0im,
        3.0 + 0.0im,
        4.0 + 0.0im,
        3.5355339059327378 + 3.5355339059327373im,
        4.242640687119286 + 4.242640687119285im,
        4.949747468305833 + 4.949747468305832im,
        5.656854249492381 + 5.65685424949238im,
    ])

    @test ψ≈ψ_result

    ψ_error = Ket([
        1.0 + 0.0im,
        2.0 + 0.0im,
        3.0 + 0.0im,
        4.0 + 0.0im,
        5.0 + 0.0im,
        6.0 + 0.0im,
        7.0 + 0.0im,
        ]
    )

    @test_throws DomainError apply_gate!(ψ_error, T_gate)

    target_error=100

    T_gate_error=Snowflake.pi_8_diag(target_error)

    @test_throws DomainError apply_gate!(ψ, T_gate_error)

    @test_throws NotImplementedError get_inverse(T_gate_error) #TODO, implement inverse of DiagonalGate

    ######################################################

    nonexistent_gate=Snowflake.nonexistent_gate(target)

    @test_throws NotImplementedError Snowflake.get_connected_qubits(nonexistent_gate)
   

end


