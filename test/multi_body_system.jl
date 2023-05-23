using Snowflake
using Test

@testset "multi_body" begin
    Ψ_up = fock(0, 2)
    Ψ_down = fock(1, 2)

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)

    qubit_count = 2
    hilber_space_size_per_qubit = 2
    system = MultiBodySystem(qubit_count, hilber_space_size_per_qubit)
    println(system)

    ##Single Qubit Gates for a single register
    h = hadamard(1)
    x = sigma_x(1)
    y = sigma_y(1)
    z = sigma_z(1)

    ##Get embedded operators
    target_qubit = 1
    H = get_embed_operator(get_operator(h), target_qubit, system)
    X = get_embed_operator(get_operator(x), target_qubit, system)
    Y = get_embed_operator(get_operator(y), target_qubit, system)
    Z = get_embed_operator(get_operator(z), target_qubit, system)

    Ψ_init = kron(Ψ_up, Ψ_up)

    # Bit-flip on qubit 1 
    @test (X * Ψ_init) ≈ kron(Ψ_down, Ψ_up)
end


