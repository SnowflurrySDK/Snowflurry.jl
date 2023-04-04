using Snowflake
using Test

@testset "serialize_circuit" begin

    qubit_count=3
    circuit = QuantumCircuit(qubit_count = qubit_count)
    push!(circuit, [sigma_x(3),control_z(2,1)])

    repetitions=10

    circuit_json=serialize_circuit(circuit,repetitions,indentation=false)

    expected_json="{\"num_repititions\":10,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"
    
    @test circuit_json==expected_json

end

