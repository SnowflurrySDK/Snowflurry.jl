using Snowflurry

c = QuantumCircuit(qubit_count = 2, name = "bell_state")
push!(c, hadamard(1))
push!(c, control_x(1, 2))

ψ = simulate(c)

print(ψ)
