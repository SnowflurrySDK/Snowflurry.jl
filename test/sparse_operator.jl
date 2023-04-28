using Snowflake
using Test

@testset "SparseOperator" begin
    σ_z=SparseOperator([1.0 0.0;0.0 -1.0])
    σ_y=SparseOperator([0.0 -im;im 0.0])
    σ_x=sparse(sigma_x())
    I=sparse(eye())
    @test σ_z  ≈ sparse(sigma_z())
    @test σ_y  ≈ sparse(sigma_y())
    @test σ_z*σ_z  ≈ I
    ψ=spin_up()
    @test σ_x*ψ ≈ spin_down()
    #testing matrix multplication as well as scalar multiplication by a sparse operator
    @test σ_x*σ_y ≈ im*σ_z
    @test commute(σ_x,σ_y) ≈ 2.0im*σ_z
    @test commute(σ_y,σ_z) ≈ 2.0im*σ_x
    @test commute(σ_z,σ_x) ≈ 2.0im*σ_y
    @test anticommute(σ_x,σ_x) ≈ 2.0*I
    vals, vecs = eigen(kron(σ_z,I), nev=2, which=:SR) #give eigenvalues with smallest real part
    @test vals[1] ≈ -1.0
    @test vals[2] ≈ -1.0 

    A=SparseOperator([1.0 2.0-im;-im 3])
    A_dag=SparseOperator([1.0 im;2.0+im 3])

    @test adjoint(A) ≈ A_dag

    @test expected_value(σ_z,spin_up()) ≈ Complex(1.0)
    @test expected_value(σ_z,spin_down()) ≈ Complex(-1.0)

    @test kron(σ_x,σ_y) ≈ sparse(kron(sigma_x(),sigma_y()))

    @test is_hermitian(σ_x)

    println(σ_x)  #test "show" function
end