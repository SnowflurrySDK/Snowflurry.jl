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
        ψ_0::Ket{S}, 
        t_range::StepRangeLen; 
        e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    )::Tuple{Vector{Ket{S}},Matrix{<:Real}} where {S<:Complex}
    Hamiltonian(t)=H
    sesolve(Hamiltonian, ψ_0, t_range; e_ops=e_ops)
end

function sesolve(
        H::Function, 
        ψ_0::Ket{S}, 
        t_range::StepRangeLen; 
        e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    )::Tuple{Vector{Ket{S}},Matrix{<:Real}} where {S<:Complex}
    dpsi_dt(t,ψ) = -im*H(t)*ψ
    y=rungekutta2(dpsi_dt, ψ_0, t_range)
    n_t = length(t_range)
    n_o = length(e_ops)
    observable=zeros(n_t, n_o) 
    for iob in 1:n_o
        for i_t in 1:n_t
            observable[i_t, iob] = real(expected_value(e_ops[iob], y[i_t]))
        end
    end        
    return (y, observable)
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
    H::AbstractOperator, 
    ρ_0::AbstractOperator, 
    t::StepRangeLen; 
    c_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    )::Matrix{<:Real}
    Hamiltonian(t) = H
    mesolve(Hamiltonian, ρ_0, t; c_ops=c_ops, e_ops=e_ops)
end

function mesolve(
    H::Function, 
    ρ_0::AbstractOperator, 
    t::StepRangeLen; 
    c_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
)::Matrix{<:Real}
    n_t = length(t)
    n_o = length(e_ops)
    observable=zeros(n_t, n_o) 

    if length(c_ops) == 0
        eigenvalues, eigenvectors = eigen(ρ_0)

        n, _ = size(ρ_0)
        for i in 1:n
            eigenvalue = eigenvalues[i]
            eigenvector = eigenvectors[i, :]
            
            @assert imag(eigenvalue) ≈ 0
            
            if real(eigenvalue) ≉ 0
                _, observable_i = sesolve(H, Ket(eigenvector), t, e_ops=e_ops)
                observable += observable_i * real(eigenvalue)
            end
        end
        return observable
    end

    drho_dt(t,ρ) = -im*commute(H(t),ρ)+sum([A*ρ*A'-0.5*anticommute(A'*A,ρ) for A in c_ops])

    ρ = ρ_0
    for i_ob in 1:n_o
        observable[1, i_ob] = real(tr(e_ops[i_ob]*ρ))
    end

    for i_t in 1:n_t-1
        h = t[i_t+1] - t[i_t]
        ρ_1 = ρ+h/2.0*drho_dt(t[i_t], ρ)
        ρ+= h * drho_dt(t[i_t]+ h/2.0, ρ_1)
        for i_ob in 1:n_o
                observable[i_t+1, i_ob] = real(tr(e_ops[i_ob]*ρ))
        end    
    end
    return observable
end

function rungekutta2(f::Function, y0::Ket{T}, t::StepRangeLen)::Vector{Ket{T}} where {T<:Complex}
    n = length(t)
    y = Vector{Ket{T}}(undef, n)
    y[1] = y0
    for i in 1:n-1
        h = T(t[i+1] - t[i])
        y_1 = y[i]+T(h/2.0)*f(T(t[i]), y[i])
        y[i+1] = y[i] + h * f(T(t[i]+ h/2.0), y_1)
    end
    return y
end
