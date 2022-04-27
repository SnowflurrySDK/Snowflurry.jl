using Snowflake
using Test

@testset "push_pop_gate" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [hadamard(1)])
    @test length(c.pipeline) == 1


    push_gate!(c, [control_x(1, 2)])
    @test length(c.pipeline) == 2
    pop_gate!(c)
    @test length(c.pipeline) == 1

    push_gate!(c, control_x(1, 2))
    @test length(c.pipeline) == 2

    plot_histogram(c,100)

    print(c)
end


@testset "bellstate" begin

    Ψ_up = fock(0, 2)
    Ψ_down = fock(1, 2)

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    push_gate!(c, [hadamard(1)])
    push_gate!(c, [control_x(1, 2)])
    ψ = simulate(c)
    @test ψ ≈ 1 / sqrt(2.0) * (kron(Ψ_up, Ψ_up) + kron(Ψ_down, Ψ_down))

    readings = simulate_shots(c, 101)
    @test ("00" in readings)
    @test ("11" in readings)
    @test ~("10" in readings)
    @test ~("01" in readings)
end

@testset "phase_kickback" begin

    Ψ_up = fock(0, 2)  # ket{0}
    Ψ_down = fock(1, 2) # ket{1}

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)


    c = QuantumCircuit(qubit_count = 2, bit_count = 0)

    push_gate!(c, [hadamard(1), sigma_x(2)])
    push_gate!(c, [hadamard(2)])
    push_gate!(c, [control_x(1, 2)])
    ψ = simulate(c)

    @test ψ ≈ kron(Ψ_m, Ψ_m)
end
