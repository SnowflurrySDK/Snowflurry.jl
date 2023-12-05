using Dates
using Snowflurry

circuit = QuantumCircuit(qubit_count = 2)

push!(circuit, hadamard(1))
push!(circuit, control_x(1, 2))

user = ENV["ANYON_USER"]
token = ENV["ANYON_TOKEN"]
host = ENV["ANYON_QPU"]

qpu = AnyonYukonQPU(host = host, user = user, access_token = token)

shot_count = 200
result_1 = transpile_and_run_job(qpu, circuit, shot_count)
println(result_1)

# alternarively, one can explicitly transpile a code and run the transpiled circuit. 

transpiler = get_transpiler(qpu)
transpiled_circuit = transpile(transpiler, circuit)
result_2 = run_job(qpu, transpiled_circuit, shot_count)
