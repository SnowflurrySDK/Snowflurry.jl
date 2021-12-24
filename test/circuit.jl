using Snowflake
using Test

@testset "cnot" begin
    
    Ψ_up = fock(2, 1)
    Ψ_down = fock(2, 2)
   
    Ψ_p = (1. / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1. / sqrt(2.0)) * (Ψ_up - Ψ_down)
    c = Circuit(qubit_count=2, bit_count=0)
    pushGate!(c, [hadamard(1)])
    pushGate!(c, [control_x(1, 2)])
    ψ = simulate(c)
    @test ψ ≈ 1 / sqrt(2.) * (kron(Ψ_up, Ψ_up) + kron(Ψ_down, Ψ_down))
end

@testset "phase_kickback" begin
    
    Ψ_up = fock(2, 1)  # ket{0}
    Ψ_down = fock(2, 2) # ket{1}
   
    Ψ_p = (1. / sqrt(2.0)) * (Ψ_up + Ψ_down)
    Ψ_m = (1. / sqrt(2.0)) * (Ψ_up - Ψ_down)


    c = Circuit(qubit_count=2, bit_count=0)
    
    pushGate!(c, [hadamard(1), sigma_x(2)])
    pushGate!(c, [hadamard(2)])
    pushGate!(c, [control_x(1, 2)])
    ψ = simulate(c)
    
    @test ψ ≈ kron(Ψ_m, Ψ_m)
end

