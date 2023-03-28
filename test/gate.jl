using Snowflake
using Test

include("testFunctions.jl")

@testset "apply_gate" begin
    ψ_0 = fock(0,2)
    ψ_0_to_update = fock(0,2)
    ψ_1 = fock(1,2)

    apply_gate!(ψ_0_to_update, hadamard(1))
    @test ψ_0_to_update ≈ 1/2^.5*(ψ_0+ψ_1)

    @test_throws DomainError apply_gate!(ψ_0_to_update, hadamard(2))

    non_qubit_ket = Ket([1.0, 0.0, 0.0])
    @test_throws DomainError apply_gate!(non_qubit_ket, hadamard(1))

    transformed_ψ_1 = hadamard(1)*ψ_1
    @test ψ_1 ≈ fock(1,2)
    @test transformed_ψ_1 ≈ 1/2^.5*(ψ_0-ψ_1)
end


@testset "gate_set" begin

    @test eye(2)≈kron(eye(),eye())
    @test_throws DomainError eye(0)
    @test eye(3)≈kron(eye(2),eye())

    H = hadamard(1)
    h_oper=get_operator(H)
    @test h_oper ≈ hadamard()
    @test get_inverse(H) == H
    @test get_instruction_symbol(H) == "h"
    @test get_display_symbol(H) ==["H"]

    println(H)

    @test get_matrix(2*h_oper) == get_matrix(h_oper).*2

    X = sigma_x(1)

    @test get_instruction_symbol(X) == "x"
    @test get_display_symbol(X) ==["X"]
    @test get_operator(X) ≈ sigma_x()
    @test get_inverse(X) == X

    Y = sigma_y(1)
    @test get_instruction_symbol(Y) == "y"
    @test get_display_symbol(Y) ==["Y"]
    @test get_operator(Y) ≈ sigma_y()
    @test get_inverse(Y) == Y

    Z = sigma_z(1)
    @test get_instruction_symbol(Z) == "z"
    @test get_display_symbol(Z) ==["Z"]
    @test get_operator(Z) ≈ sigma_z()
    @test get_inverse(Z) == Z

    CX = control_x(1, 2)

    @test get_instruction_symbol(CX) == "cx"
    @test get_display_symbol(CX) ==["*", "X"]
    @test get_operator(CX) ≈ control_x()
    @test get_inverse(CX) == CX

    CZ = control_z(1, 2)
    @test get_instruction_symbol(CZ) == "cz"
    @test get_display_symbol(CZ) ==["*", "Z"]
    @test get_operator(CZ) ≈ control_z()
    @test get_inverse(CZ) == CZ

    CCX = toffoli(1, 2, 3)
    @test get_instruction_symbol(CCX) == "ccx"
    @test get_display_symbol(CCX) ==["*", "*", "X"]
    @test CCX*fock(6,8) ≈ fock(7,8)
    @test CCX*fock(2,8) ≈ fock(2,8)
    @test CCX*fock(4,8) ≈ fock(4,8)
    @test toffoli(3, 1, 2)*fock(5,8) ≈ fock(7,8)
    @test get_inverse(CCX) == CCX
   
    ψ_0 = fock(0,2)
    ψ_1 = fock(1,2)

    S = phase(1)
    @test get_instruction_symbol(S) == "s"
    @test get_display_symbol(S) ==["S"]
    @test S*ψ_0 ≈ ψ_0
    @test S*ψ_1 ≈ im*ψ_1

    T = pi_8(1)
    @test get_instruction_symbol(T) == "t"
    @test get_display_symbol(T) ==["T"]
    @test T*ψ_0 ≈ ψ_0
    @test T*ψ_1 ≈ exp(im*pi/4.0)*ψ_1

    x90 = x_90(1)
    @test get_instruction_symbol(x90) == "x_90"
    @test get_display_symbol(x90) ==["X_90"]
    @test x90*ψ_0 ≈  rotation_x(1, pi/2)*ψ_0
    @test x90*ψ_1 ≈ rotation_x(1, pi/2)*ψ_1

    r = rotation(1, pi/2, pi/2)
    @test get_instruction_symbol(r) == "r"
    @test get_display_symbol(r) == ["R(θ=1.5708,ϕ=1.5708)"]
    @test r*ψ_0 ≈ 1/2^.5*(ψ_0+ψ_1)
    @test r*ψ_1 ≈ 1/2^.5*(-ψ_0+ψ_1)
    @test get_parameters(r)==Dict("theta"=>pi/2,"phi"=>pi/2)

    println(r)

    rx = rotation_x(1, pi/2)
    @test get_instruction_symbol(rx) == "rx"
    @test get_display_symbol(rx) ==["Rx(1.5708)"]
    @test rx*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test rx*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)
    @test get_parameters(rx)==Dict("theta"=>pi/2)

    ry = rotation_y(1, -pi/2)
    @test get_instruction_symbol(ry) == "ry"
    @test get_display_symbol(ry) ==["Ry(-1.5708)"]
    @test ry*ψ_0 ≈ 1/2^.5*(ψ_0-ψ_1)
    @test ry*ψ_1 ≈ 1/2^.5*(ψ_0+ψ_1)
    @test get_parameters(ry)==Dict("theta"=>-pi/2)

    rz = rotation_z(1, pi/2)
    @test get_instruction_symbol(rz) == "rz"
    @test get_display_symbol(rz) ==["Rz(1.5708)"]
    @test rz*Ket([1/2^.5; 1/2^.5]) ≈ Ket([0.5-im*0.5; 0.5+im*0.5])
    @test rz*ψ_0 ≈ Ket([1/2^.5-im/2^.5; 0])
    @test get_parameters(rz)==Dict("theta"=>pi/2)

    p = phase_shift(1, pi/4)
    @test get_instruction_symbol(p) == "p"
    @test get_display_symbol(p) ==["P(0.7854)"]
    @test p*Ket([1/2^.5; 1/2^.5]) ≈ Ket([1/2^.5, exp(im*pi/4)/2^.5])
    @test get_parameters(p)==Dict("phi"=>pi/4)


    u = universal(1, pi/2, -pi/2, pi/2)
    @test get_instruction_symbol(u) == "u"
    @test get_display_symbol(u) ==["U(θ=1.5708,ϕ=-1.5708,λ=1.5708)"]
    @test u*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test u*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)
    @test get_parameters(u)==Dict(
        "theta" =>pi/2,
        "phi"   =>-pi/2,
        "lambda"=>pi/2
        )

end

@testset "adjoint_gates" begin
    initial_state_10 = Ket([0, 0, 1, 0])
    iswap_dag=iswap_dagger(1, 2)
    @test iswap(1, 2)*(iswap_dag*initial_state_10) ≈ initial_state_10
    @test get_instruction_symbol(iswap_dag) == "iswap_dag"
    @test get_display_symbol(iswap_dag) ==["x†", "x†"]

    initial_state_1 = Ket([0, 1])
    pi_8_dag=pi_8_dagger(1)
    @test pi_8_dag*(pi_8(1)*initial_state_1) ≈ initial_state_1
    @test get_instruction_symbol(pi_8_dag) == "t_dag"
    @test get_display_symbol(pi_8_dag) ==["T†"]

    phase_dag=phase_dagger(1)
    @test phase_dag*(phase(1)*initial_state_1) ≈ initial_state_1
    @test get_instruction_symbol(phase_dag) == "s_dag"
    @test get_display_symbol(phase_dag) ==["S†"]
end

@testset "get_inverse" begin
    cnot = control_x(1, 2)
    @test test_inverse(cnot)
    inverse_cnot = get_inverse(cnot)
    @test get_connected_qubits(cnot)==get_connected_qubits(inverse_cnot)

    cz = control_z(1, 2)
    @test test_inverse(cz)
    inverse_cz = get_inverse(cz)
    @test get_connected_qubits(cz)==get_connected_qubits(inverse_cz)

    rx = rotation_x(1, pi/3)
    @test test_inverse(rx)
    inverse_rx = get_inverse(rx)
    @test get_connected_qubits(rx)==get_connected_qubits(inverse_rx)

    ry = rotation_y(1, pi/3)
    @test test_inverse(ry)
    inverse_ry = get_inverse(ry)
    @test get_connected_qubits(ry)==get_connected_qubits(inverse_ry)

    rz = rotation_z(1, pi/3)
    @test test_inverse(rz)
    inverse_rz = get_inverse(rz)
    @test get_connected_qubits(rz)==get_connected_qubits(inverse_rz)
   
    p = phase_shift(1, pi/3)
    @test test_inverse(p)
    inverse_p = get_inverse(p)
    @test get_connected_qubits(p)==get_connected_qubits(inverse_p)

    x_90_gate = x_90(1)
    @test test_inverse(x_90_gate)
    inverse_x_90 = get_inverse(x_90_gate)
    @test get_connected_qubits(x_90_gate)==get_connected_qubits(inverse_x_90)
    @test get_instruction_symbol(inverse_x_90) == "rx"
    @test get_display_symbol(inverse_x_90) ==["Rx(-1.5708)"]

    s = phase(1)
    @test test_inverse(s)
    inverse_s = get_inverse(s)
    @test get_connected_qubits(s)==get_connected_qubits(inverse_s)
    @test eye() ≈ get_operator(s)*get_operator(inverse_s)
    @test get_instruction_symbol(inverse_s) == "s_dag"
    @test get_display_symbol(inverse_s) ==["S†"]

    s_dag = phase_dagger(1)
    @test test_inverse(s_dag)
    inverse_s_dag = get_inverse(s)
    @test get_connected_qubits(s_dag)==get_connected_qubits(inverse_s_dag)
    @test get_instruction_symbol(s_dag) == "s_dag"
    @test get_display_symbol(s_dag) ==["S†"]


    t = pi_8(1)
    @test test_inverse(t)
    inverse_t = get_inverse(t)
    @test get_connected_qubits(t)==get_connected_qubits(inverse_t)
    @test get_instruction_symbol(inverse_t) == "t_dag"
    @test get_display_symbol(inverse_t) ==["T†"]

    
    t_dag = pi_8_dagger(1)
    @test test_inverse(t_dag)
    inverse_t_dag = get_inverse(t_dag)
    @test get_connected_qubits(t_dag)==get_connected_qubits(inverse_t_dag)
    @test get_instruction_symbol(inverse_t_dag) == "t"
    @test get_display_symbol(inverse_t_dag) ==["T"]

    
    iswap_gate = iswap(1, 2)
    @test test_inverse(iswap_gate) 
    inverse_iswap = get_inverse(iswap_gate)
    @test get_connected_qubits(iswap_gate)==get_connected_qubits(inverse_iswap)
    @test get_instruction_symbol(inverse_iswap) == "iswap_dag"
    @test get_display_symbol(inverse_iswap) ==["x†", "x†"]

    iswap_dag = iswap_dagger(1, 2)
    @test test_inverse(iswap_dag)
    inverse_iswap_dag = get_inverse(iswap_dag)
    @test get_connected_qubits(iswap_dag)==get_connected_qubits(inverse_iswap_dag)
    @test get_instruction_symbol(inverse_iswap_dag) == "iswap"
    @test get_display_symbol(inverse_iswap_dag) ==["x", "x"]


    r = rotation(1, pi/2, -pi/3)
    @test test_inverse(r)
    inverse_r = get_inverse(r)
    @test get_connected_qubits(r)==get_connected_qubits(inverse_r)


    u = universal(1, pi/2, -pi/3, pi/4)
    @test test_inverse(u)
    inverse_u = get_inverse(u)
    @test get_connected_qubits(u)==get_connected_qubits(inverse_u)

    struct UnknownGate <: AbstractGate
        instruction_symbol::String
    end
    
    Snowflake.get_operator(gate::UnknownGate) = DenseOperator([1 2; 3 4])

    unknown_gate=UnknownGate("na")
    @test_throws NotImplementedError get_inverse(unknown_gate)

    struct UnknownHermitianGate <: AbstractGate
        instruction_symbol::String
    end
    
    Snowflake.get_operator(gate::UnknownHermitianGate) = DenseOperator([1 im; -im 1])

    unknown_hermitian_gate = UnknownHermitianGate("na")
    @test get_inverse(unknown_hermitian_gate) == unknown_hermitian_gate
end


@testset "gate_set_exceptions" begin
    @test_throws DomainError control_x(1, 1)
end


@testset "ladder_operators" begin
    ψ_0 = fock(0,2)
    ψ_1 = fock(1,2)

    @test sigma_p()*ψ_1 ≈ ψ_0
    @test sigma_m()*ψ_0 ≈ ψ_1
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
    std_gates = ["x", "y", "z", "s", "t", "i", "h", "cx", "cz", "iswap", "ccx"]
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
