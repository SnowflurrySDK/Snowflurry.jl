using Snowflake
using Test

@testset "qpu" begin
    # create a 3 qubit system with nearest neighbor connectivity
    qpu = create_virtual_qpu(3,Matrix([1 1 0; 1 1 1 ; 0 1 1]), ["x" , "y" , "z" , "i", "cz"])
    @test qpu.qubit_count == 3
    @test "x" in qpu.native_gates
    
    c = QuantumCircuit(qubit_count = 3, bit_count = 0)
    push_gate!(c, sigma_x(1))
    push_gate!(c, control_z(2,1))

    is_circuit_ok,  = is_circuit_native_on_qpu(c, qpu)
    @test is_circuit_ok

    push_gate!(c,control_z(2,3))
    is_circuit_ok, = does_circuit_satisfy_qpu_connectivity(c, qpu)
    println(does_circuit_satisfy_qpu_connectivity(c, qpu))
    @test is_circuit_ok
end

