using DiffEqCallbacks

"""
    ShrodingerProblem is a structure that is defined to solve the Shrodinger equation in time-domain using sesolve(). 

**Fields**
- `H` -- a function that returns the Hamiltonian operator (of any subtype of `AbstractOperator`) as a function of time.
- `init_state` -- initial state (`Ket`) of a quantum system
- `t_span` -- time interval for which the system has to be simulated. 
        For instance: 
            t_span=(0.0,1.0) evaluates the output from t=0.0 to t=1.0
- `e_ops` -- list of operators for which the expected value 
    (the observables) will be evaluated at each time step in t_range. 
- `t_integ` -- timesteps for which the output solution is evaluated. 
    Default value is `nothing`, for which OrdinaryDiffEq.solve() 
    determines the optimal timesteps. 
    For instance: 
        t_integ=range(0.,stop=1.0,length=9) evaluates the output 
        at t=0.0, 0.1, ... , 1.0.
        Note: t_integ must be bounded by t_span.  
"""
Base.@kwdef struct ShrodingerProblem
    H::Function
    init_state::Ket
    t_span::Tuple{<:Real,<:Real}
    e_ops::Vector{AbstractOperator}
    t_integ::Union{<:AbstractRange,Vector{<:Real},Nothing}=nothing
    
    function ShrodingerProblem(
        H::Function,
        init_state::Ket,
        t_span::Tuple{<:Real,<:Real},
        e_ops::Vector{<:AbstractOperator},
        t_integ::Union{<:AbstractRange,Vector{<:Real},Nothing}=nothing)
    
        check_t_span_t_integ!(t_span,t_integ)

        new(H,init_state,t_span,e_ops,t_integ)
    end
end

function Base.show(io::IO, p::ShrodingerProblem)
    println(io, "Snowflake.ShrodingerProblem:\n")

    println(io, "Hamiltonian (H): $(p.H)\n")
    println(io, "Initial state (init_state):\n$(p.init_state)\n")
    println(io, "Time interval (t_span): $(p.t_span)")
    println(io, "Output timesteps (t_integ): $(p.t_integ)\n")
    println(io, "Expected value operators (e_ops):\n$(p.e_ops)\n")
end

"""
    A LindbladProblem is a structure that is defined to solve the Lindblad master equation in time-domain using lindblad_solve(). 

**Fields**
- `H` -- a function that returns the Hamiltonian operator (of any subtype of `AbstractOperator`) as a function of time.
- `init_state` -- initial state density matrix (`DenseOperator`) of a quantum system
- `t_span` -- time interval for which the system has to be simulated. 
        For instance: 
            t_span=(0.0,1.0) evaluates the output from t=0.0 to t=1.0
- `e_ops` -- list of operators (any subtype of `AbstractOperator`) for which the expected value 
    (the observables) will be evaluated at each time step in t_range. 

- `c_ops` -- list of collapse operators (any subtype of `AbstractOperator`).
- `t_integ` -- timesteps for which the output solution is evaluated. 
        Default value is `nothing`, for which OrdinaryDiffEq.solve() 
        determines the optimal timesteps. 
        For instance: 
            t_integ=range(0.,stop=1.0,length=9) evaluates the output 
            at t=0.0, 0.1, ... , 1.0.
            Note: t_integ must be bounded by t_span.  
"""
Base.@kwdef struct LindbladProblem
    H::Function
    init_state::DenseOperator
    t_span::Tuple{<:Real,<:Real}
    e_ops::Vector{AbstractOperator}
    c_ops::Vector{AbstractOperator}
    t_integ::Union{<:AbstractRange,Vector{<:Real},Nothing}=nothing
    
    function LindbladProblem(
        H::Function,
        init_state::DenseOperator,
        t_span::Tuple{<:Real,<:Real},
        e_ops::Vector{<:AbstractOperator},
        c_ops::Vector{<:AbstractOperator},
        t_integ::Union{<:AbstractRange,Vector{<:Real},Nothing}=nothing)
    
        check_t_span_t_integ!(t_span,t_integ)
        
        new(H,init_state,t_span,e_ops,c_ops,t_integ)
    end
end

function Base.show(io::IO, p::LindbladProblem)
    println(io, "Snowflake.LindbladProblem:\n")

    println(io, "Hamiltonian (H): $(p.H)\n")
    println(io, "Initial state (init_state):\n$(p.init_state)\n")
    println(io, "Time interval (t_span): $(p.t_span)")
    println(io, "Output timesteps (t_integ): $(p.t_integ)\n")
    println(io, "Expected value operators (e_ops):\n$(p.e_ops)\n")
    println(io, "Collapse operators: (c_ops)\n$(p.c_ops)\n")
end

#ensures t_integ does not exceed t_span, and converts empty array to `nothing`
function check_t_span_t_integ!(
    t_span::Tuple{<:Real,<:Real},
    t_integ::Union{<:AbstractRange,Vector{<:Real},Nothing}
    )::Nothing
    # replace empty array by nothing
    if !isnothing(t_integ) && isempty(t_integ)
        t_integ=nothing
    end

    if !isnothing(t_integ)
        @assert t_integ[1]>=t_span[1] "Cannot evaluate observable before"*
            " start of simulation. Received t_integ[1]<t_span[1]:\n"*"
            t_integ[1]=$(t_integ[1]), t_span[1]=$(t_span[1])"
        @assert t_integ[end]<=t_span[2] "Cannot evaluate observable after"*
            " completion of simulation. Received t_integ[end]>t_span[2]:\n"*"
            t_integ[end]]=$(t_integ[end]), t_span[2]=$(t_span[2])"
    end
end


"""
    sesolve(problem::ShrodingerProblem; kwargs...)
Solves the Shrodinger equation:

``\\frac{d \\Psi}{d t}=-i \\hat{H}\\Psi``

and returns a tuple corresponding the time-instance vector, the corresponding wavefunction `Ket`, and a Vector of observables evaluated at each time step. 

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

    ODEprob = OrdinaryDiffEq.ODEProblem(Hamiltonian!,problem.init_state.data,problem.t_span)

    n_o=length(problem.e_ops)

    function save_func(u,t,integrator)

        # allocate memory without initializing
        observable_t = Vector{Float64}(undef, n_o)
        
        for i_ob in 1:n_o
            observable_t[i_ob] = real(expected_value(problem.e_ops[i_ob], Ket(u)))
        end
        
        return observable_t
    end

    return solve(ODEprob, problem.t_integ, save_func,typeof(problem.init_state);kwargs...)
end


"""
        lindblad_solve(problem::LindbladProblem;kwargs...)

Solves the Lindblad Master equation:

``\\dot{\\rho}=-i [H, \\rho]+\\sum_i \\gamma_i\\left(L_i \\rho L^{\\dag}_i - \\frac{1}{2}\\left\\{L^{\\dag}_i L_i, \\rho\\right\\}\\right)``

and returns a Vector of observables evaluated at each time step.

**Fields**
- `problem` -- An object of type LindbladProblem that defines the problem to be solved. 
- `kwargs` -- list of keyword arguments to be passed to the ODE solver. See (https://docs.sciml.ai/DiffEqDocs/stable/basics/common_solver_opts/#solver_options).
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

    ODEprob=OrdinaryDiffEq.ODEProblem(Lindblad,problem.init_state.data,problem.t_span)

    n_o=length(problem.e_ops)
    
    function save_func(u,t,integrator)

        # allocate memory without initializing
        observable_t = Vector{Float64}(undef, n_o)
        
        for i_ob in 1:n_o
            observable_t[i_ob] = real(tr(problem.e_ops[i_ob]*DenseOperator(u)))
        end
        
        return observable_t
    end
      
    return solve(ODEprob, problem.t_integ, save_func, typeof(problem.init_state);kwargs...)
end



function solve(
    ODEprob::OrdinaryDiffEq.ODEProblem,
    t_integ::Union{<:AbstractRange,Vector{<:Real},Nothing},
    save_func::Function,
    type_sol::DataType;
    kwargs...
    )::NamedTuple{
        (:t, :u, :e), 
        Tuple{Vector{<:Real}, 
        Vector{Union{DenseOperator,Ket}}, 
        Matrix{<:Real}}}

    #container for output values
                            # typeof(t), typeof(observable)
    saved_values = SavedValues(Float64, Vector{Float64})

    if isnothing(t_integ)   
        # outputs are evaluated at timesteps determined by solve()
        cb=SavingCallback(save_func, saved_values)
    else
        # outputs are evaluated at timesteps in t_integ
        cb_preset=PresetTimeCallback(
            t_integ,
            (x->nothing) # affect_ic! has no effect on current solution
        )
            
        cb_save=SavingCallback(save_func, saved_values,saveat=t_integ)
        cb=OrdinaryDiffEq.CallbackSet(cb_preset,cb_save)
    end
        
    #The default algo is Tsit5 but we switch to Rosenbrock23 for stiff problems
    alg=OrdinaryDiffEq.AutoTsit5(OrdinaryDiffEq.Rosenbrock23(autodiff=false))
    
    sol = OrdinaryDiffEq.solve(ODEprob, alg, callback=cb, 
    save_everystep=false, # reduces the output size of sol
    save_on=false;
    kwargs...
    )
    
    # allocate memory without initializing
    n_t=length(saved_values.t)
    n_o=length(saved_values.saveval[1])

    observable = Matrix{Float64}(undef,n_t,n_o) 

    for i_t in 1:n_t
        for i_ob in 1:n_o
            observable[i_t,i_ob] = saved_values.saveval[i_t][i_ob]
        end
    end

    output=[type_sol(u_t) for u_t in sol.u]

    return (t=saved_values.t,u=output,e=observable)
end