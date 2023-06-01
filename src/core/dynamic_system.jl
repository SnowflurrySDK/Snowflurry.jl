"""
    sesolve(H::AbstractOperator, ψ_0::Ket, t_range::StepRangeLen; e_ops::Vector{AbstractOperator}=(AbstractOperator)[])
    sesolve(H::Function, ψ_0::Ket, t_range::StepRangeLen; e_ops::Vector{Operator}=(Operator)[])

Solves the Shrodinger equation:

``\\frac{d \\Psi}{d t}=-i \\hat{H}\\Psi``

and returns the final state Ket, and a Vector of observables evaluated at each time step. 

**Fields**
- `H` -- the Hamiltonian operator (of any subtype of `AbstractOperator`) or a 
        function that returns the Hamiltonian as a function of time.
- `ψ_0` -- initital state (`Ket`) of a quantum system
- `t_range` -- time interval for which the system has to be simulated. 
        For instance: 
            t_range=0:10 evaluates the output using time 
            steps: 0,1,2,...,10. 
            t_range=0:0.01:1 evaluates the output using 
            time steps: 0,0.01,0.02,...,1.0 

- `e_ops` -- list of operators for which the expected value 
    (the observables) will be evaluated at each time step in t_range. 


"""
function sesolve(
    H::AbstractOperator, 
    ψ_0::Ket{S} where {S<:Complex}, 
    tspan::Tuple{Float64,Float64}
)
        dψ_dt = -im*sparse(H).data
        function Hamiltonian!(dψ_v,ψ_v,p,t)
            mul!(dψ_v,dψ_dt,ψ_v)
            nothing
        end
        prob = OrdinaryDiffEq.ODEProblem(Hamiltonian!,ψ_0.data,tspan)
        sol=OrdinaryDiffEq.solve(prob,OrdinaryDiffEq.AutoTsit5(OrdinaryDiffEq.Rosenbrock23(autodiff=false))) #The default algo is Tsit5 but we switch to Rosenbrock23 for stiff problems
        y=Vector{typeof(ψ_0)}()
        for v in sol.u
            push!(y,Ket(v))
        end
        return (t=sol.t,u=y)
end

function sesolve_eops(
        H::AbstractOperator, 
        ψ_0::Ket{S} where {S<:Complex}, 
        tspan::Tuple{Float64,Float64};
        e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    )
    sol=sesolve(H,ψ_0,tspan)

    n_t = length(sol.t)
    n_o = length(e_ops)
    observable=zeros(n_t, n_o) 
    for iob in 1:n_o
        for i_t in 1:n_t
            observable[i_t, iob] = real(expected_value(e_ops[iob], sol.u[i_t]))
        end
    end        
    return (t=sol.t,u=sol.u,e=observable)
end

function sesolve(
            H::Function, 
            ψ_0::Ket{S} where {S<:Complex}, 
            tspan::Tuple{Float64,Float64}
        )    
        function Hamiltonian!(dψ_v,ψ_v,p,t)
            mul!(dψ_v,-im*H(t).data,ψ_v)
            nothing
        end

        prob = OrdinaryDiffEq.ODEProblem(Hamiltonian!,ψ_0.data,tspan)
        sol=OrdinaryDiffEq.solve(prob,OrdinaryDiffEq.AutoTsit5(OrdinaryDiffEq.Rosenbrock23(autodiff=false))) #The default algo is Tsit5 but we switch to Rosenbrock23 for stiff problems

        y=Vector{typeof(ψ_0)}()
        for v in sol.u
            push!(y,Ket(v))
        end
        return (t=sol.t,u=y)
end

function sesolve_eops(
    H::Function, 
    ψ_0::Ket{S} where {S<:Complex}, 
    tspan::Tuple{Float64,Float64};
    e_ops::Vector{T} where {T<:AbstractOperator},
    )    
    
    sol=sesolve(H,ψ_0,tspan)

    n_t = length(sol.t)
    n_o = length(e_ops)
    observable=zeros(n_t, n_o) 
    for iob in 1:n_o
        for i_t in 1:n_t
            observable[i_t, iob] = real(expected_value(e_ops[iob], sol.u[i_t]))
        end
    end        

    return (t=sol.t,u=sol.u,e=observable)
end

"""
    mesolve(H::AbstractOperator, ψ_0::Ket, t_range::StepRangeLen; e_ops::Vector{AbstractOperator}=(AbstractOperator)[])

Solves the Lindblad Master equation:

``\\dot{\\rho}=-i [H, \\rho]+\\sum_i \\gamma_i\\left(L_i \\rho L^{\\dag}_i - \\frac{1}{2}\\left\\{L^{\\dag}_i L_i, \\rho\\right\\}\\right)``

and returns a Vector of observables evaluated at each time step.

**Fields**
- `H` -- the Hamiltonian operator (of any subtype of `AbstractOperator`).
- `ψ_0` -- initital state (Ket) of a quantum system
- `t_range` -- time interval for which the system has to be simulated. 
        For instance: 
            t_range=0:10 evaluates the output using time 
            steps: 0,1,2,...,10. 
            t_range=0:0.01:1 evaluates the output using 
            time steps: 0,0.01,0.02,...,1.0 
- `e_ops` -- list of operators for which the expected value 
        (the observables) will be evaluated at each time step in t_range. 
- `c_ops` -- list of collapse operators ``L_i``'s.
"""
function mesolve(
    H::Function, 
    ρ_0::T, 
    tspan::Tuple{Number,Number}; 
    c_ops::Vector{T},
    ) where {T<:DenseOperator}

    if length(c_ops) == 0
        @warn "You have speciefied no collapse operator for the Master Equation. In such case, we suggest using the Shrodigner eq. solvers."
    end

    drho_dt(t,ρ) = -im*(commute(H(t),ρ))+sum([A*ρ*A'-0.5*anticommute(A'*A,ρ) for A in c_ops])
    
    function Lindblad(ρ,p,t)
        return drho_dt(t,DenseOperator(ρ)).data
    end

    function Shrodinger(ρ,p,t)
        return (-im*(commute(H(t),DenseOperator(ρ)))).data
    end

    if length(c_ops) == 0
        prob=OrdinaryDiffEq.ODEProblem(Shrodinger,ρ_0.data,tspan)
        return OrdinaryDiffEq.solve(prob,OrdinaryDiffEq.AutoTsit5(OrdinaryDiffEq.Rosenbrock23(autodiff=false))) #The default algo is Tsit5 but we switch to Rosenbrock23 for stiff problems
    else
        prob=OrdinaryDiffEq.ODEProblem(Lindblad,ρ_0.data,tspan)
        return OrdinaryDiffEq.solve(prob,OrdinaryDiffEq.AutoTsit5(OrdinaryDiffEq.Rosenbrock23(autodiff=false))) #The default algo is Tsit5 but we switch to Rosenbrock23 for stiff problems
    end
    
end

 function mesolve_eops(
    H::Function, 
    ρ_0::T, 
    tspan::Tuple{Float64,Float64}; 
    c_ops::Vector{T}, 
    e_ops::Vector{T}, 
    ) where {T<:AbstractOperator}
    if length(c_ops) == 0
        @warn "You have speciefied no collapse operator for the Master Equation. In such case, we suggest using the Shrodigner eq. solvers."
    end
    sol = mesolve(H,ρ_0,tspan,c_ops=c_ops)
    n_t = length(sol.t)
    n_o = length(e_ops)
    observable=zeros(n_t, n_o) 
    for i_t in 1:n_t
        for i_ob in 1:n_o
                observable[i_t, i_ob] = real(tr(e_ops[i_ob].data*sol.u[i_t]))
        end    
    end
    return (t=sol.t,u=sol.u,e=observable)
end

