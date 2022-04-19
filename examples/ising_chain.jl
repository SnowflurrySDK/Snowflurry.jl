using Snowflake

Ψ_up = fock(1, 2)
Ψ_down = fock(2, 2)

Ψ_p = (1.0 / sqrt(2.0)) * (Ψ_up + Ψ_down)
Ψ_m = (1.0 / sqrt(2.0)) * (Ψ_up - Ψ_down)

qubit_count = 2
hilber_space_size_per_qubit = 2
system = MultiBodySystem(qubit_count, hilber_space_size_per_qubit)

x = sigma_x(1)
z = sigma_z(1)

##Get embedded operators
target_qubit = 1
x_1 = get_embed_operator(x.operator, target_qubit, system)
z_1 = get_embed_operator(z.operator, target_qubit, system)

target_qubit = 2
x_2 = get_embed_operator(x.operator, target_qubit, system)
z_2 = get_embed_operator(z.operator, target_qubit, system)

ω = 0.1 #qubit frequencies
J = 1.0 #coupling rate
hamiltonian = -ω*(z_1+z_2)-J*x_1*x_2 
eig_vals, eig_vecs = Snowflake.eigen(hamiltonian)
println(eig_vals)
println(eig_vecs[:,1])
println(eig_vecs[:,2])

ψ_pp = kron(Ψ_p, Ψ_p)
ψ_mm = kron(Ψ_m, Ψ_m)
ψ_pm = kron(Ψ_p, Ψ_m)
ψ_mp = kron(Ψ_m, Ψ_p)

ψ_uu = kron(Ψ_up, Ψ_up)
ψ_dd = kron(Ψ_down, Ψ_down)

ψ_1 = (ψ_uu+ψ_dd)
ψ_2 = (ψ_uu-ψ_dd)


ψ_1 = (ψ_pp)
ψ_2 = (ψ_mm)

println(ψ_1)
println(hamiltonian*ψ_1)
println(Snowflake.expect(hamiltonian, ψ_2))


# println(ψ_pp)
# println(hamiltonian*ψ_pp)

# println(ψ_mm)
# println(hamiltonian*ψ_mm)
