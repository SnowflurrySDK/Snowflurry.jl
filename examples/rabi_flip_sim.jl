using Snowflake
using Plots


ψ_0 = spin_up()
ω = 2.0*pi #Rabi frequency
H = ω/2.0*sigma_x()
T = 100.0
t = 0.0:0.01:T
#master equation solver
projection = ψ_0*ψ_0'
Γ = 0.05  #relaxation rate
prob = mesolve(H, ket2dm(ψ_0), t, c_ops=[sqrt(Γ)*sigma_m()], e_ops=[projection])
#ψ , prob = sesolve(H, ψ_0, t,e_ops=[sigma_z()])
#master equation solver
plot(t,prob, label=["P(spin_up)"],lw=2)