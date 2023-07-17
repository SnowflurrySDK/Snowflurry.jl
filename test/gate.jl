using Snowflurry
using Test
using LinearAlgebra

include("test_functions.jl")

@testset "Gate" begin
    struct MockNumConnectedQubit <: AbstractGateSymbol
        num_connected_qubits::Int
    end

    Snowflurry.get_num_connected_qubits(gate::MockNumConnectedQubit) = return gate.num_connected_qubits

    @testset "constructor" begin

        function test_domain_error_on_mismatched_connected_qubits(num_connected_qubits::Int, connected_qubits::Vector{Int})
            @test_throws DomainError Gate(MockNumConnectedQubit(num_connected_qubits), connected_qubits)
        end

        test_domain_error_on_mismatched_connected_qubits(1, Vector{Int}([]))
        test_domain_error_on_mismatched_connected_qubits(1, [1, 2])
        test_domain_error_on_mismatched_connected_qubits(0, [1])
        test_domain_error_on_mismatched_connected_qubits(0, [7, 9])
        test_domain_error_on_mismatched_connected_qubits(6, [6])
        test_domain_error_on_mismatched_connected_qubits(6, [1, 3, 7])


        function test_success(num_connected_qubits::Int, connected_qubits::Vector{Int})
            gate = Gate(MockNumConnectedQubit(num_connected_qubits), connected_qubits)
        end

        test_success(0, Vector{Int}([]))
        test_success(1, [1])
        test_success(1, [6])
        test_success(2, [1, 2])
        test_success(2, [7, 9])
        test_success(6, [1, 3, 7, 99, 2, 11])
    end

    @testset "show" begin
        function test_show(gate_placement::Gate, expected::String)
            io = IOBuffer()

            Base.show(io, gate_placement)
            actual = String(take!(io))

            println(actual)
            println(expected)

            @test actual == expected
        end

        test_show(
            iswap(1, 2),
            """Gate Object: Snowflurry.ISwap
            Connected_qubits	: [1, 2]
            Operator:
            (4, 4)-element Snowflurry.SwapLikeOperator:
            Underlying data ComplexF64:
            Equivalent DenseOperator:
            1.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im
            0.0 + 0.0im    0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im
            0.0 + 0.0im    0.0 + 1.0im    0.0 + 0.0im    0.0 + 0.0im
            0.0 + 0.0im    0.0 + 0.0im    0.0 + 0.0im    1.0 + 0.0im
            """
        )

        test_show(
            universal(3, pi/2, -pi/2, pi/2),
            """Gate Object: Snowflurry.Universal
            Parameters: 
            theta	: 1.5707963267948966
            phi	: -1.5707963267948966
            lambda	: 1.5707963267948966
            
            Connected_qubits	: [3]
            Operator:
            (2, 2)-element Snowflurry.DenseOperator:
            Underlying data ComplexF64:
            0.7071067811865476 + 0.0im    -4.329780281177466e-17 - 0.7071067811865475im
            4.329780281177466e-17 - 0.7071067811865475im    0.7071067811865476 + 0.0im
            """
        )
    end

    @testset "getters" begin
        function test_getters(symbol::AbstractGateSymbol, connected_qubits::Vector{Int})
            gate = Gate(symbol, connected_qubits)

            @test get_connected_qubits(gate) == connected_qubits
            @test get_gate_symbol(gate) == symbol
        end

        test_getters(Snowflurry.Hadamard(), [3])
        test_getters(Snowflurry.ISwap(), [7, 3])
        test_getters(Snowflurry.Universal(pi/2, -pi/2, pi/4), [11])
    end

    @testset "throw domain error when connected qubits are not unique" begin
        function test_dissallow_non_unique_connected_qubits(symbol::AbstractGateSymbol, connected_qubits::Vector{Int})
            @test_throws DomainError Gate(symbol, connected_qubits)
        end

        test_dissallow_non_unique_connected_qubits(Snowflurry.ISwap(), [3, 3])
        test_dissallow_non_unique_connected_qubits(Snowflurry.Toffoli(), [1,1,2])
        test_dissallow_non_unique_connected_qubits(Snowflurry.Toffoli(), [1,2,1])
        test_dissallow_non_unique_connected_qubits(Snowflurry.Toffoli(), [2,1,1])
    end
end

@testset "controlled" begin
    @testset "throw domain error when target and control qubits are not unique" begin
        function test_dissallow_non_unique_target_and_control_qubits(gate::Gate, control_qubits::Vector{Int})
            @test_throws DomainError Snowflurry.controlled(gate, control_qubits)
        end

        test_dissallow_non_unique_target_and_control_qubits(sigma_x(1), [1])
        test_dissallow_non_unique_target_and_control_qubits(hadamard(3), [3])
        test_dissallow_non_unique_target_and_control_qubits(hadamard(7), [1,7])
        test_dissallow_non_unique_target_and_control_qubits(hadamard(7), [7,1])
        test_dissallow_non_unique_target_and_control_qubits(iswap(1,2), [1])
        test_dissallow_non_unique_target_and_control_qubits(iswap(1,2), [2])
        test_dissallow_non_unique_target_and_control_qubits(iswap(1,2), [1,2])
        test_dissallow_non_unique_target_and_control_qubits(iswap(1,2), [3,4,1])
        test_dissallow_non_unique_target_and_control_qubits(iswap(1,2), [3,4,2])
    end
end

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
    h_oper=get_operator(get_gate_symbol(H))
    @test h_oper ≈ hadamard()
    @test inv(H) == H
    @test get_instruction_symbol(get_gate_symbol(H)) == "h"
    @test get_symbol_for_instruction("h") == Snowflurry.Hadamard
    @test get_display_symbol(get_gate_symbol(H)) ==["H"]

    @test get_matrix(2*h_oper) == get_matrix(h_oper).*2

    X = sigma_x(1)

    @test get_instruction_symbol(get_gate_symbol(X)) == "x"
    @test get_symbol_for_instruction("x") == Snowflurry.SigmaX
    @test get_display_symbol(get_gate_symbol(X)) ==["X"]
    @test get_operator(get_gate_symbol(X)) ≈ sigma_x()
    @test inv(X) == X

    Y = sigma_y(1)
    @test get_instruction_symbol(get_gate_symbol(Y)) == "y"
    @test get_symbol_for_instruction("y") == Snowflurry.SigmaY
    @test get_display_symbol(get_gate_symbol(Y)) ==["Y"]
    @test get_operator(get_gate_symbol(Y)) ≈ sigma_y()
    @test inv(Y) == Y

    Z = sigma_z(1)
    @test get_instruction_symbol(get_gate_symbol(Z)) == "z"
    @test get_symbol_for_instruction("z") == Snowflurry.SigmaZ
    @test get_display_symbol(get_gate_symbol(Z)) ==["Z"]
    @test get_operator(get_gate_symbol(Z)) ≈ sigma_z()
    @test inv(Z) == Z

    CX = control_x(1, 2)

    @test get_instruction_symbol(get_gate_symbol(CX)) == "cx"
    @test get_symbol_for_instruction("cx") == Snowflurry.ControlX
    @test get_display_symbol(get_gate_symbol(CX)) ==["*", "X"]
    @test get_operator(get_gate_symbol(CX)) ≈ control_x()
    @test inv(CX) == CX

    CZ = control_z(1, 2)
    @test get_instruction_symbol(get_gate_symbol(CZ)) == "cz"
    @test get_symbol_for_instruction("cz") == Snowflurry.ControlZ
    @test get_display_symbol(get_gate_symbol(CZ)) ==["*", "Z"]
    @test get_operator(get_gate_symbol(CZ)) ≈ control_z()
    @test inv(CZ) == CZ

    SWAP = swap(1, 2)
    @test get_instruction_symbol(get_gate_symbol(SWAP)) == "swap"
    @test get_symbol_for_instruction("swap") == Snowflurry.Swap
    @test get_display_symbol(get_gate_symbol(SWAP)) == ["☒", "☒"]
    @test get_operator(get_gate_symbol(SWAP)) ≈ swap()
    @test inv(SWAP) == SWAP

    CCX = toffoli(1, 2, 3)
    @test get_instruction_symbol(get_gate_symbol(CCX)) == "ccx"
    @test get_symbol_for_instruction("ccx") == Snowflurry.Toffoli
    @test get_display_symbol(get_gate_symbol(CCX)) ==["*", "*", "X"]
    @test CCX*fock(6,8) ≈ fock(7,8)
    @test CCX*fock(2,8) ≈ fock(2,8)
    @test CCX*fock(4,8) ≈ fock(4,8)
    @test toffoli(3, 1, 2)*fock(5,8) ≈ fock(7,8)
    @test inv(CCX) == CCX
   
    ψ_0 = fock(0,2)
    ψ_1 = fock(1,2)

    T = pi_8(1)
    @test get_instruction_symbol(get_gate_symbol(T)) == "t"
    @test get_symbol_for_instruction("t") == Snowflurry.Pi8
    @test get_display_symbol(get_gate_symbol(T)) ==["T"]
    @test T*ψ_0 ≈ ψ_0
    @test T*ψ_1 ≈ exp(im*pi/4.0)*ψ_1

    x90 = x_90(1)
    @test get_instruction_symbol(get_gate_symbol(x90)) == "x_90"
    @test get_symbol_for_instruction("x_90") == Snowflurry.X90
    @test get_display_symbol(get_gate_symbol(x90)) ==["X_90"]
    @test get_matrix(get_operator(get_gate_symbol(x90))) ≈ (1/sqrt(2.0)) .* [
        1 -im;
        -im 1
    ]

    xm90 = x_minus_90(1)
    @test get_instruction_symbol(get_gate_symbol(xm90)) == "x_minus_90"
    @test get_symbol_for_instruction("x_minus_90") == Snowflurry.XM90
    @test get_display_symbol(get_gate_symbol(xm90)) ==["X_m90"]
    @test get_matrix(get_operator(get_gate_symbol(xm90))) ≈ (1/sqrt(2.0)) .* [
        1 im;
        im 1
    ]

    y90 = y_90(1)
    @test get_instruction_symbol(get_gate_symbol(y90)) == "y_90"
    @test get_symbol_for_instruction("y_90") == Snowflurry.Y90
    @test get_display_symbol(get_gate_symbol(y90)) ==["Y_90"]
    @test get_matrix(get_operator(get_gate_symbol(y90))) ≈ (1/sqrt(2.0)) .* [
        1 -1;
        1 1
    ]

    ym90 = y_minus_90(1)
    @test get_instruction_symbol(get_gate_symbol(ym90)) == "y_minus_90"
    @test get_symbol_for_instruction("y_minus_90") == Snowflurry.YM90
    @test get_display_symbol(get_gate_symbol(ym90)) ==["Y_m90"]
    @test get_matrix(get_operator(get_gate_symbol(ym90))) ≈ (1/sqrt(2.0)) .* [
        1 1;
        -1 1
    ]

    z90 = z_90(1)
    @test get_instruction_symbol(get_gate_symbol(z90)) == "z_90"
    @test get_symbol_for_instruction("z_90") == Snowflurry.Z90
    @test get_display_symbol(get_gate_symbol(z90)) ==["Z_90"]
    @test get_matrix(get_operator(get_gate_symbol(z90))) ≈ [
        1 0;
        0 im
    ]

    zm90 = z_minus_90(1)
    @test get_instruction_symbol(get_gate_symbol(zm90)) == "z_minus_90"
    @test get_symbol_for_instruction("z_minus_90") == Snowflurry.ZM90
    @test get_display_symbol(get_gate_symbol(zm90)) ==["Z_m90"]
    @test get_matrix(get_operator(get_gate_symbol(zm90))) ≈ [
        1 0;
        0 -im
    ]

    r = rotation(1, pi/2, pi/2)
    @test get_instruction_symbol(get_gate_symbol(r)) == "r"
    @test get_symbol_for_instruction("r") == Snowflurry.Rotation
    @test get_display_symbol(get_gate_symbol(r)) == ["R(θ=1.5708,ϕ=1.5708)"]
    @test r*ψ_0 ≈ 1/2^.5*(ψ_0+ψ_1)
    @test r*ψ_1 ≈ 1/2^.5*(-ψ_0+ψ_1)
    @test get_gate_parameters(get_gate_symbol(r))==Dict("theta"=>pi/2,"phi"=>pi/2)

    rx = rotation_x(1, pi/2)
    @test get_instruction_symbol(get_gate_symbol(rx)) == "rx"
    @test get_symbol_for_instruction("rx") == Snowflurry.RotationX
    @test get_display_symbol(get_gate_symbol(rx)) ==["Rx(1.5708)"]
    @test rx*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test rx*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)
    @test get_gate_parameters(get_gate_symbol(rx))==Dict("theta"=>pi/2)

    ry = rotation_y(1, -pi/2)
    @test get_instruction_symbol(get_gate_symbol(ry)) == "ry"
    @test get_symbol_for_instruction("ry") == Snowflurry.RotationY
    @test get_display_symbol(get_gate_symbol(ry)) ==["Ry(-1.5708)"]
    @test ry*ψ_0 ≈ 1/2^.5*(ψ_0-ψ_1)
    @test ry*ψ_1 ≈ 1/2^.5*(ψ_0+ψ_1)
    @test get_gate_parameters(get_gate_symbol(ry))==Dict("theta"=>-pi/2)

    p = phase_shift(1, pi/4)
    @test get_instruction_symbol(get_gate_symbol(p)) == "rz"
    @test get_symbol_for_instruction("rz") == Snowflurry.PhaseShift
    @test get_display_symbol(get_gate_symbol(p)) ==["Rz(0.7854)"]
    @test p*Ket([1/2^.5; 1/2^.5]) ≈ Ket([1/2^.5, exp(im*pi/4)/2^.5])
    @test get_gate_parameters(get_gate_symbol(p))==Dict("lambda"=>pi/4)


    u = universal(1, pi/2, -pi/2, pi/2)
    @test get_instruction_symbol(get_gate_symbol(u)) == "u"
    @test get_symbol_for_instruction("u") == Snowflurry.Universal
    @test get_display_symbol(get_gate_symbol(u)) ==["U(θ=1.5708,ϕ=-1.5708,λ=1.5708)"]
    @test u*ψ_0 ≈ 1/2^.5*(ψ_0-im*ψ_1)
    @test u*ψ_1 ≈ 1/2^.5*(-im*ψ_0+ψ_1)
    @test get_gate_parameters(get_gate_symbol(u))==Dict(
        "theta" =>pi/2,
        "phi"   =>-pi/2,
        "lambda"=>pi/2
        )

    iden = identity_gate(1)
    @test get_instruction_symbol(get_gate_symbol(iden)) == "i"
    @test get_symbol_for_instruction("i") == Snowflurry.Identity
    @test get_display_symbol(get_gate_symbol(iden)) ==["I"]
    @test get_matrix(get_operator(get_gate_symbol(iden))) ≈ get_matrix(eye())
    
    
    # ControlX   
    ψ_input=Ket([1.,2.,3.,4.])
    ψ_input_32=Ket(ComplexF32[1.,2.,3.,4.])

    ψ_1_2=Ket([1.,2.,4.,3.])
    ψ_2_1=Ket([1.,4.,3.,2.])
    
    @test ψ_1_2 ≈ control_x(1,2)*ψ_input
    @test ψ_2_1 ≈ control_x(2,1)*ψ_input

    @test typeof(control_x(1,2)*ψ_input_32)==Ket{ComplexF32}

    @test_throws DomainError control_x(1,10)*ψ_input
    
    # ControlX as Controlled

    cnot_kernel_1_2=controlled(sigma_x(2),[1])
    cnot_kernel_2_1=controlled(sigma_x(1),[2])

    @test ψ_1_2 ≈ cnot_kernel_1_2*ψ_input
    @test ψ_2_1 ≈ cnot_kernel_2_1*ψ_input

    @test typeof(cnot_kernel_1_2*ψ_input_32)==Ket{ComplexF32}
    @test get_display_symbol(get_gate_symbol(cnot_kernel_1_2)) ==["*", "X"]

    # ControlZ
    ψ_input=Ket([1.,2.,3.,4.])
    ψ_input_32=Ket(ComplexF32[1.,2.,3.,4.])

    ψ_1_2=Ket([1.,2.,3.,-4.])
    
    @test ψ_1_2 ≈ control_z(1,2)*ψ_input
    @test ψ_1_2 ≈ control_z(2,1)*ψ_input

    @test typeof(control_x(1,2)*ψ_input_32)==Ket{ComplexF32}

    @test_throws DomainError control_x(1,10)*ψ_input

    # ControlZ as Controlled

    cz_kernel_1_2=controlled(sigma_z(2),[1])
    cz_kernel_2_1=controlled(sigma_z(1),[2])

    @test ψ_1_2 ≈ cz_kernel_1_2*ψ_input
    @test ψ_1_2 ≈ cz_kernel_2_1*ψ_input

    @test typeof(cz_kernel_1_2*ψ_input_32)==Ket{ComplexF32}
    @test get_display_symbol(get_gate_symbol(cz_kernel_1_2)) ==["*", "Z"]

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

    # Toffoli as Controlled

    toffoli_kernel_1_2_3=controlled(sigma_x(3),[1,2])
    toffoli_kernel_2_1_3=controlled(sigma_x(3),[2,1])
    toffoli_kernel_1_3_2=controlled(sigma_x(2),[1,3])
    toffoli_kernel_3_1_2=controlled(sigma_x(2),[3,1])
    toffoli_kernel_2_3_1=controlled(sigma_x(1),[2,3])
    toffoli_kernel_3_2_1=controlled(sigma_x(1),[3,2])

    @test ψ_1_2_3 ≈ toffoli_kernel_1_2_3*ψ_input
    @test ψ_1_2_3 ≈ toffoli_kernel_2_1_3*ψ_input
    @test ψ_1_3_2 ≈ toffoli_kernel_1_3_2*ψ_input
    @test ψ_1_3_2 ≈ toffoli_kernel_3_1_2*ψ_input
    @test ψ_2_3_1 ≈ toffoli_kernel_2_3_1*ψ_input
    @test ψ_2_3_1 ≈ toffoli_kernel_3_2_1*ψ_input

    @test typeof(toffoli_kernel_1_2_3*ψ_input_32)==Ket{ComplexF32}
    @test get_display_symbol(get_gate_symbol(toffoli_kernel_1_2_3)) ==["*", "*", "X"]

    # ControlledHadamard as Controlled
    controlled_hadamard_kernel_1_2=controlled(hadamard(2),[1])
    controlled_hadamard_kernel_2_1=controlled(hadamard(1),[2])

    # ControlledHadamard as Dense AbstractControlledSymbol
    struct ControlledHadamard <: AbstractGateSymbol
    end
    
    control_hadamard(T::Type{<:Complex}=ComplexF64) = DenseOperator(
        T[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, sqrt(2)/2, sqrt(2)/2] [
                0.0,
                0.0,
                sqrt(2)/2,
                -sqrt(2)/2,
        ]],
    )

    Snowflurry.get_num_connected_qubits(ch::ControlledHadamard) = 2

    Snowflurry.get_operator(::ControlledHadamard, T::Type{<:Complex}=ComplexF64) = control_hadamard(T)
    

    controlled_hadamard_dense_1_2=Gate(ControlledHadamard(), [1,2])
    controlled_hadamard_dense_2_1=Gate(ControlledHadamard(), [2,1])
  
    @test get_operator(get_gate_symbol(controlled_hadamard_kernel_1_2)) ≈ get_operator(get_gate_symbol(controlled_hadamard_dense_1_2))

    @test get_operator(get_gate_symbol(controlled_hadamard_kernel_1_2)) isa DenseOperator{4, ComplexF64}
    @test get_operator(get_gate_symbol(controlled_hadamard_kernel_1_2),ComplexF32) isa DenseOperator{4, ComplexF32}

    ψ_input=Ket([1.,2.,3.,4.])
    ψ_input_32=Ket(ComplexF32[1.,2.,3.,4.])
    
    @test controlled_hadamard_kernel_1_2*ψ_input ≈ controlled_hadamard_dense_1_2*ψ_input
    @test controlled_hadamard_kernel_2_1*ψ_input ≈ controlled_hadamard_dense_2_1*ψ_input

    @test typeof(controlled_hadamard_kernel_1_2*ψ_input_32)==Ket{ComplexF32}
    @test get_display_symbol(get_gate_symbol(controlled_hadamard_kernel_1_2)) ==["*", "H"]

    @test_throws DomainError controlled_hadamard_kernel_1_2*Ket([1.,2.])

    # Neither target nor control is last qubit
    controlled_hadamard_kernel_2_3=controlled(hadamard(3),[2])
    controlled_hadamard_dense_2_3=Gate(ControlledHadamard(), [2, 3])

    ψ_input=Ket([ComplexF64(v) for v in 1:2^4])
    
    @test controlled_hadamard_kernel_2_3*ψ_input ≈ controlled_hadamard_dense_2_3*ψ_input

    # circumventing casting to DenseOperator not allowed  
    @test_throws NotImplementedError Snowflurry.apply_controlled_gate_operator!(
        Ket([1,2]),
        eye(4),
        DiagonalOperator([-1.,1.]),
        [1,2]
    )

end

struct DenseGate<:AbstractGateSymbol
    operator::DenseOperator
end

function Snowflurry.get_num_connected_qubits(gate::DenseGate)
    matrix = get_matrix(gate.operator)
    rows, cols = size(matrix)
    @assert rows == cols
    num_connected_qubits = Int(round(log2(rows)))
    @assert 2 ^ num_connected_qubits == rows
    return num_connected_qubits
end

Snowflurry.get_operator(gate::DenseGate,T::Type{<:Complex}=ComplexF64)=gate.operator

function make_labels(num_controls::Int,labels::Vector{String})
    vcat(
        [Snowflurry.control_display_symbol for _ in 1:num_controls], 
        labels
    )
end

@testset "Controlled multi-control single-target" begin
    qubit_count=4

    test_cases=[
        #control_qubits, target_qubits 
        ([1],            [4]),
        ([1,2],          [3]),
        ([1,3],          [2]),
        ([1,2,3],        [4]),
        ([1,2,4],        [3]),
        ([1,3,4],        [2]),
    ]

    for (control_qubits,target_qubits) in test_cases

        num_controls=length(control_qubits)

        c_gate_config=[
            [sigma_x,      make_labels(num_controls, ["X"])],
            [sigma_y,      make_labels(num_controls, ["Y"])],
            [sigma_z,      make_labels(num_controls, ["Z"])],
            [hadamard,     make_labels(num_controls, ["H"])],
            [pi_8,         make_labels(num_controls, ["T"])],
            [pi_8_dagger,  make_labels(num_controls, ["T†"])],
            [x_90,         make_labels(num_controls, ["X_90"])],
            [x_minus_90,   make_labels(num_controls, ["X_m90"])],
            [y_90,         make_labels(num_controls, ["Y_90"])],
            [y_minus_90,   make_labels(num_controls, ["Y_m90"])],
            [z_90,         make_labels(num_controls, ["Z_90"])],
            [z_minus_90,   make_labels(num_controls, ["Z_m90"])],
        ]

        for (func,labels) in c_gate_config
            c_gate=controlled(func(target_qubits...),control_qubits)
            @test get_display_symbol(get_gate_symbol(c_gate))==labels
            @test control_qubits==get_control_qubits(c_gate)
            @test vcat(control_qubits,target_qubits)==get_connected_qubits(c_gate)

            @test get_gate_parameters(get_gate_symbol(c_gate))==Dict{String, Real}()

            equivalent_dense_gate= Gate(DenseGate(get_operator(get_gate_symbol(c_gate))), get_connected_qubits(c_gate))
            ψ_input=Ket([ComplexF64(v) for v in 1:2^qubit_count])

            @test c_gate*ψ_input ≈ equivalent_dense_gate*ψ_input
        end

        # parameterized Gates
        test_cases_params=[
            [rotation,     [pi,pi/2],  ["theta","phi"], make_labels(num_controls, ["R(θ=3.1416,ϕ=1.5708)"])],
            [rotation_x,   [pi/3],     ["theta"],       make_labels(num_controls, ["Rx(1.0472)"])],
            [rotation_y,   [pi/4],     ["theta"],       make_labels(num_controls, ["Ry(0.7854)"])],
            [phase_shift,  [pi/7],     ["lambda"],      make_labels(num_controls, ["Rz(0.4488)"])],
            [universal,    [pi/3,pi/12,pi/4],["theta","phi","lambda"], 
                make_labels(num_controls, ["U(θ=1.0472,ϕ=0.2618,λ=0.7854)"])],
        ]

        for (func,params,param_keys,labels) in test_cases_params
            c_gate=controlled(func(target_qubits...,params...),control_qubits)
            @test get_display_symbol(get_gate_symbol(c_gate))==labels
            @test control_qubits==get_control_qubits(c_gate)
            @test vcat(control_qubits,target_qubits)==get_connected_qubits(c_gate)

            params_in_gate=get_gate_parameters(get_gate_symbol(c_gate))

            for (k,v) in zip(param_keys,params)
                @test params_in_gate[k]==v
            end

            equivalent_dense_gate= Gate(DenseGate(get_operator(get_gate_symbol(c_gate))), get_connected_qubits(c_gate))
            ψ_input=Ket([ComplexF64(v) for v in 1:2^qubit_count])

            @test c_gate*ψ_input ≈ equivalent_dense_gate*ψ_input
        end

        #test label precision
        @test get_display_symbol(
            get_gate_symbol(controlled(rotation(target_qubits...,[pi,pi/2]...),control_qubits)),precision=2
            ) == make_labels(num_controls, ["R(θ=3.14,ϕ=1.57)"])
    end

    # circumventing casting to DenseOperator not allowed  
    @test_throws NotImplementedError Snowflurry.apply_controlled_gate_operator!(
        Ket([v for v in 1:8]),
        eye(8),
        DiagonalOperator([-1.,1.]),
        [1,2]
    )

    @test_throws AssertionError Controlled(Controlled(Snowflurry.SigmaX(),1),3)
end

@testset "Controlled multi-control dual-target" begin
    qubit_count=6

    test_cases=[
        #control_qubits, target_qubits 
        ([1],            [3,4]),
        ([1],            [4,3]),
        ([1,2],          [3,4]),
        ([1,3],          [2,4]),
        ([1,2,3],        [4,5]),
        ([1,2,3],        [5,4]),
        ([1,2,4],        [3,5]),
        ([2,3,4],        [1,5]),
    ]

    for (control_qubits,target_qubits) in test_cases

        num_controls=length(control_qubits)

        c_gate_config=[
            [control_x,     make_labels(num_controls, [Snowflurry.control_display_symbol, "X"])],
            [control_z,     make_labels(num_controls, [Snowflurry.control_display_symbol, "Z"])],
            [swap,          make_labels(num_controls, ["☒", "☒"])],
            [iswap,         make_labels(num_controls, ["x", "x"])],
            [iswap_dagger,  make_labels(num_controls, ["x†", "x†"])],
        ]

        for (func,labels) in c_gate_config
            c_gate=controlled(func(target_qubits...),control_qubits)
            @test control_qubits==get_control_qubits(c_gate)
            @test vcat(control_qubits,target_qubits)==get_connected_qubits(c_gate)

            @test get_display_symbol(get_gate_symbol(c_gate))==labels

            @test get_gate_parameters(get_gate_symbol(c_gate))==Dict{String, Real}()

            equivalent_dense_gate= Gate(DenseGate(get_operator(get_gate_symbol(c_gate))), get_connected_qubits(c_gate))
            ψ_input=Ket([ComplexF64(v) for v in 1:2^qubit_count])

            @test c_gate*ψ_input ≈ equivalent_dense_gate*ψ_input
        end
    end
end

@testset "adjoint_gates" begin
    initial_state_10 = Ket([0, 0, 1, 0])
    iswap_dag=iswap_dagger(1, 2)
    @test iswap(1, 2)*(iswap_dag*initial_state_10) ≈ initial_state_10
    @test get_instruction_symbol(get_gate_symbol(iswap_dag)) == "iswap_dag"
    @test get_symbol_for_instruction("iswap_dag") == Snowflurry.ISwapDagger
    @test get_display_symbol(get_gate_symbol(iswap_dag)) ==["x†", "x†"]

    initial_state_1 = Ket([0, 1])
    pi_8_dag=pi_8_dagger(1)
    @test pi_8_dag*(pi_8(1)*initial_state_1) ≈ initial_state_1
    @test get_instruction_symbol(get_gate_symbol(pi_8_dag)) == "t_dag"
    @test get_symbol_for_instruction("t_dag") == Snowflurry.Pi8Dagger
    @test get_display_symbol(get_gate_symbol(pi_8_dag)) ==["T†"]

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
    @test get_instruction_symbol(get_gate_symbol(inverse_x_90)) == "x_minus_90"
    @test get_display_symbol(get_gate_symbol(inverse_x_90)) ==["X_m90"]

    x_minus_90_gate = x_minus_90(1)
    @test test_inverse(x_minus_90_gate)
    inverse_x_minus_90 = inv(x_minus_90_gate)
    @test get_connected_qubits(x_minus_90_gate)==get_connected_qubits(inverse_x_minus_90)
    @test get_instruction_symbol(get_gate_symbol(inverse_x_minus_90)) == "x_90"
    @test get_display_symbol(get_gate_symbol(inverse_x_minus_90)) ==["X_90"]

    y_90_gate = y_90(1)
    @test test_inverse(y_90_gate)
    inverse_y_90 = inv(y_90_gate)
    @test get_connected_qubits(y_90_gate)==get_connected_qubits(inverse_y_90)
    @test get_instruction_symbol(get_gate_symbol(inverse_y_90)) == "y_minus_90"
    @test get_display_symbol(get_gate_symbol(inverse_y_90)) ==["Y_m90"]

    y_minus_90_gate = y_minus_90(1)
    @test test_inverse(y_minus_90_gate)
    inverse_y_minus_90 = inv(y_minus_90_gate)
    @test get_connected_qubits(y_minus_90_gate)==get_connected_qubits(inverse_y_minus_90)
    @test get_instruction_symbol(get_gate_symbol(inverse_y_minus_90)) == "y_90"
    @test get_display_symbol(get_gate_symbol(inverse_y_minus_90)) ==["Y_90"]

    z_90_gate = z_90(1)
    @test test_inverse(z_90_gate)
    inverse_z_90 = inv(z_90_gate)
    @test get_connected_qubits(z_90_gate)==get_connected_qubits(inverse_z_90)
    @test get_instruction_symbol(get_gate_symbol(inverse_z_90)) == "z_minus_90"
    @test get_display_symbol(get_gate_symbol(inverse_z_90)) ==["Z_m90"]

    z_minus_90_gate = z_minus_90(1)
    @test test_inverse(z_minus_90_gate)
    inverse_z_minus_90 = inv(z_minus_90_gate)
    @test get_connected_qubits(z_minus_90_gate)==get_connected_qubits(inverse_z_minus_90)
    @test get_instruction_symbol(get_gate_symbol(inverse_z_minus_90)) == "z_90"
    @test get_display_symbol(get_gate_symbol(inverse_z_minus_90)) ==["Z_90"]

    t = pi_8(1)
    @test test_inverse(t)
    inverse_t = inv(t)
    @test get_connected_qubits(t)==get_connected_qubits(inverse_t)
    @test get_instruction_symbol(get_gate_symbol(inverse_t)) == "t_dag"
    @test get_display_symbol(get_gate_symbol(inverse_t)) ==["T†"]
    
    t_dag = pi_8_dagger(1)
    @test test_inverse(t_dag)
    inverse_t_dag = inv(t_dag)
    @test get_connected_qubits(t_dag)==get_connected_qubits(inverse_t_dag)
    @test get_instruction_symbol(get_gate_symbol(inverse_t_dag)) == "t"
    @test get_display_symbol(get_gate_symbol(inverse_t_dag)) ==["T"]
    
    iswap_gate = iswap(1, 2)
    @test test_inverse(iswap_gate) 
    inverse_iswap = inv(iswap_gate)
    @test get_connected_qubits(iswap_gate)==get_connected_qubits(inverse_iswap)
    @test get_instruction_symbol(get_gate_symbol(inverse_iswap)) == "iswap_dag"
    @test get_display_symbol(get_gate_symbol(inverse_iswap)) ==["x†", "x†"]

    iswap_dag = iswap_dagger(1, 2)
    @test test_inverse(iswap_dag)
    inverse_iswap_dag = inv(iswap_dag)
    @test get_connected_qubits(iswap_dag)==get_connected_qubits(inverse_iswap_dag)
    @test get_instruction_symbol(get_gate_symbol(inverse_iswap_dag)) == "iswap"
    @test get_display_symbol(get_gate_symbol(inverse_iswap_dag)) ==["x", "x"]

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

    struct UnknownGateSymbol <: AbstractGateSymbol
        instruction_symbol::String
    end
    
    Snowflurry.get_operator(gate::UnknownGateSymbol) = DenseOperator([1 2; 3 4])

    unknown_gate=UnknownGateSymbol("na")
    @test_throws NotImplementedError inv(unknown_gate)

    struct UnknownHermitianGateSymbol <: AbstractGateSymbol
        instruction_symbol::String
    end
    
    Snowflurry.get_operator(gate::UnknownHermitianGateSymbol) = DenseOperator([1 im; -im 1])

    unknown_hermitian_gate = UnknownHermitianGateSymbol("na")

    # test fallback implementation of inv(::AbstractGateSymbol)
    @test inv(unknown_hermitian_gate) == unknown_hermitian_gate
end

@testset "move_gate" begin
    target = 2
    theta = pi/2
    rx_gate = rotation_x(target, theta)
    qubit_mapping = Dict(2=>3)
    moved_rx_gate = move_gate(rx_gate, qubit_mapping)
    
    qubit_mapping = Dict(1=>3, 3=>1)
    untouched_rx_gate = move_gate(rx_gate, qubit_mapping)
    @test untouched_rx_gate isa Snowflurry.Gate{Snowflurry.RotationX}
    @test get_connected_qubits(untouched_rx_gate) == [target]
    @test get_gate_parameters(get_gate_symbol(untouched_rx_gate)) == Dict("theta"=>theta)

    qubit_mapping = Dict(2=>3, 3=>2)
    moved_rx_gate = move_gate(rx_gate, qubit_mapping)
    @test moved_rx_gate isa Snowflurry.Gate{Snowflurry.RotationX}
    @test get_connected_qubits(moved_rx_gate) == [3]
    @test get_gate_parameters(get_gate_symbol(moved_rx_gate)) == Dict("theta"=>theta)

    moved_twice_rx = move_gate(moved_rx_gate, qubit_mapping)
    @test moved_twice_rx isa Snowflurry.Gate{Snowflurry.RotationX}
    @test get_connected_qubits(moved_twice_rx) == [2]
    @test get_gate_parameters(get_gate_symbol(moved_twice_rx)) == Dict("theta"=>theta)
    
    inverse_moved_gate = inv(moved_rx_gate)
    @test inverse_moved_gate isa Snowflurry.Gate{Snowflurry.RotationX}
    @test get_connected_qubits(inverse_moved_gate) == [3]
    @test get_gate_parameters(get_gate_symbol(inverse_moved_gate)) == Dict("theta"=>-theta)

    qubit_mapping = Dict(2=>3, 3=>2, 4=>1, 1=>4)
    toffoli_gate = toffoli(2, 3, 1)
    moved_toffoli_gate = move_gate(toffoli_gate, qubit_mapping)
    @test moved_toffoli_gate isa Snowflurry.Gate{Snowflurry.Toffoli}
    @test get_connected_qubits(moved_toffoli_gate) == [3, 2, 4]

    qubit_mapping = Dict(2=>22, 3=>33,4=>44)
    toffoli_gate = toffoli(2, 3, 4)
    @test get_connected_qubits(toffoli_gate) == [2, 3, 4]
    @test get_control_qubits(toffoli_gate)==[2,3]
    @test get_target_qubits(toffoli_gate)==[4]

    moved_toffoli_gate = move_gate(toffoli_gate, qubit_mapping)
    @test moved_toffoli_gate isa Snowflurry.Gate{Snowflurry.Toffoli}
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
