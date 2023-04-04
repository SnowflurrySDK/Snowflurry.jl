using Snowflake
using Test
using Plots

@testset "Rabi Flip Shrodinger" begin
    ψ_0 = spin_up()
    ω = 2.0*pi #Rabi frequency
    H = ω/2.0*sigma_x()
    t = 0.0:0.01:1.0
    ψ , prob = sesolve(H, ψ_0, t,e_ops=[sigma_z()])
    @test last(prob) ≈ 1.0 atol=1.e-4
end

@testset "Master Equation: relaxation" begin
    ψ_0 = spin_up()
    ω = 0.0*pi #Rabi frequency
    H = ω/2.0*sigma_x()
    T = 2.0
    t = 0.0:0.001:T
    #master equation solver
    projection = ψ_0*ψ_0'
    Γ = 0.05  #relaxation rate
    prob = mesolve(H, ket2dm(ψ_0), t, c_ops=[sqrt(Γ)*sigma_m()], e_ops=[projection])
    @test last(prob) ≈ exp(-Γ*T) atol=1.e-4
end
