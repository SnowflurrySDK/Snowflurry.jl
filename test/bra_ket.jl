using Snowflake
using Test

@testset "simple_bra_ket" begin
    Ψ_0 = fock(1, 2)
    Ψ_1 = fock(2, 2)
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

@testset "multi_body" begin
    Ψ_up = fock(1, 2)
    Ψ_down = fock(2, 2)

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)

    qubit_count = 2
    hilber_space_size_per_qubit = 2
    system = MultiBodySystem(qubit_count, hilber_space_size_per_qubit)

    ##Single Qubit Gates for a single register
    h = hadamard(1)
    x = sigma_x(1)
    y = sigma_y(1)
    z = sigma_z(1)

    ##Get embedded operators
    target_qubit = 1
    H = get_embed_operator(h.operator, target_qubit, system)
    X = get_embed_operator(x.operator, target_qubit, system)
    Y = get_embed_operator(y.operator, target_qubit, system)
    Z = get_embed_operator(z.operator, target_qubit, system)

    Ψ_init = kron(Ψ_up, Ψ_up)

    # Bit-flip on qubit 1 
    @test (X * Ψ_init) ≈ kron(Ψ_down, Ψ_up)



end
