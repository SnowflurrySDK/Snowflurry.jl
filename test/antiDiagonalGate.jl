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