using Snowflake
using Test

@testset "Rabi Flip Shrodinger" begin
    ψ_0 = spin_up()
    ω = 2.0*pi #Rabi frequency
    H = ω/2.0*sigma_x()
    t = 0.0:0.01:1.0
    ψ , prob = sesolve(H, ψ_0, t,e_ops=[sigma_z()])
    @test last(prob) ≈ 1.0 atol=1.e-4
end

@testset "Rabi Flip Shrodinger, ComplexF32" begin
    ψ_0 = spin_up(ComplexF32)
    ω = 2.0*pi #Rabi frequency
    H = ComplexF32(ω/2.0)*sigma_x(ComplexF32)
    t = 0.0:0.01:1.0
    ψ , prob = sesolve(H, ψ_0, t,e_ops=[sigma_z()])
    @test last(prob) ≈ 1.0 atol=1.e-4

    @test typeof(ψ)==Vector{Ket{ComplexF32}}
end

@testset "Master Equation" begin
    @testset "relaxation" begin
        function test_relaxation(dtype, Γ, t)
            Ψ_0 = spin_up(dtype)
            H = dtype(0)*sigma_x(dtype)
            projection = Ψ_0*Ψ_0'
            prob = mesolve(
                H,
                ket2dm(Ψ_0),
                t,
                c_ops=[sqrt(dtype(Γ))*sigma_m(dtype)],
                e_ops=[projection]
            )

            @test prob ≈ exp.(-Γ*collect(t)) atol=1.e-4
        end

        t = 0.0:0.01:2.0
        Γ = 0.5
        test_relaxation(ComplexF64, Γ, t)
        test_relaxation(ComplexF32, Γ, t)
    end

    @testset "equivalent to sesolve" begin
        function test_sesolve_rabi(dtype, ω, t)
            ψ_0 = spin_up(dtype)
            H = dtype(ω/2.0)*sigma_x(dtype)
            e_ops = [sigma_z(dtype)]
            ψ_sesolve , prob_sesolve = sesolve(H, ψ_0, t,e_ops=e_ops)

            ρ_0 = ket2dm(ψ_0)
            c_ops = Vector{DenseOperator{2, dtype}}([])
            prob_mesolve = mesolve(H, ρ_0, t, e_ops=e_ops, c_ops=c_ops)

            @test prob_sesolve ≈ prob_mesolve
        end

        ω = 2.0 * pi
        t = 0.0:0.01:1.0
        test_sesolve_rabi(ComplexF64, ω, t)
        test_sesolve_rabi(ComplexF32, ω, t)
    end
end
