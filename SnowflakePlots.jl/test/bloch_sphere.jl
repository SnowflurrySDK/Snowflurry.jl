using SnowflakePlots
using Snowflake
using Test

@testset "plot_bloch_sphere_for_circuit" begin
    c = QuantumCircuit(qubit_count=1)
    push!(c, [hadamard(1)])
    plot_bloch_sphere(c)
end

@testset "plot_bloch_sphere_for_density_matrices" begin
    Ψ_0 = fock(1, 2)
    plot_bloch_sphere(Ψ_0)
    plot_bloch_sphere(ket2dm(Ψ_0))

    Ψ_1 = Ket([1/sqrt(2), -0.5+0.5im])
    Ψ_2 = Ket([1/sqrt(2), -0.5-0.5im])
    plot_bloch_sphere_animation([Ψ_1, Ψ_2, Ψ_1])
    plot_bloch_sphere_animation([Ψ_2, Ψ_1, Ψ_2])
    plot_bloch_sphere_animation([ket2dm(Ψ_1), ket2dm(Ψ_0)])
end
