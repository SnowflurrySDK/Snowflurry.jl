function sesolve(H::Operator, ψ_0::Ket, t_list::StepRangeLen; e_ops::Vector{Operator}=(Operator)[], kwargs...)
    
end
function sesolve(H::Function, ψ_0::Ket, t_range::StepRangeLen; e_ops::Vector{Operator}=(Operator)[], kwargs...)
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

function rungekutta2(f, y0, t)
    n = length(t)
    println(length(y0))
    y = Array{Ket}(undef, n)
    y[1] = y0
    for i in 1:n-1
        h = t[i+1] - t[i]
        y_1 = y[i]+h/2.0*f(t[i], y[i])
        y[i+1] = y[i] + h * f(t[i]+ h/2.0, y_1)
    end
    return y
end