using Snowflake
using Test

@testset "regression test: cnot inverse identity" begin
    q1 = 2
    q2 = 4
    qubit_count = 5

    cnot_circuit = QuantumCircuit(qubit_count=qubit_count, gates=[
        control_x(q1, q2)]
    )
    inverted_cnot_circuit = QuantumCircuit(qubit_count=qubit_count, gates=[
        hadamard(q1),
        hadamard(q2),
        control_x(q2, q1),
        hadamard(q1),
        hadamard(q2),
    ])

    @test compare_circuits(cnot_circuit, inverted_cnot_circuit)
end
