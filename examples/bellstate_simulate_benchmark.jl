using Snowflake

qubit_count=6

c = QuantumCircuit(qubit_count, bit_count = 0)
push_gate!(c, [hadamard(1)])

for i in 
push_gate!(c, [control_x(1, 2)])

ψ = simulate(c)

plot_histogram(c, 1001)
