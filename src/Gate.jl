export Gate, sigma_x, sigma_y, sigma_z, hadamard, control_z, control_x, x_90, iswap, eye

struct Gate
    display_symbol::Array{String}
    instruction_symbol::String
    operator::Operator
    target::Array

    Gate(display_symbol, instruction_symbol, operator, target::Array) = new(display_symbol, instruction_symbol, operator, target)
    Gate(display_symbol, instruction_symbol, operator, target::Int) = new(display_symbol, instruction_symbol, operator, [target])

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
hadamard() = Operator(1.0 / sqrt(2.0) * reshape(Complex.([1.0, 1.0, 1.0, -1.0]), 2, 2))
eye() = Operator(Matrix{Complex}(1.0I, 2, 2))

sigma_x(target) = Gate(["X"], "x", sigma_x(), target)
sigma_y(target) = Gate(["Y"], "y", sigma_y(), target)
sigma_z(target) = Gate(["Z"], "z", sigma_z(), target)
hadamard(target) = Gate(["H"], "ha", hadamard(), target)
x_90(target) = Gate(["X_90"], "x_90", Operator(reshape(Complex.([cos(pi / 2.0), -im * sin(pi / 2.0), -im * sin(pi / 2.0), cos(pi / 2.0)]), 2, 2)), target)




# two qubit gates
control_z(control_qubit, target_qubit) = Gate(["*" "Z"], "cz", Operator(Complex.([[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [0.0, 0.0, 0.0, -1.0]])), [control_qubit, target_qubit])
control_x(control_qubit, target_qubit) = Gate(["*" "X"], "cx", Operator(Complex.([[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0] [0.0, 0.0, 1.0, 0.0]])), [control_qubit, target_qubit])
iswap(qubit_1, qubit_2) = Gate(["x" "x"], "iswap", Operator(Complex.([[1.0, 0.0, 0.0, 0.0] [0.0, 0.0, im, 0.0] [0.0, im, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0]])), [qubit_1, qubit_2])

Base.:*(M::Gate, x::Ket) = M.operator * x
