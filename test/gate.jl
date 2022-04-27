using Snowflake
using Test


@testset "gate_set" begin
    H = hadamard(1)

    @test H.instruction_symbol == "h"
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

    ψ_0 = fock(0,2)
    ψ_1 = fock(1,2)

    S = phase(1)
    @test S.instruction_symbol == "s"
    @test S*ψ_0 ≈ ψ_0
    @test S*ψ_1 ≈ im*ψ_1

    T = pi_8(1)
    @test T.instruction_symbol == "t"
    @test T*ψ_0 ≈ ψ_0
    @test T*ψ_1 ≈ exp(im*pi/4.0)*ψ_1

    x90 = x_90(1)
    @test x90.instruction_symbol == "x_90"
    @test x90*ψ_0 ≈ -im*ψ_1 
    @test x90*ψ_1 ≈ -im*ψ_0 

end

@testset "tensor_product_single_qubit_gate" begin


    Ψ1_0 = fock(0, 2) # |0> for qubit_1
    Ψ1_1 = fock(1, 2) # |1> for qubit_1
    Ψ2_0 = fock(0, 2) # |0> for qubit_2
    Ψ2_1 = fock(1, 2) # |0> for qubit_2
    ψ_init = kron(Ψ1_0, Ψ2_0)

    U = kron(sigma_x(), eye())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_0)

    U = kron(eye(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_0, Ψ2_1)

    U = kron(sigma_x(), sigma_x())
    @test U * ψ_init ≈ kron(Ψ1_1, Ψ2_1)

end

@testset "std_gates" begin
    std_gates = ["x", "y", "z", "s", "t", "i", "h", "cx", "cz", "iswap"]
    for gate in std_gates
        @test gate in keys(STD_GATES)
    end
end

@testset "pauli_gates" begin
    pauli_gates = ["x", "y", "z", "i"]
    for gate in pauli_gates
        @test gate in keys(STD_GATES)
    end
end
