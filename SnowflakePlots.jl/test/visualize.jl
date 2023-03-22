using SnowflakePlots
using Test

@testset "plot_histogram" begin
    c = QuantumCircuit(qubit_count = 2)
    push!(c, [hadamard(1)])
    push!(c, [control_x(1, 2)])
    plot_histogram(c,100)
end

@testset "viz_wigner" begin
    alpha = 0.25
    hspace_size=8
    ψ_0 = normalize!(coherent(alpha, hspace_size)+coherent(-alpha,hspace_size))
    p=q=-3.0:0.1:3
    viz_wigner(ket2dm(ψ_0),p,q)
end