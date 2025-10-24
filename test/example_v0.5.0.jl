using Snowflurry

include("mock_functions.jl")

metadata = makeMetadataResponseJSON(
    "[{\"id\":\"6b770575-c40f-4d81-a9de-b1969a028ca5\",\"name\":\"yamaska\",\"hostServer\":\"yamaska.anyonsys.com\",\"type\":\"quantum-computer\",\"owner\":\"CalculQC\",\"status\":\"online\",\"metadata\":{\"Serial Number\":\"ANYK202301\"},\"qubitCount\":24,\"bitCount\":24,\"connectivity\":\"lattice\",\"disconnectedQubits\":[10,14,15,19],\"disconnectedConnections\":[[6, 11]]}]",
)

requestor = MockRequestor(
    make_request_checker("", Dict("machineName" => "yamaska"), return_metadata = metadata),
    make_post_checker(expected_json_yukon),
)
test_client = Client(
    host = expected_host,
    user = expected_user,
    access_token = expected_access_token,
    requestor = requestor,
)

qpu =
    AnyonYamaskaQPU(test_client, expected_project_id, status_request_throttle = no_throttle)

connectivity = get_connectivity(qpu)

path = Snowflurry.path_search(7, 12, connectivity)

circuit = QuantumCircuit(qubit_count = 12, instructions = [control_z(7, 12)])
