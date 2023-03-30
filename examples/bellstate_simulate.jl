using Snowflake

c = QuantumCircuit(qubit_count = 2)
push!(c, [hadamard(1)])
push!(c, [control_x(1, 2)])

ψ = simulate(c)

plot_histogram(c, 1001)
