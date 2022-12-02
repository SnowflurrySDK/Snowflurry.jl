using Snowflake
using Test

@testset "simple_bra_ket" begin
    Ψ_0 = spin_up()
    Ψ_1 = spin_down()
    print(Ψ_0)

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_0 + Ψ_1)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_0 - Ψ_1)
    _Ψ = Bra(Ψ_p)

    # test if adjoin operations work properly
    @test adjoint(Ψ_p) ≈ Bra(Ψ_p)
    @test adjoint(_Ψ) ≈ Ψ_p
    # Test amplitude is unity
    @test (_Ψ * Ψ_p) ≈ Complex(1.0)

    @test get_num_qubits(_Ψ) == 1
    @test get_num_bodies(Ket([1.0, 0.0, 0.0]), 3) == 1

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
    
    xy = kron(x, y)
    @test get_num_qubits(xy) == 2
end

@testset "operator_exceptions" begin
    not_square = Operator(zeros(1, 2))
    @test_throws ErrorException get_num_qubits(not_square)
    @test_throws ErrorException get_num_bodies(not_square)

    non_integer_qubits = Operator(zeros(3, 3))
    @test_throws DomainError get_num_qubits(non_integer_qubits)

    non_integer_qutrit = Operator(zeros(2, 2))
    @test_throws DomainError get_num_bodies(non_integer_qutrit, 3)
end

@testset "ket_exceptions" begin
    non_integer_qubits = Ket(zeros(3))
    @test_throws DomainError get_num_qubits(non_integer_qubits)

    non_integer_qutrit = Bra(Ket(zeros(2)))
    @test_throws DomainError get_num_bodies(non_integer_qutrit, 3)
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

    plot_bloch_sphere(Ψ_0)
    plot_bloch_sphere(ket2dm(Ψ_0))

    Ψ_1 = Ket([1/sqrt(2), -0.5+0.5im])
    Ψ_2 = Ket([1/sqrt(2), -0.5-0.5im])
    plot_bloch_sphere_animation([Ψ_1, Ψ_2, Ψ_1])
    plot_bloch_sphere_animation([ket2dm(Ψ_1), ket2dm(Ψ_0)])
end

@testset "coherent state" begin
    ψ = Snowflake.coherent(2.0,20)
    @test expected_value(number_op(20),ψ) ≈ 4.0 atol=1.0e-4
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

@testset "qutrit_operators" begin
    hilbert_space_size_per_qutrit = 3
    qutrit_operator = Operator([1 0 0;
                                0 1 0
                                0 0 1])
    @test get_num_bodies(kron(qutrit_operator, qutrit_operator),
        hilbert_space_size_per_qutrit) == 2
end

@testset "ishermitian" begin
    @test ishermitian(sigma_y())
    @test !ishermitian(sigma_p())
end