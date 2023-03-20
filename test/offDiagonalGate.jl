using Snowflake
using Test

@testset "OffDiagonal Gate: SigmaY" begin

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
end