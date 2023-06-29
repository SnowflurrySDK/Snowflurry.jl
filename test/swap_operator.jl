using Snowflurry
using Test
using StaticArrays

include("test_functions.jl")

test_operator_implementation(SwapLikeOperator,dim=nothing,label="SwapOperator")

@testset "SwapLikeOperator" begin

    sw=iswap(1,2)
    println(sw)

    @test SwapLikeOperator(im)≈get_operator(get_gate_symbol(sw))
    @test SwapLikeOperator(0.0 + 1.0im)≈get_operator(get_gate_symbol(sw))
    @test SwapLikeOperator(Complex(1))≈get_operator(get_gate_symbol(swap(1,2)))

    sum_op=swap()+iswap()

    test_sum=DenseOperator(
        ComplexF64[[2.0, 0.0, 0.0, 0.0] [0.0, 0.0, 1.0+im, 0.0] [0.0, 1.0+im, 0.0, 0.0] [0.0, 0.0, 0.0, 2.0]])

    @test test_sum≈sum_op

    null_op=DenseOperator(zeros(ComplexF64,4,4))

    diff_op=swap()-swap()

    @test diff_op≈null_op

    test_approx=DenseOperator(
        ComplexF64[[1.0, 0.0, 0.0, 0.0] [0.0, 0.0, im, 0.0] [0.0, im, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0]])

    @test iswap()≈test_approx

end
