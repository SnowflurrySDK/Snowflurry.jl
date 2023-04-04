using Snowflake
using Test

include("testFunctions.jl")

test_operator_implementation(
    AntiDiagonalOperator,
    dim=1,
    label="AntiDiagonalOperator",
    values=[1.,2.] # only single target AntiDiagonalOperator are allowed
)

@testset "AntiDiagonalOperator" begin

    @test_throws DomainError AntiDiagonalOperator([1,2,3,4]) 

    anti_diag_op=AntiDiagonalOperator([1,2])

    #kron
    composite_op=kron(anti_diag_op,eye())

    @test composite_op[1,3]==anti_diag_op[1,2]
    @test composite_op[2,4]==anti_diag_op[1,2]
    @test composite_op[1,1]==ComplexF64(0.)
    @test composite_op[3,1]≈ anti_diag_op[2,1]
    @test composite_op[4,2]≈ anti_diag_op[2,1]

    composite_op=kron(eye(),anti_diag_op)

    @test composite_op[1,2]==anti_diag_op[1,2]
    @test composite_op[2,1]==anti_diag_op[2,1]
    @test composite_op[1,1]==ComplexF64(0.)
    @test composite_op[3,4]≈ anti_diag_op[1,2]
    @test composite_op[4,3]≈ anti_diag_op[2,1]

    # Base.:* 

    input_array_complex=make_array(1, ComplexF64,[1.,2.])

    anti_diag_op=AntiDiagonalOperator(input_array_complex)

    result=DiagonalOperator(
        [a*b for (a,b) in zip(
            input_array_complex,
            reverse(input_array_complex)
            )
        ])

    @test anti_diag_op*anti_diag_op≈ result
    @test DenseOperator(anti_diag_op)*anti_diag_op≈ result
    @test anti_diag_op*DenseOperator(anti_diag_op)≈ result
    
    # Exponentiation

    anti_diag_op=AntiDiagonalOperator([1,1])
    op=exp(-im*π/2*anti_diag_op)
    
    @test isapprox(op[1,1],ComplexF64(0.),atol=1e-12)
    @test op[1,2] ≈ -im
    @test op[2,1] ≈ -im
    @test isapprox(op[2,2],ComplexF64(0.),atol=1e-12)

    composite_op=kron(anti_diag_op,eye())

    @test composite_op[1,3]==anti_diag_op[1,2]
    @test composite_op[2,4]==anti_diag_op[1,2]
    @test composite_op[1,1]==ComplexF64(0.)
    @test composite_op[3,1]≈ anti_diag_op[2,1]
    @test composite_op[4,2]≈ anti_diag_op[2,1]

    composite_op=kron(eye(),anti_diag_op)

    @test composite_op[1,2]==anti_diag_op[1,2]
    @test composite_op[2,1]==anti_diag_op[2,1]
    @test composite_op[1,1]==ComplexF64(0.)
    @test composite_op[3,4]≈ anti_diag_op[1,2]
    @test composite_op[4,3]≈ anti_diag_op[2,1]
    
    # LinearAlgebra.eigen
    vals, vecs = Snowflake.eigen(anti_diag_op)
    @test vals[1] ≈ -1.0
    @test vals[2] ≈ 1.0 

end

@testset "AntiDiagonal Gate: SigmaY" begin

    qubit_count=3
    target=1
    
    ψ = Ket([v for v in 1:2^qubit_count])

    Y_gate=Snowflake.sigma_y(target)

    y_operator=get_operator(Y_gate)

    println(y_operator)

    apply_gate!(ψ, Y_gate)
    
    ψ_result=Ket([
        0.0 - 5.0im,
        0.0 - 6.0im,
        0.0 - 7.0im,
        0.0 - 8.0im,
        0.0 + 1.0im,
        0.0 + 2.0im,
        0.0 + 3.0im,
        0.0 + 4.0im
    ])

    @test ψ ≈ ψ_result

    @test adjoint(y_operator) ≈ y_operator

end

@testset "AntiDiagonal Gate: sigma_p, sigma_m" begin

    @test typeof(sigma_p())==AntiDiagonalOperator{2,ComplexF64}
    @test typeof(sigma_m())==AntiDiagonalOperator{2,ComplexF64}

end