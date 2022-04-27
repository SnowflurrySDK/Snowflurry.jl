using Snowflake
using Test

@testset "simple_bra_ket" begin
    Ψ_0 = fock(0, 2)
    Ψ_1 = fock(1, 2)
    print(Ψ_0)

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_0 + Ψ_1)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_0 - Ψ_1)
    _Ψ = Bra(Ψ_p)

    # test if adjoin operations work properly
    @test adjoint(Ψ_p) ≈ Bra(Ψ_p)
    @test adjoint(_Ψ) ≈ Ψ_p
    # Test amplitude is unity
    @test (_Ψ * Ψ_p) ≈ Complex(1.0)


    M_0 = Ψ_0 * Bra(Ψ_0)
    @test size(M_0) == (2, 2)

    H = hadamard(1)
    X = sigma_x(1)
    Y = sigma_y(1)
    Z = sigma_z(1)

    # Hadamard gate on a single qubit
    @test H * Ψ_0 ≈ Ψ_p
    @test H * Ψ_1 ≈ Ψ_m



    # Bit flip gate (sigma_x)
    @test X * Ψ_0 ≈ Ψ_1
    @test X * Ψ_1 ≈ Ψ_0
    @test (Bra(Ψ_1) * X.operator) * Ψ_0 ≈ Complex(1.0)

    # Z gate
    @test Z * Ψ_0 ≈ Ψ_0
    @test Z * Ψ_1 ≈ -Ψ_1


end

@testset "pauli_operators" begin
    x = sigma_x()
    z = sigma_z()
    y = sigma_y()
    @test x[1,1] ≈ 0.0
    @test x[1,2] ≈ 1.0
    @test y ≈ 1.0im*x*z
    #commutation relations
    @test commute(x,y) ≈ 2.0im*z
    @test commute(y,z) ≈ 2.0im*x
    @test commute(z,x) ≈ 2.0im*y
    @test anticommute(x,x) ≈ 2.0*eye()

    vals, vecs = Snowflake.eigen(z)
    @test vals[1] ≈ -1.0
    @test vals[2] ≈ 1.0 
    

end


@testset "fock_space" begin
   hspace_size = 8
    a_dag = create(hspace_size)
    a = destroy(hspace_size)
    n = number_op(hspace_size)
    #adding a photon to a photon number base vector
    @test a_dag*fock(3,hspace_size) ≈ sqrt(4.0)*fock(4,hspace_size)
    #subtracting a photon
    @test a*fock(3,hspace_size) ≈ sqrt(3.0)*fock(2,hspace_size)
    @test expected_value(n,fock(3,hspace_size))==3

    
end

@testset "density_matrix" begin
    Ψ_0 = fock(1, 2)
    @test ket2dm(Ψ_0) ≈ (Ψ_0*Bra(Ψ_0))
    @test fock_dm(1,2) ≈ (Ψ_0*Bra(Ψ_0))
end

@testset "coherent state" begin
    @test coherent(0.25im, 5) ≈ Ket([0.969233234, 0.0 + 0.2423083086190im, -0.042834462040, -0.006182622047433im,7.7282775592e-4]) atol=1.0e-4
end

@testset "cat states" begin
    alpha = 0.25
    hspace_size=8
    ψ_0 = normalize!(coherent(alpha, hspace_size)+coherent(-alpha,hspace_size))
    ψ_1 = normalize!(coherent(alpha, hspace_size)-coherent(-alpha,hspace_size))

    @test Bra(ψ_0)*ψ_1 ≈ 0.0
    @test wigner(ket2dm(ψ_0),0.0,0.0) ≈ -0.636619772367581382432888403855 atol=1.0e-4
    p=q=-3.0:0.1:3
    viz_wigner(ket2dm(ψ_0),p,q)
end