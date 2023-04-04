"""
    sesolve(H::AbstractOperator, ψ_0::Ket, t_range::StepRangeLen; e_ops::Vector{AbstractOperator}=(AbstractOperator)[])
    sesolve(H::Function, ψ_0::Ket, t_range::StepRangeLen; e_ops::Vector{Operator}=(Operator)[])

Solves the Shrodinger equation:

``\\frac{d \\Psi}{d t}=-i \\hat{H}\\Psi``

**Fields**
- `H` -- the Hamiltonian operator or a function that returns the Hamiltonian as a function of time.
- `ψ_0` -- initital status of a quantum system
- `t_range` -- time interval for which the system has to be simulated. 
- `e_ops` -- list of operators for which the expected value will be returned as a function of time. 
"""
function sesolve(
        H::AbstractOperator, 
        ψ_0::Ket, 
        t_range::StepRangeLen; 
        e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    )
    Hamiltonian(t)=H
    sesolve(Hamiltonian, ψ_0, t_range; e_ops=e_ops)
end

function sesolve(
        H::Function, 
        ψ_0::Ket, 
        t_range::StepRangeLen; 
        e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    )
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
    mesolve(H::Function, ψ_0::Ket, t_range::StepRangeLen; e_ops::Vector{AbstractOperator}=(AbstractOperator)[])

Solves the Lindblad Master equation:

``\\dot{\\rho}=-i [H, \\rho]+\\sum_i \\gamma_i\\left(L_i \\rho L^{\\dag}_i - \\frac{1}{2}\\left\\{L^{\\dag}_i L_i, \\rho\\right\\}\\right)``

**Fields**
- `H` -- the Hamiltonian operator or a function that returns the Hamiltonian as a function of time.
- `ψ_0` -- initital status of a quantum system
- `t_range` -- time interval for which the system has to be simulated. 
- `e_ops` -- list of operators for which the expected value will be returned as function of time. 
- `c_ops` -- list of collapse operators ``L_i``'s.
"""
function mesolve(
    H::AbstractOperator, 
    ρ_0::AbstractOperator, 
    t::StepRangeLen; 
    c_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    e_ops::Vector{T} where {T<:AbstractOperator}=(T)[], 
    )
    drho_dt(t,ρ) = -im*commute(H,ρ)+sum([A*ρ*A'-0.5*anticommute(A'*A,ρ) for A in c_ops])
    n_t = length(t)
    n_o = length(e_ops)
    observable=zeros(n_t, n_o) 

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

function rungekutta2(f, y0, t)
    n = length(t)
    y = Array{Ket}(undef, n)
    y[1] = y0
    for i in 1:n-1
        h = t[i+1] - t[i]
        y_1 = y[i]+h/2.0*f(t[i], y[i])
        y[i+1] = y[i] + h * f(t[i]+ h/2.0, y_1)
    end
    return y
end
