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

    Ψ_up = spin_up()
    Ψ_down = spin_down()

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

    Ψ_up = spin_up()
    Ψ_down = spin_down()

    Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)


    c = QuantumCircuit(qubit_count = 2, bit_count = 0)

    push_gate!(c, [hadamard(1), sigma_x(2)])
    push_gate!(c, [hadamard(2)])
    push_gate!(c, [control_x(1, 2)])
    ψ = simulate(c)

    @test ψ ≈ kron(Ψ_m, Ψ_m)
end

@testset "simulate_cz_gate" begin
    c = QuantumCircuit(qubit_count = 3, bit_count = 0)

    push_gate!(c, [sigma_x(1), sigma_x(3)])
    push_gate!(c, [control_z(3, 1)])
    returned_state = simulate(c)
    
    pop_gate!(c)
    push_gate!(c, sigma_z(1))
    expected_state = simulate(c)
    @test returned_state ≈ expected_state
end

@testset "simulate_cx_gate" begin
    c = QuantumCircuit(qubit_count = 3, bit_count = 0)

    push_gate!(c, sigma_x(3))
    push_gate!(c, [control_x(3, 1)])
    returned_state = simulate(c)
    
    pop_gate!(c)
    push_gate!(c, sigma_x(1))
    expected_state = simulate(c)
    @test returned_state ≈ expected_state
end

@testset "throw_if_gate_outside_circuit" begin
    c = QuantumCircuit(qubit_count = 2, bit_count = 0)
    @test_throws DomainError push_gate!(c, control_x(1, 3))
end
