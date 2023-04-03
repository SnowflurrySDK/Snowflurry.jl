using Snowflake

include("run_jobs.jl")

qubit_count_circuit=3

circuit = QuantumCircuit(qubit_count = qubit_count_circuit)

# push!(circuit, [control_x(1, 3),rotation(2,π,-π/4),control_z(2,1)])
# push!(circuit, [sigma_x(3),control_z(2,1)])
push!(circuit, [sigma_x(1)])

# circuit_json=serialize_circuit(c,55)

user="user_test"

# host="https://httpbin.org/post"
# access_token="test-access-token"

host        =ENV["ANYON_QUANTUM_HOST"]
access_token=ENV["ANYON_QUANTUM_TOKEN"]

# host        ="https://en.wikipedia.org/wiki/Main_Page"
# access_token="12345"

test_client=Client(host,user,access_token)

qubit_count_qpu=3
connectivity=Matrix([1 1 0; 1 1 1 ; 0 1 1])

native_gates=["x" , "y" , "z" , "i", "cz"]

num_repetitions=10

# create_virtual_qpu(qubit_count_qpu, connectivity, native_gates, host = "localhost:5600")

qpu=QPU(
    "Anyon Systems Inc.",
    "TBD",
    "0000-0000-0001",
    host,
    qubit_count_qpu,
    connectivity,
    native_gates
)

qpu_service=QPUService(test_client,qpu)

println("run with qpu_service: $qpu_service and circuit: $circuit")

run(qpu_service, circuit ,num_repetitions)

# qpu = create_virtual_qpu(3,connectivity, )


