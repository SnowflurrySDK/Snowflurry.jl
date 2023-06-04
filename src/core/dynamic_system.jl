
"""
    ShrodingerProblem is a structure that is defined to solve the shrodinger equation in time-domain using sesolve(). 

**Fields**
- `H` -- a function that retrurns the  Hamiltonian operator (of any subtype of `AbstractOperator`) as a function of time.
- `init_state` -- initital state (`Ket`) of a quantum system
- `tspan` -- time interval for which the system has to be simulated. 
        For instance: 
            tspan=(0.0,1.0) evaluates the output from t=0.0 to t=1.0
- `e_ops` -- list of operators for which the expected value 
    (the observables) will be evaluated at each time step in t_range. 

"""
Base.@kwdef struct ShrodingerProblem{T<:AbstractOperator, S<:Complex}
    H::Function
    init_state::Ket{S}
    tspan::Tuple{Float64,Float64}
    e_ops::Vector{T}
end

"""
    A LindbladProblem is a structure that is defined to solve the Lindblad master equation in time-domain using lindblad_solve(). 

**Fields**
- `H` -- a function that retrurns the  Hamiltonian operator (of any subtype of `AbstractOperator`) as a function of time.
- `init_state` -- initital state density matrix (`DenseOperator`) of a quantum system
- `tspan` -- time interval for which the system has to be simulated. 
        For instance: 
            tspan=(0.0,1.0) evaluates the output from t=0.0 to t=1.0
- `e_ops` -- list of operators (type DenseOperator) for which the expected value 
    (the observables) will be evaluated at each time step in t_range. 

- `c_ops` -- list of collapse operators (type DenseOperator). 
"""
Base.@kwdef struct LindbladProblem{T<:DenseOperator}
    H::Function
    init_state::T
    tspan::Tuple{Float64,Float64}
    e_ops::Vector{T}
    c_ops::Vector{T}
end

"""
    sesolve(problem::ShrodingerProblem; kwargs...)
Solves the Shrodinger equation:

``\\frac{d \\Psi}{d t}=-i \\hat{H}\\Psi``

and returns a tuple correponding the time instance vector, the corresponding wavefunction Ket, and a Vector of observables evaluated at each time step. 

**Fields**
- `problem` -- An object of type ShrodingerProblem that defines the problem to be solved. 
- `is_hamiltonian_static` -- A Bool variable indicating whether the Hamiltonian operator changes with time or not. Default value is false. If true, the solver can have significant performance boost.
- `kwargs` -- list of keyword arguments to be passed to the ODE solver. See (https://docs.sciml.ai/DiffEqDocs/stable/basics/common_solver_opts/#solver_options).
"""
function sesolve(
    problem::ShrodingerProblem;
    is_hamiltonian_static::Bool = false,
    kwargs...
)
        
        dψ_dt_0 = -im*sparse(problem.H(0)).data
        function Hamiltonian!(dψ_v,ψ_v,p,t)
            if (is_hamiltonian_static)
                mul!(dψ_v,dψ_dt_0,ψ_v)
            else
                mul!(dψ_v,sparse(-im*problem.H(t)).data,ψ_v)
            end
            nothing
        end
        prob = OrdinaryDiffEq.ODEProblem(Hamiltonian!,problem.init_state.data,problem.tspan)
        sol=OrdinaryDiffEq.solve(prob,OrdinaryDiffEq.AutoTsit5(OrdinaryDiffEq.Rosenbrock23(autodiff=false));kwargs...) #The default algo is Tsit5 but we switch to Rosenbrock23 for stiff problems
        y=Vector{typeof(problem.init_state)}()
        for v in sol.u
            push!(y,Ket(v))
        end
        
        n_t = length(sol.t)
        n_o = length(problem.e_ops)
        observable=zeros(n_t, n_o) 
        for iob in 1:n_o
            for i_t in 1:n_t
                observable[i_t, iob] = real(expected_value(problem.e_ops[iob], y[i_t]))
            end
        end        
        return (t=sol.t,u=y,e=observable)
end


"""
        lindblad_solve(problem::LindbladProblem;kwargs...)

Solves the Lindblad Master equation:

``\\dot{\\rho}=-i [H, \\rho]+\\sum_i \\gamma_i\\left(L_i \\rho L^{\\dag}_i - \\frac{1}{2}\\left\\{L^{\\dag}_i L_i, \\rho\\right\\}\\right)``

and returns a Vector of observables evaluated at each time step.

**Fields**
- `problem` -- An object of type LindbladProblem that defines the problem to be solved. 
- `kwargs` -- list of keyword arguments to be passed to the ODE solver. See (https://docs.sciml.ai/DiffEqDocs/stable/basics/common_solver_opts/#solver_options)..
"""
function lindblad_solve(
    problem::LindbladProblem;
    kwargs...
    )

    if length(problem.c_ops) == 0
        throw(DomainError(problem.c_ops,"No collapse operator was provided. Try using sesolve()."))
    end

    drho_dt(t,ρ) = -im*(commute(problem.H(t),ρ))+sum([A*ρ*A'-0.5*anticommute(A'*A,ρ) for A in problem.c_ops])
    
    function Lindblad(ρ,p,t)
        return drho_dt(t,DenseOperator(ρ)).data
    end

    prob=OrdinaryDiffEq.ODEProblem(Lindblad,problem.init_state.data,problem.tspan)
    sol= OrdinaryDiffEq.solve(prob,OrdinaryDiffEq.AutoTsit5(OrdinaryDiffEq.Rosenbrock23(autodiff=false));kwargs...) #The default algo is Tsit5 but we switch to Rosenbrock23 for stiff problems

    n_t = length(sol.t)
    n_o = length(problem.e_ops)
    observable=zeros(n_t, n_o) 
    for i_t in 1:n_t
        for i_ob in 1:n_o
                observable[i_t, i_ob] = real(tr(problem.e_ops[i_ob].data*sol.u[i_t]))
        end    
    end
    return (t=sol.t,u=sol.u,e=observable)
end
