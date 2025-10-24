using Snowflurry

circuit = QuantumCircuit(qubit_count = 3, name = "3 qubit GHZ")

push!(circuit, hadamard(1))
push!(circuit, control_x(1, 2))
push!(circuit, control_x(2, 3))
push!(circuit, readout(1, 1))
push!(circuit, readout(2, 2))
push!(circuit, readout(3, 3))

qpu = AnyonYukonQPU(
    host = "https://manager.anyonlabs.com",
    user = "richard_feynman",
    access_token = "*********",
    realm = "anyon",
)

shot_count = 1000
result, qpu_time = transpile_and_run_job(qpu, transpiled_circuit, shot_count)

println(result)
