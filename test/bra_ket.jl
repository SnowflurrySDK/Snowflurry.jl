using Snowflake
using Test

@testset "ket" begin
    Ψ_0 = fock(2, 1)
    Ψ_1 = fock(2, 2)
    
    Ψ_p = (1. / sqrt(2.0)) * (Ψ_0 + Ψ_1)
    Ψ_m = (1. / sqrt(2.0)) * (Ψ_0 - Ψ_1)

    _Ψ = Bra(Ψ_p)

    H = hadamard(1)
    X = sigma_x(1)
    Y = sigma_y(1)
    Z = sigma_z(1)

    # Test amplitude is unity
    @test (_Ψ * Ψ_p) ≈ Complex(1.0)
    
    # Hadamard gate on a single qubit
    @test H * Ψ_0 ≈ Ψ_p
    @test H * Ψ_1 ≈ Ψ_m

    # Bit flip gate (sigma_x)
    @test X * Ψ_0 ≈ Ψ_1
    @test X * Ψ_1 ≈ Ψ_0

    # Z gate
    @test Z * Ψ_0 ≈ Ψ_0
    @test Z * Ψ_1 ≈ -Ψ_1


end

@testset "multi_body" begin
    Ψ_up = fock(2, 1)
    Ψ_down = fock(2, 2)
    
    Ψ_p = (1. / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1. / sqrt(2.0)) * (Ψ_up - Ψ_down)

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
    H = getEmbedOperator(h.operator, target_qubit, system)
    X = getEmbedOperator(x.operator, target_qubit, system)
    Y = getEmbedOperator(y.operator, target_qubit, system)
    Z = getEmbedOperator(z.operator, target_qubit, system)
    
    Ψ_init = kron(Ψ_up, Ψ_up)
    
    # Bit-flip on qubit 1 
    @test (X * Ψ_init) ≈ kron(Ψ_down, Ψ_up)
    


end