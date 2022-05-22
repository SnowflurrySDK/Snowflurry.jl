struct Gate
    display_symbol::Array{String}
    instruction_symbol::String
    operator::Operator
    target::Array

    function Gate(display_symbol, instruction_symbol, operator, target::Array)
        ensure_target_qubits_are_different(target)
        new(display_symbol, instruction_symbol, operator, target)
    end
    Gate(display_symbol, instruction_symbol, operator, target::Int) =
        new(display_symbol, instruction_symbol, operator, [target])

end

function ensure_target_qubits_are_different(target::Array)
    num_targets = length(target)
    if num_targets > 1
        previous_target = target[1]
        for i = 2:num_targets
            current_target = target[i]
            if previous_target == current_target
                throw(DomainError(current_target,
                    "The gate uses qubit $current_target more than once!"))
            end
        end
    end
end

function Base.show(io::IO, gate::Gate)
    println(io, "Gate Object:")
    println(io, "\tinstruction symbol:" * gate.instruction_symbol)
    println(io, "\toperator:")
    show(io, "text/plain", gate.operator)
    println()
    println(io, "\ttargets: $(gate.target)")
end

Base.kron(x::Gate, y::Gate) = kron(x.operator, y.operator)
Base.kron(x::Gate, y::Operator) = kron(x.operator, y)
Base.kron(x::Operator, y::Gate) = kron(x, y.operator)

# Single Qubit Gates
sigma_x() = Operator(reshape(Complex.([0.0, 1.0, 1.0, 0.0]), 2, 2))
sigma_y() = Operator(reshape(Complex.([0.0, im, -im, 0.0]), 2, 2))
sigma_z() = Operator(reshape(Complex.([1.0, 0.0, 0.0, -1.0]), 2, 2))
sigma_p() = 0.5*(sigma_x()+im*sigma_y())
sigma_m() = 0.5*(sigma_x()-im*sigma_y())
projector_0() = Operator([1 0; 0 0])
projector_1() = Operator([0 0; 0 1])

hadamard() = Operator(1.0 / sqrt(2.0) * reshape(Complex.([1.0, 1.0, 1.0, -1.0]), 2, 2))
phase() = Operator(reshape(Complex.([1.0, 0.0, 0.0, im]), 2, 2))
pi_8() = Operator(reshape(Complex.([1.0, 0.0, 0.0, exp(im*pi/4.0)]), 2, 2))

eye() = Operator(Matrix{Complex}(1.0I, 2, 2))
x_90() = Operator(
    reshape(
        Complex.([cos(pi / 2.0), -im * sin(pi / 2.0), -im * sin(pi / 2.0), cos(pi / 2.0)]),
        2,
        2,
    ),
)

control_x() = Operator(
    Complex.(
        [[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0] [
            0.0,
            0.0,
            1.0,
            0.0,
        ]],
    ),
)

control_z() = Operator(
    Complex.(
        [[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [
            0.0,
            0.0,
            0.0,
            -1.0,
        ]],
    ),
)

iswap() = Operator(
    Complex.(
        [[1.0, 0.0, 0.0, 0.0] [0.0, 0.0, im, 0.0] [0.0, im, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0]],
    ),
)


sigma_x(target) = Gate(["X"], "x", sigma_x(), target)
sigma_y(target) = Gate(["Y"], "y", sigma_y(), target)
sigma_z(target) = Gate(["Z"], "z", sigma_z(), target)
hadamard(target) = Gate(["H"], "h", hadamard(), target)
phase(target) = Gate(["S"], "s", phase(), target)
pi_8(target) = Gate(["T"], "t", pi_8(), target)
x_90(target) = Gate(["X_90"], "x_90", x_90(), target)




# two qubit gates
control_z(control_qubit, target_qubit) =
    Gate(["*" "Z"], "cz", control_z(), [control_qubit, target_qubit])
control_x(control_qubit, target_qubit) =
    Gate(["*" "X"], "cx", control_x(), [control_qubit, target_qubit])
iswap(qubit_1, qubit_2) = Gate(["x" "x"], "iswap", iswap(), [qubit_1, qubit_2])

Base.:*(M::Gate, x::Ket) = M.operator * x

STD_GATES = Dict(
    "x" => sigma_x,
    "y" => sigma_y,
    "z" => sigma_z,
    "s" => phase, 
    "t" => pi_8, 
    "i" => eye,
    "h" => hadamard,
    "cx" => control_x,
    "cz" => control_z,
    "iswap" => iswap,
)

PAULI_GATES = Dict(
    "x" => sigma_x,
    "y" => sigma_y,
    "z" => sigma_z, 
    "i" => eye
)
