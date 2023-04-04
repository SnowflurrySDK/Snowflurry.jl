using Snowflake
using Test
using StaticArrays


@testset "Diagonal Gate: phase_shift" begin

    qubit_count=3
    target=1
    
    ϕ=π  
    ψ = Ket([v for v in 1:2^qubit_count])

    phase_gate=phase_shift(target,ϕ)

    phase_gate_operator=get_operator(phase_gate)

    println(phase_gate_operator)

    @test !is_hermitian(phase_gate_operator)

    @test phase_gate_operator[2,2]==exp(ϕ*im)
    @test phase_gate_operator[2,1]===ComplexF64(0.)

    composite_op=kron(phase_gate_operator,eye())

    @test composite_op[1,1]==phase_gate_operator[1,1]
    @test composite_op[2,2]==phase_gate_operator[1,1]
    @test composite_op[1,2]==ComplexF64(0.)
    @test composite_op[3,3]≈ phase_gate_operator[2,2]
    @test composite_op[4,4]≈ phase_gate_operator[2,2]

    composite_op=kron(eye(),phase_gate_operator)

    @test composite_op[1,1]==phase_gate_operator[1,1]
    @test composite_op[2,2]==phase_gate_operator[2,2]
    @test composite_op[1,2]==ComplexF64(0.)
    @test composite_op[3,3]≈ phase_gate_operator[1,1]
    @test composite_op[4,4]≈ phase_gate_operator[2,2]

    apply_gate!(ψ, phase_gate)
    
    ψ_z = Ket([v for v in 1:2^qubit_count])

    ZGate=sigma_z(target)
    apply_gate!(ψ_z, ZGate)

    @test ψ≈ψ_z

    # Ctor from LinearAlgebra.Adjoint(DiagonalOperator{N,T})
    @test adjoint(phase_gate_operator)≈get_operator(Snowflake.phase_shift(target,-ϕ))

    @test test_inverse(phase_gate)

end

@testset "Diagonal Gate: apply_operator to last qubit" begin

    ###############################################
    ### different code path in apply_operator when target is last qubit
    qubit_count=3
    target=3
    
    ϕ=π  

    ψ = Ket([v for v in 1:2^qubit_count])

    phase_gate=phase_shift(target,ϕ)
    
    op=get_operator(phase_gate)

    @test op[1,1] === ComplexF64(1.)
    @test op[2,2] === exp(im*ϕ)
    @test op[2,1] === ComplexF64(0.)

    @test get_operator(inv(phase_gate))==get_operator(phase_shift(target,-ϕ))
  
    apply_gate!(ψ, phase_gate)

end

@testset "Diagonal Gate: sigma_z" begin
    
    qubit_count=3
    target=1

    input_array=[v for v in 1:2^qubit_count]
    
    ψ_z = Ket(input_array)

    z_gate=sigma_z(target)
    apply_gate!(ψ_z, z_gate)

    input_array[5:end]=-input_array[5:end]

    result=Ket(input_array)

    @test ψ_z≈result

    qubit_count=1

    ψ_z = Ket([v for v in 1:2^qubit_count])

    @test expected_value(get_operator(z_gate), ψ_z) == ComplexF64(-3.)

    @test test_inverse(z_gate)

end

@testset "Diagonal Gate: Pi8" begin

    ###############################################
    # T gate (PhaseGate with π/8 phase) test

    qubit_count=3
    target=1

    ψ = Ket([v for v in 1:2^qubit_count])

    T_gate=pi_8(target)
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

    T_gate_error=pi_8(target_error)

    @test_throws DomainError apply_gate!(ψ, T_gate_error)
   
end


