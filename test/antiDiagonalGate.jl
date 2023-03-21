using Snowflake
using Test

@testset "AntiDiagonalOperator" begin
    
    # Constructor from Integer-valued Vector
    anti_diag_op=AntiDiagonalOperator([1,2,3,4])

    @test anti_diag_op.data==ComplexF64[1.,2.,3.,4.]

    # Constructor from Integer-valued Vector, specifying ComplexF32
    anti_diag_op=AntiDiagonalOperator([1,2,3,4],ComplexF32)

    @test anti_diag_op.data==ComplexF32[1.,2.,3.,4.]
    @test anti_diag_op.data[1]===ComplexF32(1.)

    # Constructor from Real-valued Vector
    anti_diag_op=AntiDiagonalOperator([1.,2.,3.,4.])
    @test anti_diag_op.data==ComplexF64[1.,2.,3.,4.]

    # Constructor from Complex-valued Vector
    anti_diag_op=AntiDiagonalOperator(ComplexF64[1.,2.,3.,4.])
    @test anti_diag_op.data==ComplexF64[1.,2.,3.,4.]

    # Constructor from adjoint(AntiDiagonalOperator{T})
    anti_diag_op=AntiDiagonalOperator(
        ComplexF64[
            1.0+im,
            2.0+im,
            3.0+im,
            4.0+im])

    adjoint_anti_diag_op=adjoint(anti_diag_op)

    @test adjoint_anti_diag_op.data==ComplexF64[
        1.0-im,
        2.0-im,
        3.0-im,
        4.0-im]


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

    # Cast to Operator
    @test Operator(anti_diag_op) ≈ anti_diag_op

    sum_anti_diag_op=anti_diag_op+anti_diag_op
    @test sum_anti_diag_op≈ 2*anti_diag_op
    @test sum_anti_diag_op≈ Operator(anti_diag_op)+anti_diag_op
    @test sum_anti_diag_op≈ anti_diag_op+Operator(anti_diag_op)
         
    anti_diag_op_2=AntiDiagonalOperator(
        ComplexF64[
            2.0+2im,
            4.0+2im,
            6.0+2im,
            8.0+2im])

    diff_anti_diag_op=sum_anti_diag_op-anti_diag_op
    @test diff_anti_diag_op ≈ anti_diag_op

    diff_anti_diag_op=anti_diag_op_2-anti_diag_op
    @test Operator(anti_diag_op)≈ diff_anti_diag_op

    # Base.:+ and Base.:- 

    @test (2*anti_diag_op).data == (anti_diag_op + anti_diag_op).data
    @test 2*anti_diag_op ≈ anti_diag_op + Operator(anti_diag_op)
    @test 2*anti_diag_op ≈ Operator(anti_diag_op) + anti_diag_op

    @test anti_diag_op.data == (2*anti_diag_op - anti_diag_op).data
    @test Operator(anti_diag_op) ≈ 2*anti_diag_op - Operator(anti_diag_op)
    @test Operator(anti_diag_op) ≈ 2*Operator(anti_diag_op) - anti_diag_op

    # Base.:*

    result=DiagonalOperator(
        [a*b for (a,b) in zip(
            Vector(anti_diag_op.data),
            Vector(reverse(anti_diag_op.data)
            ))
        ])

    @test anti_diag_op*anti_diag_op≈ result
    @test Operator(anti_diag_op)*anti_diag_op≈ result
    @test anti_diag_op*Operator(anti_diag_op)≈ result
    
    # Commutation relations
    
    result=anti_diag_op*anti_diag_op-anti_diag_op*anti_diag_op

    @test commute(anti_diag_op,anti_diag_op)  ≈ result
    @test commute(anti_diag_op,Operator(anti_diag_op))  ≈ result
    @test commute(Operator(anti_diag_op),(anti_diag_op))≈ result

    result= anti_diag_op*anti_diag_op+anti_diag_op*anti_diag_op

    @test anticommute(anti_diag_op,anti_diag_op)  ≈ result
    @test anticommute(anti_diag_op,Operator(anti_diag_op))  ≈ result
    @test anticommute(Operator(anti_diag_op),(anti_diag_op))≈ result

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