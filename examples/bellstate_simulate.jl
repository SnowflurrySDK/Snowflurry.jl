using Snowflake

c = Circuit(qubit_count=2, bit_count=0)
pushGate!(c, [hadamard(1)])
pushGate!(c, [control_x(1, 2)])

ψ = simulate(c)

histogram(c,10001)