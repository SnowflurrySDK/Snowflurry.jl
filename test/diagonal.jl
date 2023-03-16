using Snowflake
using Test
using StaticArrays

@testset "diagonal_gate" begin

    qubit_count=3
    target=1
    
    ϕ=π  
    ψ = Ket([v for v in 1:2^qubit_count])

    phase_gate=Snowflake.phase_shift_diag(target,ϕ)

    phase_gate_operator=get_operator(phase_gate)

    println(phase_gate_operator)

    apply_gate!(ψ, phase_gate)
    
    ψ_z = Ket([v for v in 1:2^qubit_count])

    ZGate=sigma_z(target)
    apply_gate!(ψ_z, ZGate)

    @test ψ≈ψ_z

    ##############################################
    # DiagonalOperator

    # Ctor from Real-valued array
    @test DiagonalOperator([1.,2.])==DiagonalOperator(SVector{2,ComplexF64}([1.,2.]))

    @test adjoint(phase_gate_operator).data≈get_operator(Snowflake.phase_shift_diag(target,-ϕ)).data
        
    ###############################################
    ### different code path in apply_operator when target is last qubit

    target=3
    
    ψ = Ket([v for v in 1:2^qubit_count])

    phase_gate=Snowflake.phase_shift_diag(target,ϕ)
    
    @test get_operator(get_inverse(phase_gate))==get_operator(Snowflake.phase_shift_diag(target,-ϕ))
    
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


    nonexistent_gate(target::Integer) = NonExistentGate(target) # to test MethodError on non-implemented AbstractGates

    struct NonExistentGate <: Snowflake.AbstractGate
        target::Int
    end

    nonexistent_gate=nonexistent_gate(target)

    @test_throws NotImplementedError Snowflake.get_connected_qubits(nonexistent_gate)
   
    ######################################################

    diagonalGate_N_targets(target_list::Vector{<:Integer}) = 
        Diagonal_N_TargetGate(target_list)

    struct Diagonal_N_TargetGate <: Snowflake.AbstractGate
        target_list::Vector{<:Integer}
    end

    Snowflake.get_operator(gate::Diagonal_N_TargetGate,T::Type{<:Complex}=ComplexF64) = 
        diagonalGate_N_targets(length(gate.target_list),T)

    diagonalGate_N_targets(N_targets::Integer,T::Type{<:Complex}=ComplexF64) =
        DiagonalOperator{2^N_targets,T}(T[exp(im*n*pi/4.0) for n in 1:2^N_targets])

    Snowflake.get_connected_qubits(gate::Diagonal_N_TargetGate)=gate.target_list

    #####################################

    target_qubit_1=1
    target_qubit_2=2

    my_diagonalGate_2targets=diagonalGate_N_targets([target_qubit_1,target_qubit_2])

    ψ= Ket([1., 10., 100., 1000.])

    apply_gate!(ψ, my_diagonalGate_2targets)

    ψ_result=Ket([
        0.7071067811865476 + 0.7071067811865475im
        0.0 + 10.0im
        -70.71067811865474 + 70.71067811865476im
        -1000.0 + 0.0im
    ])

    @test ψ≈ψ_result

    #####################################

    target_qubit_1=1
    target_qubit_2=2
    target_qubit_3=3

    qubit_count=3

    my_diagonalGate_3targets=
        diagonalGate_N_targets([target_qubit_1,target_qubit_2,target_qubit_3])

    ψ= Ket([10^v for v in 1:2^qubit_count])

    apply_gate!(ψ, my_diagonalGate_3targets)

    ψ_result=Ket([
        7.0710678118654755 + 7.071067811865475im
        0.0 + 100.0im
        -707.1067811865474 + 707.1067811865476im
        -10000.0 + 0.0im
        -70710.67811865477 - 70710.67811865475im
        0.0 - 1.0e6im
        7.071067811865473e6 - 7.071067811865477e6im
        1.0e8 - 0.0im  
    ])

    @test ψ≈ψ_result


    #####################################

    target_qubit_1=1
    target_qubit_2=2
    target_qubit_3=10 # erroneous

    qubit_count=3

    my_diagonalGate_3targets=
        diagonalGate_N_targets([target_qubit_1,target_qubit_2,target_qubit_3])

    ψ= Ket([10^v for v in 1:2^qubit_count])

    @test_throws DomainError apply_gate!(ψ, my_diagonalGate_3targets)

    ψ= Ket([10^v for v in 1:2^(qubit_count-1)])

    @test_throws DomainError apply_gate!(ψ, my_diagonalGate_3targets)


end


