using Snowflake

c = QuantumCircuit(qubit_count = 2, bit_count = 0)
push_gate!(c, [hadamard(1)])
push_gate!(c, [control_x(1, 2)])

ψ = simulate(c)

plot_histogram(c, 1001)
