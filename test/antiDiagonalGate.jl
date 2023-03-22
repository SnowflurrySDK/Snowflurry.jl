using Snowflake
using Test

include("testFunctions.jl")

test_operator_implementation(AntiDiagonalOperator,dim=1,label="AntiDiagonalOperator")

@testset "AntiDiagonalOperator" begin

    anti_diag_op=AntiDiagonalOperator([1,2,3,4])

    #kron
    composite_op=kron(anti_diag_op,eye())

    @test composite_op[1,1]==anti_diag_op[1,1]
    @test composite_op[2,2]==anti_diag_op[1,1]
    @test composite_op[1,2]==ComplexF64(0.)
    @test composite_op[3,3]≈ anti_diag_op[2,2]
    @test composite_op[4,4]≈ anti_diag_op[2,2]

    composite_op=kron(eye(),anti_diag_op)

    @test composite_op[1,1]==anti_diag_op[1,1]
    @test composite_op[2,2]==anti_diag_op[2,2]
    @test composite_op[1,2]==ComplexF64(0.)
    @test composite_op[3,3]≈ anti_diag_op[1,1]
    @test composite_op[4,4]≈ anti_diag_op[2,2]

    # Base.:* 

    anti_diag_op=AntiDiagonalOperator(make_array(1, Int64))

    result=DiagonalOperator(
        [a*b for (a,b) in zip(
            Vector(anti_diag_op.data),
            Vector(reverse(anti_diag_op.data)
            ))
        ])

    @test anti_diag_op*anti_diag_op≈ result
    @test Operator(anti_diag_op)*anti_diag_op≈ result
    @test anti_diag_op*Operator(anti_diag_op)≈ result
    
    # Exponentiation
    θ=π 
    anti_diag_op=AntiDiagonalOperator([1,1])
    @test (exp(-im*θ/2*anti_diag_op)).data ≈ [[0.,-im] [-im,0.]]

    # LinearAlgebra.eigen
    vals, vecs = eigen(anti_diag_op)
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

    @test adjoint(y_operator).data==ComplexF64[im,-im]

end