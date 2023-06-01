using Snowflake
using Test

@testset "Rabi Flip Shrodinger" begin
    ψ_0 = spin_up()
    ω = 2.0*pi #Rabi frequency
    H = ω/2.0*sigma_x()
    tspan = (0.0,1.0)
    t, ψ , prob = sesolve_eops(H, ψ_0, tspan,e_ops=[sigma_z()])
    @test last(prob) ≈ 1.0 atol=1.e-4
end

@testset "Rabi Flip Shrodinger, ComplexF32" begin
    ψ_0 = spin_up(ComplexF32)
    ω = 2.0*pi #Rabi frequency
    H = ComplexF32(ω/2.0)*sigma_x(ComplexF32)
    tspan = (0.0,1.0)
    t, ψ , prob = sesolve_eops(H, ψ_0, tspan,e_ops=[sigma_z()])
    @test last(prob) ≈ 1.0 atol=1.e-4
    @test typeof(ψ)==Vector{Ket{ComplexF32}}
end

@testset "Master Equation" begin
    @testset "relaxation" begin
        function test_relaxation(dtype, Γ, t)
            Ψ_0 = spin_up(dtype)
            H(t) = DenseOperator(dtype(0.0)*sigma_x(dtype))
            projection = Ψ_0*Ψ_0'
            ρ_0=ket2dm(Ψ_0)
            c_op =DenseOperator(sqrt(dtype(Γ))*sigma_m(dtype))
            t_, ρ, prob = mesolve_eops(H,ρ_0, t,  c_ops=[DenseOperator(c_op)], e_ops=[projection])
            @test prob ≈ exp.(-Γ*collect(t_)) atol=1.e-4
        end

        t = (0.0,1.0)
        Γ = 0.5
        test_relaxation(ComplexF64, Γ, t)
        test_relaxation(ComplexF32, Γ, t)
    end
end
