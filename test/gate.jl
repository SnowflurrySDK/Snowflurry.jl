using Snowflake
using Test


@testset "gate_set" begin
    H = hadamard(1)

    @test H.instruction_symbol == "ha"
    @test H.display_symbol == ["H"]

    println(H)

    X = sigma_x(1)
    @test X.instruction_symbol == "x"
    @test X.display_symbol == ["X"]

    Y = sigma_y(1)
    @test Y.instruction_symbol == "y"
    @test Y.display_symbol == ["Y"]

    Z = sigma_z(1)
    @test Z.instruction_symbol == "z"
    @test Z.display_symbol == ["Z"]

    CX = control_x(1, 2)
    @test CX.instruction_symbol == "cx"

    CZ = control_z(1, 2)
    @test CZ.instruction_symbol == "cz"
end

@testset "tensor_product_single_qubit_gate" begin


    Ψ1_0 = fock(1, 2) # |0> for qubit_1
    Ψ1_1 = fock(2, 2) # |1> for qubit_1
    Ψ2_0 = fock(1, 2) # |0> for qubit_2
    Ψ2_1 = fock(2, 2) # |0> for qubit_2
    ψ_init = kron(Ψ1_0, Ψ2_0)

    U = kron(sigma_x(), eye())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_0)

    U = kron(eye(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_0, Ψ2_1)

    U = kron(sigma_x(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_1)

end
