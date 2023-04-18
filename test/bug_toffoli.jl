using Snowflake
using Test

@testset "bug #132" begin
    c0 = QuantumCircuit(qubit_count = 4, gates=[toffoli(3,4,2)])
    c1 = QuantumCircuit(qubit_count = 4, gates=[toffoli(4,3,2)])

    @test compare_circuits(c0,c1)

    transpiler=Snowflake.PlaceOperationsOnLine()

    c0 = QuantumCircuit(qubit_count = 6, gates=[toffoli(1,5,4)])
    c1=transpile(transpiler,c0)

    @test compare_circuits(c0,c1)

    c0 = QuantumCircuit(qubit_count = 6, gates=[toffoli(2,6,4)]) #this one works
    c1=transpile(transpiler,c0)

    @test compare_circuits(c0,c1)

end