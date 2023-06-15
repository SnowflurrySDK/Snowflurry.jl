using Snowflake
using Test

#coverage of printouts
dtype=ComplexF64
ψ_0 =  spin_up(dtype)
ω = 2.0*pi #Rabi frequency
H(t) = dtype(ω/2.0)*(sigma_x(dtype))
t_span = (0.0,1.0)
e_ops=[sigma_z(dtype)]
problem = ShrodingerProblem(H=H , init_state=ψ_0, t_span=t_span, e_ops=e_ops)
println(problem)

Γ = 0.5
Ψ_0 = spin_up(dtype)
H(t) = DenseOperator(dtype(0.0)*sigma_x(dtype))
projection = Ψ_0*Ψ_0'
ρ_0=ket2dm(Ψ_0)
c_op =DenseOperator(sqrt(dtype(Γ))*sigma_m(dtype))
problem=LindbladProblem(H=H,init_state=ρ_0, t_span=t_span, e_ops=[projection], c_ops=[c_op])
println(problem)


@testset "Rabi Flip Shrodinger" begin
    function test_sesolve_rabi(dtype; is_hamiltonian_static::Bool)
        ψ_0 =  spin_up(dtype)
        ω = 2.0*pi #Rabi frequency
        H(t) = dtype(ω/2.0)*(sigma_x(dtype))
        t_span = (0.0,1.0)
        e_ops=[sigma_z(dtype)]
        problem = ShrodingerProblem(H=H , init_state=ψ_0, t_span=t_span, e_ops=e_ops)
        t, ψ , prob = sesolve(problem, is_hamiltonian_static=is_hamiltonian_static)
        @test last(prob) ≈ 1.0 atol=1.e-4
        @test typeof(ψ[1])==Ket{dtype}
    end
    test_sesolve_rabi(ComplexF64, is_hamiltonian_static=false)
    test_sesolve_rabi(ComplexF64, is_hamiltonian_static=true)
    test_sesolve_rabi(ComplexF32, is_hamiltonian_static=true)
end

function test_relaxation(dtype, t_integ=nothing)
    t_span = (0.0,1.0)
    Γ = 0.5
    Ψ_0 = spin_up(dtype)
    H(t) = DenseOperator(dtype(0.0)*sigma_x(dtype))
    projection = Ψ_0*Ψ_0'
    ρ_0=ket2dm(Ψ_0)
    c_op =DenseOperator(sqrt(dtype(Γ))*sigma_m(dtype))

    if isnothing(t_integ)
        #test without t_integ arg, using default []
        problem=LindbladProblem(H=H,init_state=ρ_0, t_span=t_span, e_ops=[projection], c_ops=[c_op])
    else
        problem=LindbladProblem(H=H,init_state=ρ_0, t_span=t_span, e_ops=[projection], c_ops=[c_op],t_integ=t_integ)
    end
    t, ρ, probability = lindblad_solve(problem)
    @test probability ≈ exp.(-Γ*t) atol=1.e-4
    @test typeof(ρ[1])==DenseOperator{2,dtype}

    if !isnothing(t_integ) && length(t_integ)>0
        @test length(t)==length(t_integ)
    end

    problem=LindbladProblem(H=H,init_state=ρ_0, t_span=t_span, e_ops=[projection], c_ops=(DenseOperator{2,dtype})[])
    @test_throws DomainError lindblad_solve(problem)
end

@testset "Master Equation:relaxation" begin
    test_relaxation(ComplexF64)
    test_relaxation(ComplexF32)
end

@testset "Master Equation:relaxation, range integrator" begin
    test_relaxation(ComplexF64,range(0.,stop=1., length=15))
    test_relaxation(ComplexF32,range(0.,stop=1., length=15))
end

@testset "Master Equation:relaxation, array integrator" begin
    test_relaxation(ComplexF64,[0.0,0.02,0.04,0.3,0.6,0.9])
    test_relaxation(ComplexF32,[0.0,0.02,0.04,0.3,0.6,0.9])

    # empty array reverts to nothing internally
    test_relaxation(ComplexF64,Vector{Float64}())

    # t_integ exceeds t_span
    @test_throws AssertionError test_relaxation(ComplexF64,[-100.,  1.])
    @test_throws AssertionError test_relaxation(ComplexF64,[   0.,100.])
    @test_throws AssertionError test_relaxation(ComplexF64,[-100.,100.])

end



@testset "Master Equation:relaxation AbstractOperator" begin
    function test_relaxation(dtype)
        t_span = (0.0,1.0)
        Γ = 0.5
        Ψ_0 = spin_up(dtype)
        H(t) = DenseOperator(dtype(0.0)*sigma_x(dtype))
        projection = DiagonalOperator(dtype[1.,0.])
        ρ_0=ket2dm(Ψ_0)
        c_op_anti_diag=AntiDiagonalOperator(dtype[0.,sqrt(2.)/2.])

        problem=LindbladProblem(H=H,init_state=ρ_0, t_span=t_span, e_ops=[projection], c_ops=[c_op_anti_diag])
        t, ρ, probability = lindblad_solve(problem)
        @test probability ≈ exp.(-Γ*t) atol=1.e-4
    end
    test_relaxation(ComplexF64)
    test_relaxation(ComplexF32)
end
