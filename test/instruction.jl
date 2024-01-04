using Snowflurry
using Test

@testset "AbstractInstruction: fallback cases" begin
    struct NewInstruction <: AbstractInstruction end

    instr = NewInstruction()

    @test_throws NotImplementedError Base.inv(instr)
    @test_throws NotImplementedError get_connected_qubits(instr)
    @test_throws NotImplementedError apply_instruction!(Ket([1, 2, 3, 4]), instr)
    @test_throws NotImplementedError Base.:*(instr, Ket([1, 2, 3, 4]))

    @test_throws NotImplementedError Snowflurry.is_multi_target(instr)
    @test_throws NotImplementedError Snowflurry.is_not_rz_gate(instr)
end
