using Snowflake
using Test
using LinearAlgebra

include("test_functions.jl")

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

    @test eye(4)≈kron(eye(),eye())
    @test eye(8)≈kron(eye(4),eye())
    @test eye(6)≈kron(eye(3),eye(2))

    H = hadamard(1)
    h_oper=get_operator(H)
    @test h_oper ≈ hadamard()
    @test inv(H) == H
    @test get_instruction_symbol(H) == "h"
    @test get_display_symbol(H) ==["H"]

    println(H)

    @test get_matrix(2*h_oper) == get_matrix(h_oper).*2

    X = sigma_x(1)

    @test get_instruction_symbol(X) == "x"
    @test get_display_symbol(X) ==["X"]
    @test get_operator(X) ≈ sigma_x()
    @test inv(X) == X

    Y = sigma_y(1)
    @test get_instruction_symbol(Y) == "y"
    @test get_display_symbol(Y) ==["Y"]
    @test get_operator(Y) ≈ sigma_y()
    @test inv(Y) == Y

    Z = sigma_z(1)
    @test get_instruction_symbol(Z) == "z"
    @test get_display_symbol(Z) ==["Z"]
    @test get_operator(Z) ≈ sigma_z()
    @test inv(Z) == Z

    CX = control_x(1, 2)

    @test get_instruction_symbol(CX) == "cx"
    @test get_display_symbol(CX) ==["*", "X"]
    @test get_operator(CX) ≈ control_x()
    @test inv(CX) == CX

    CZ = control_z(1, 2)
    @test get_instruction_symbol(CZ) == "cz"
    @test get_display_symbol(CZ) ==["*", "Z"]
    @test get_operator(CZ) ≈ control_z()
    @test inv(CZ) == CZ

    SWAP = swap(1, 2)
    @test get_instruction_symbol(SWAP) == "swap"
    @test get_display_symbol(SWAP) == ["☒", "☒"]
    @test get_operator(SWAP) ≈ swap()
    @test inv(SWAP) == SWAP

    CCX = toffoli(1, 2, 3)
    @test get_instruction_symbol(CCX) == "ccx"
    @test get_display_symbol(CCX) ==["*", "*", "X"]
    @test CCX*fock(6,8) ≈ fock(7,8)
    @test CCX*fock(2,8) ≈ fock(2,8)
    @test CCX*fock(4,8) ≈ fock(4,8)
    @test toffoli(3, 1, 2)*fock(5,8) ≈ fock(7,8)
    @test inv(CCX) == CCX
   
    ψ_0 = fock(0,2)
    ψ_1 = fock(1,2)

    T = pi_8(1)
    @test get_instruction_symbol(T) == "t"
    @test get_display_symbol(T) ==["T"]
    @test T*ψ_0 ≈ ψ_0
    @test T*ψ_1 ≈ exp(im*pi/4.0)*ψ_1

    x90 = x_90(1)
    @test get_instruction_symbol(x90) == "x_90"
    @test get_display_symbol(x90) ==["X_90"]
    @test get_matrix(get_operator(x90)) ≈ (1/sqrt(2.0)) .* [
        1 -im;
        -im 1
    ]

    xm90 = x_minus_90(1)
    @test get_instruction_symbol(xm90) == "x_minus_90"
    @test get_display_symbol(xm90) ==["X_m90"]
    @test get_matrix(get_operator(xm90)) ≈ (1/sqrt(2.0)) .* [
        1 im;
        im 1
    ]

    y90 = y_90(1)
    @test get_instruction_symbol(y90) == "y_90"
    @test get_display_symbol(y90) ==["Y_90"]
    @test get_matrix(get_operator(y90)) ≈ (1/sqrt(2.0)) .* [
        1 -1;
        1 1
    ]

    ym90 = y_minus_90(1)
    @test get_instruction_symbol(ym90) == "y_minus_90"
    @test get_display_symbol(ym90) ==["Y_m90"]
    @test get_matrix(get_operator(ym90)) ≈ (1/sqrt(2.0)) .* [
        1 1;
        -1 1
    ]

    z90 = z_90(1)
    @test get_instruction_symbol(z90) == "z_90"
    @test get_display_symbol(z90) ==["Z_90"]
    @test get_matrix(get_operator(z90)) ≈ [
        1 0;
        0 im
    ]

    zm90 = z_minus_90(1)
    @test get_instruction_symbol(zm90) == "z_minus_90"
    @test get_display_symbol(zm90) ==["Z_m90"]
    @test get_matrix(get_operator(zm90)) ≈ [
        1 0;
        0 -im
    ]

    r = rotation(1, pi/2, pi/2)
    @test get_instruction_symbol(r) == "r"
    @test get_display_symbol(r) == ["R(θ=1.5708,ϕ=1.5708)"]
    @test r*ψ_0 ≈ 1/2^.5*(ψ_0+ψ_1)
    @test r*ψ_1 ≈ 1/2^.5*(-ψ_0+ψ_1)
    @test get_gate_parameters(r)==Dict("theta"=>pi/2,"phi"=>pi/2)

    println(r)

    rx = rotation_x(1, pi/2)
    @test get_instruction_symbol(rx) == "rx"
    @test get_display_symbol(rx) ==["Rx(1.5708)"]
    @test rx*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test rx*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)
    @test get_gate_parameters(rx)==Dict("theta"=>pi/2)

    ry = rotation_y(1, -pi/2)
    @test get_instruction_symbol(ry) == "ry"
    @test get_display_symbol(ry) ==["Ry(-1.5708)"]
    @test ry*ψ_0 ≈ 1/2^.5*(ψ_0-ψ_1)
    @test ry*ψ_1 ≈ 1/2^.5*(ψ_0+ψ_1)
    @test get_gate_parameters(ry)==Dict("theta"=>-pi/2)

    p = phase_shift(1, pi/4)
    @test get_instruction_symbol(p) == "p"
    @test get_display_symbol(p) ==["P(0.7854)"]
    @test p*Ket([1/2^.5; 1/2^.5]) ≈ Ket([1/2^.5, exp(im*pi/4)/2^.5])
    @test get_gate_parameters(p)==Dict("phi"=>pi/4)


    u = universal(1, pi/2, -pi/2, pi/2)
    @test get_instruction_symbol(u) == "u"
    @test get_display_symbol(u) ==["U(θ=1.5708,ϕ=-1.5708,λ=1.5708)"]
    @test u*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test u*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)
    @test get_gate_parameters(u)==Dict(
        "theta" =>pi/2,
        "phi"   =>-pi/2,
        "lambda"=>pi/2
        )

    iden = identity_gate(1)
    @test get_instruction_symbol(iden) == "i"
    @test get_display_symbol(iden) ==["I"]
    @test get_matrix(get_operator(iden)) ≈ get_matrix(eye())
    
    
    # ControlX   
    ψ_input=Ket([1.,2.,3.,4.])
    ψ_input_32=Ket(ComplexF32[1.,2.,3.,4.])

    ψ_1_2=Ket([1.,2.,4.,3.])
    ψ_2_1=Ket([1.,4.,3.,2.])
    
    @test ψ_1_2 ≈ control_x(1,2)*ψ_input
    @test ψ_2_1 ≈ control_x(2,1)*ψ_input

    @test typeof(control_x(1,2)*ψ_input_32)==Ket{ComplexF32}

    @test_throws DomainError control_x(1,10)*ψ_input
    

    # ControlZ
    ψ_input=Ket([1.,2.,3.,4.])
    ψ_input_32=Ket(ComplexF32[1.,2.,3.,4.])

    ψ_1_2=Ket([1.,2.,3.,-4.])
    
    @test ψ_1_2 ≈ control_z(1,2)*ψ_input
    @test ψ_1_2 ≈ control_z(2,1)*ψ_input

    @test typeof(control_x(1,2)*ψ_input_32)==Ket{ComplexF32}

    @test_throws DomainError control_x(1,10)*ψ_input

    #Toffoli
    ψ_input=Ket([1.,2.,3.,4.,5.,6.,7.,8.])
    ψ_input_32=Ket(ComplexF32[1.,2.,3.,4.,5.,6.,7.,8.])

    ψ_1_2_3=Ket([1.,2.,3.,4.,5.,6.,8.,7.])
    ψ_1_3_2=Ket([1.,2.,3.,4.,5.,8.,7.,6.])
    ψ_2_3_1=Ket([1.,2.,3.,8.,5.,6.,7.,4.])
    
    @test ψ_1_2_3 ≈ toffoli(1,2,3)*ψ_input
    @test ψ_1_2_3 ≈ toffoli(2,1,3)*ψ_input
    @test ψ_1_3_2 ≈ toffoli(1,3,2)*ψ_input
    @test ψ_1_3_2 ≈ toffoli(3,1,2)*ψ_input
    @test ψ_2_3_1 ≈ toffoli(2,3,1)*ψ_input
    @test ψ_2_3_1 ≈ toffoli(3,2,1)*ψ_input

    @test typeof(toffoli(1,2,3)*ψ_input_32)==Ket{ComplexF32}

    @test_throws DomainError toffoli(1,2,10)*ψ_input

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

end

@testset "inv" begin
    cnot = control_x(1, 2)
    @test test_inverse(cnot)
    inverse_cnot = inv(cnot)
    @test get_connected_qubits(cnot)==get_connected_qubits(inverse_cnot)
    @test get_control_qubits(cnot)==[1]
    @test get_target_qubits(cnot)==[2]
    @test get_control_qubits(cnot)==get_control_qubits(inverse_cnot)
    @test get_target_qubits(cnot)==get_target_qubits(inverse_cnot)

    cz = control_z(1, 2)
    @test test_inverse(cz)
    inverse_cz = inv(cz)
    @test get_connected_qubits(cz)==get_connected_qubits(inverse_cz)
    @test get_control_qubits(cz)==[1]
    @test get_target_qubits(cz)==[2]
    @test get_control_qubits(cz)==get_control_qubits(inverse_cz)
    @test get_target_qubits(cz)==get_target_qubits(inverse_cz)

    rx = rotation_x(1, pi/3)
    @test test_inverse(rx)
    inverse_rx = inv(rx)
    @test get_connected_qubits(rx)==get_connected_qubits(inverse_rx)


    ry = rotation_y(1, pi/3)
    @test test_inverse(ry)
    inverse_ry = inv(ry)
    @test get_connected_qubits(ry)==get_connected_qubits(inverse_ry)

 
    p = phase_shift(1, pi/3)
    @test test_inverse(p)
    inverse_p = inv(p)
    @test get_connected_qubits(p)==get_connected_qubits(inverse_p)

    x_90_gate = x_90(1)
    @test test_inverse(x_90_gate)
    inverse_x_90 = inv(x_90_gate)
    @test get_connected_qubits(x_90_gate)==get_connected_qubits(inverse_x_90)
    @test get_instruction_symbol(inverse_x_90) == "x_minus_90"
    @test get_display_symbol(inverse_x_90) ==["X_m90"]

    x_minus_90_gate = x_minus_90(1)
    @test test_inverse(x_minus_90_gate)
    inverse_x_minus_90 = inv(x_minus_90_gate)
    @test get_connected_qubits(x_minus_90_gate)==get_connected_qubits(inverse_x_minus_90)
    @test get_instruction_symbol(inverse_x_minus_90) == "x_90"
    @test get_display_symbol(inverse_x_minus_90) ==["X_90"]

    y_90_gate = y_90(1)
    @test test_inverse(y_90_gate)
    inverse_y_90 = inv(y_90_gate)
    @test get_connected_qubits(y_90_gate)==get_connected_qubits(inverse_y_90)
    @test get_instruction_symbol(inverse_y_90) == "y_minus_90"
    @test get_display_symbol(inverse_y_90) ==["Y_m90"]

    y_minus_90_gate = y_minus_90(1)
    @test test_inverse(y_minus_90_gate)
    inverse_y_minus_90 = inv(y_minus_90_gate)
    @test get_connected_qubits(y_minus_90_gate)==get_connected_qubits(inverse_y_minus_90)
    @test get_instruction_symbol(inverse_y_minus_90) == "y_90"
    @test get_display_symbol(inverse_y_minus_90) ==["Y_90"]

    z_90_gate = z_90(1)
    @test test_inverse(z_90_gate)
    inverse_z_90 = inv(z_90_gate)
    @test get_connected_qubits(z_90_gate)==get_connected_qubits(inverse_z_90)
    @test get_instruction_symbol(inverse_z_90) == "z_minus_90"
    @test get_display_symbol(inverse_z_90) ==["Z_m90"]

    z_minus_90_gate = z_minus_90(1)
    @test test_inverse(z_minus_90_gate)
    inverse_z_minus_90 = inv(z_minus_90_gate)
    @test get_connected_qubits(z_minus_90_gate)==get_connected_qubits(inverse_z_minus_90)
    @test get_instruction_symbol(inverse_z_minus_90) == "z_90"
    @test get_display_symbol(inverse_z_minus_90) ==["Z_90"]

    t = pi_8(1)
    @test test_inverse(t)
    inverse_t = inv(t)
    @test get_connected_qubits(t)==get_connected_qubits(inverse_t)
    @test get_instruction_symbol(inverse_t) == "t_dag"
    @test get_display_symbol(inverse_t) ==["T†"]
    
    t_dag = pi_8_dagger(1)
    @test test_inverse(t_dag)
    inverse_t_dag = inv(t_dag)
    @test get_connected_qubits(t_dag)==get_connected_qubits(inverse_t_dag)
    @test get_instruction_symbol(inverse_t_dag) == "t"
    @test get_display_symbol(inverse_t_dag) ==["T"]
    
    iswap_gate = iswap(1, 2)
    @test test_inverse(iswap_gate) 
    inverse_iswap = inv(iswap_gate)
    @test get_connected_qubits(iswap_gate)==get_connected_qubits(inverse_iswap)
    @test get_instruction_symbol(inverse_iswap) == "iswap_dag"
    @test get_display_symbol(inverse_iswap) ==["x†", "x†"]

    iswap_dag = iswap_dagger(1, 2)
    @test test_inverse(iswap_dag)
    inverse_iswap_dag = inv(iswap_dag)
    @test get_connected_qubits(iswap_dag)==get_connected_qubits(inverse_iswap_dag)
    @test get_instruction_symbol(inverse_iswap_dag) == "iswap"
    @test get_display_symbol(inverse_iswap_dag) ==["x", "x"]

    r = rotation(1, pi/2, -pi/3)
    @test test_inverse(r)
    inverse_r = inv(r)
    @test get_connected_qubits(r)==get_connected_qubits(inverse_r)

    u = universal(1, pi/2, -pi/3, pi/4)
    @test test_inverse(u)
    inverse_u = inv(u)
    @test get_connected_qubits(u)==get_connected_qubits(inverse_u)

    iden = identity_gate(1)
    @test test_inverse(iden)
    inverse_iden = inv(iden)
    @test get_connected_qubits(iden)==get_connected_qubits(inverse_iden)

    struct UnknownGate <: AbstractGate
        instruction_symbol::String
    end
    
    Snowflake.get_operator(gate::UnknownGate) = DenseOperator([1 2; 3 4])

    unknown_gate=UnknownGate("na")
    @test_throws NotImplementedError inv(unknown_gate)

    struct UnknownHermitianGate <: AbstractGate
        instruction_symbol::String
    end
    
    Snowflake.get_operator(gate::UnknownHermitianGate) = DenseOperator([1 im; -im 1])

    unknown_hermitian_gate = UnknownHermitianGate("na")

    # test fallback implementation of inv(::AbstractGate)
    @test inv(unknown_hermitian_gate) == unknown_hermitian_gate

    struct UnknownControlledGate<:AbstractControlledGate end

    @test_throws NotImplementedError get_target_qubits(UnknownControlledGate())
    @test_throws NotImplementedError get_control_qubits(UnknownControlledGate())

end

@testset "move_gate" begin
    target = 2
    theta = pi/2
    rx_gate = rotation_x(target, theta)
    qubit_mapping = Dict(2=>3)
    moved_rx_gate = move_gate(rx_gate, qubit_mapping)
    @test_throws NotImplementedError get_control_qubits(moved_rx_gate)
    @test_throws NotImplementedError get_target_qubits(moved_rx_gate)
    
    qubit_mapping = Dict(1=>3, 3=>1)
    untouched_rx_gate = move_gate(rx_gate, qubit_mapping)
    @test is_gate_type(untouched_rx_gate, Snowflake.RotationX)
    @test get_gate_type(untouched_rx_gate) == Snowflake.RotationX
    @test get_connected_qubits(untouched_rx_gate) == [target]
    @test get_gate_parameters(untouched_rx_gate) == Dict("theta"=>theta)

    qubit_mapping = Dict(2=>3, 3=>2)
    moved_rx_gate = move_gate(rx_gate, qubit_mapping)
    @test is_gate_type(moved_rx_gate, Snowflake.RotationX)
    @test get_gate_type(moved_rx_gate) == Snowflake.RotationX
    @test get_connected_qubits(moved_rx_gate) == [3]
    @test get_gate_parameters(moved_rx_gate) == Dict("theta"=>theta)

    moved_twice_rx = move_gate(moved_rx_gate, qubit_mapping)
    @test is_gate_type(moved_twice_rx, Snowflake.RotationX)
    @test get_gate_type(moved_twice_rx) == Snowflake.RotationX
    @test get_connected_qubits(moved_twice_rx) == [2]
    @test get_gate_parameters(moved_twice_rx) == Dict("theta"=>theta)
    
    inverse_moved_gate = inv(moved_rx_gate)
    @test is_gate_type(inverse_moved_gate, Snowflake.RotationX)
    @test get_connected_qubits(inverse_moved_gate) == [3]
    @test get_gate_parameters(inverse_moved_gate) == Dict("theta"=>-theta)

    qubit_mapping = Dict(2=>3, 3=>2, 4=>1, 1=>4)
    toffoli_gate = toffoli(2, 3, 1)
    moved_toffoli_gate = move_gate(toffoli_gate, qubit_mapping)
    @test is_gate_type(moved_toffoli_gate, Snowflake.Toffoli)
    @test get_connected_qubits(moved_toffoli_gate) == [3, 2, 4]

    qubit_mapping = Dict(2=>22, 3=>33,4=>44)
    toffoli_gate = toffoli(2, 3, 4)
    @test get_connected_qubits(toffoli_gate) == [2, 3, 4]
    @test get_control_qubits(toffoli_gate)==[2,3]
    @test get_target_qubits(toffoli_gate)==[4]

    moved_toffoli_gate = move_gate(toffoli_gate, qubit_mapping)
    @test is_gate_type(moved_toffoli_gate, Snowflake.Toffoli)
    @test get_connected_qubits(moved_toffoli_gate) == [22, 33, 44]
    @test get_control_qubits(moved_toffoli_gate)==[22,33]
    @test get_target_qubits(moved_toffoli_gate)==[44]

    inv_moved_toffoli_gate=inv(moved_toffoli_gate)

    @test inv_moved_toffoli_gate==moved_toffoli_gate
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

@testset "invariance to permutation of controls (or targets for swap)" begin
    c0 = QuantumCircuit(qubit_count = 4, gates=[toffoli(3,4,2)])
    c1 = QuantumCircuit(qubit_count = 4, gates=[toffoli(4,3,2)])

    @test compare_circuits(c0,c1)

    c0 = QuantumCircuit(qubit_count = 3, gates=[toffoli(2,3,1)])
    c1 = QuantumCircuit(qubit_count = 3, gates=[toffoli(3,2,1)])

    @test compare_circuits(c0,c1)

    c0 = QuantumCircuit(qubit_count = 3, gates=[swap(2,3)])
    c1 = QuantumCircuit(qubit_count = 3, gates=[swap(3,2)])

    @test compare_circuits(c0,c1)

end

@testset "regression test: cnot inverse identity" begin 
    q1 = 2 
    q2 = 4 
    qubit_count = 5 
    cnot_circuit = QuantumCircuit(qubit_count=qubit_count, gates=[ control_x(q1, q2)] ) 
    inverted_cnot_circuit = QuantumCircuit(
        qubit_count=qubit_count,
        gates=[ 
            hadamard(q1), 
            hadamard(q2), 
            control_x(q2, q1), 
            hadamard(q1), 
            hadamard(q2), 
        ])
        
    @test compare_circuits(cnot_circuit, inverted_cnot_circuit) 
end
