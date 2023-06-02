using Snowflake
using Test

@testset "Rabi Flip Shrodinger" begin
    function test_sesolve_rabi(dtype; is_hamiltonian_static::Bool)
        ψ_0 =  spin_up(dtype)
        ω = 2.0*pi #Rabi frequency
        H(t) = dtype(ω/2.0)*(sigma_x(dtype))
        tspan = (0.0,1.0)
        e_ops=[sigma_z(dtype)]
        problem = ShrodingerProblem(H=H , init_state=ψ_0, tspan=tspan, e_ops=e_ops)
        t, ψ , prob = sesolve(problem, is_hamiltonian_static=is_hamiltonian_static)
        @test last(prob) ≈ 1.0 atol=1.e-4
        @test typeof(ψ)==Vector{Ket{dtype}}
    end
    test_sesolve_rabi(ComplexF64, is_hamiltonian_static=false)
    test_sesolve_rabi(ComplexF64, is_hamiltonian_static=true)
    test_sesolve_rabi(ComplexF32, is_hamiltonian_static=true)
end


@testset "Master Equation" begin
    @testset "relaxation" begin
        function test_relaxation(dtype)
            tspan = (0.0,1.0)
            Γ = 0.5
            Ψ_0 = spin_up(dtype)
            H(t) = DenseOperator(dtype(0.0)*sigma_x(dtype))
            projection = Ψ_0*Ψ_0'
            ρ_0=ket2dm(Ψ_0)
            c_op =DenseOperator(sqrt(dtype(Γ))*sigma_m(dtype))

            problem=LindbladProblem(H=H,init_state=ρ_0, tspan=tspan, e_ops=[projection], c_ops=[c_op])
            t, ρ, prob = mesolve(problem)
            @test prob ≈ exp.(-Γ*collect(t)) atol=1.e-4

            problem=LindbladProblem(H=H,init_state=ρ_0, tspan=tspan, e_ops=[projection], c_ops=(DenseOperator{2,dtype})[])
            @test_throws DomainError mesolve(problem)
        end
        test_relaxation(ComplexF64)
        test_relaxation(ComplexF32)
    end


end

#     @testset "equivalent to sesolve" begin
#         function test_sesolve_rabi(dtype, ω, t)
#             ψ_0 = spin_up(dtype)
#             H(t) = DenseOperator(dtype(ω/2.0)*sigma_x(dtype))
#             e_ops = [DenseOperator(sigma_z(dtype))]
#             t_, ψ, prob_sesolve = sesolve_eops(H, ψ_0, t,e_ops=e_ops, dt=0.1, adaptive=false)

#             ρ_0 = ket2dm(ψ_0)
#             c_ops = Vector{DenseOperator{2, dtype}}([])
#             t_, ρ, prob_mesolve = mesolve_eops(H, ρ_0, t, e_ops=e_ops, c_ops=c_ops, dt=0.1, adaptive=false)

#             @test prob_sesolve ≈ prob_mesolve  atol=1.e-3
#         end

#         ω = 2.0 * pi
#         t = (0.0,1.0)
#         test_sesolve_rabi(ComplexF64, ω, t)
#         test_sesolve_rabi(ComplexF32, ω, t)
#     end

# end
