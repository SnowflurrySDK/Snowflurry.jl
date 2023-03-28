using Snowflake
using Test

@testset "qpu" begin
    # create a 3 qubit system with nearest neighbor connectivity
    qpu = create_virtual_qpu(3,Matrix([1 1 0; 1 1 1 ; 0 1 1]), ["x" , "y" , "z" , "i", "cz"])
    @test qpu.qubit_count == 3
    @test "x" in qpu.native_gates

    show(qpu)
    
    c = QuantumCircuit(qubit_count = 3)
    # push_gate!(c, sigma_x(1))
    push_gate!(c, control_z(2,1))

    is_circuit_ok,  = is_circuit_native_on_qpu(c, qpu)
    @test is_circuit_ok

    push_gate!(c,control_z(2,3))
    is_circuit_ok, = does_circuit_satisfy_qpu_connectivity(c, qpu)
    println(does_circuit_satisfy_qpu_connectivity(c, qpu))
    @test is_circuit_ok

    push_gate!(c, control_x(2, 3))
    (is_circuit_ok, non_native_gate) = is_circuit_native_on_qpu(c, qpu)
    @test !is_circuit_ok
    @test non_native_gate == get_instruction_symbol(control_x(2, 3))

    push_gate!(c, control_z(3, 1))
    (is_circuit_ok, incorrect_gate) = does_circuit_satisfy_qpu_connectivity(c, qpu)
    @test !is_circuit_ok
    @test incorrect_gate.target == [3, 1]
end

