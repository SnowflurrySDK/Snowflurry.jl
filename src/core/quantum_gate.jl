struct Gate
    display_symbol::Array{String}
    instruction_symbol::String
    operator::Operator
    target::Array
    parameters::Array

    function Gate(display_symbol, instruction_symbol, operator, target::Array, parameters=[])
        ensure_target_qubits_are_different(target)
        new(display_symbol, instruction_symbol, operator, target, parameters)
    end
    Gate(display_symbol, instruction_symbol, operator, target::Int, parameters=[]) =
        new(display_symbol, instruction_symbol, operator, [target], parameters)

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
    println(io, "instruction symbol: " * gate.instruction_symbol)
    if !isempty(gate.parameters)
        print(io, "parameters: " )
        show(io, gate.parameters)
        println()
    end
    println(io, "targets: $(gate.target)")
    println(io, "operator:")
    show(io, "text/plain", gate.operator)
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

rotation(theta, phi) = Operator(
    [cos(theta/2) -im*exp(-im*phi)*sin(theta/2);
     -im*exp(im*phi)*sin(theta/2) cos(theta/2)]
)

rotation_z(theta) = Operator(
    [exp(-im*theta/2) 0;
     0 exp(im*theta/2)]
)

phase_shift(phi) = Operator(
    [1 0;
    0 exp(im*phi)]
)

universal(theta, phi, lambda) = Operator(
    [cos(theta/2) -exp(im*lambda)*sin(theta/2)
     exp(im*phi)*sin(theta/2) exp(im*(phi+lambda))*cos(theta/2)]
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

"""
    sigma_x(target)

Apply the Pauli X gate to the `target` qubit.

The Pauli X operator is
```math
\\sigma_x = \\begin{bmatrix}
    0 & 1 \\\\      
    1 & 0
\\end{bmatrix}.
```
"""
sigma_x(target) = Gate(["X"], "x", sigma_x(), target)

"""
    sigma_y(target)

Apply the Pauli Y gate to the `target` qubit.

The Pauli Y operator is
```math
\\sigma_y = \\begin{bmatrix}
    0 & -i \\\\      
    i & 0
\\end{bmatrix}.
```
"""
sigma_y(target) = Gate(["Y"], "y", sigma_y(), target)

"""
    sigma_z(target)

Apply the Pauli Z gate to the `target` qubit.

The Pauli Z operator is
```math
\\sigma_z = \\begin{bmatrix}
    1 & 0 \\\\      
    0 & -1
\\end{bmatrix}.
```
"""
sigma_z(target) = Gate(["Z"], "z", sigma_z(), target)

"""
    hadamard(target)

Apply the Hadamard gate to the `target` qubit.

The Hadamard operator is
```math
H = \\frac{1}{\\sqrt{2}} \\begin{bmatrix}
    1 & 1 \\\\      
    1 & -1
\\end{bmatrix}.
```
"""
hadamard(target) = Gate(["H"], "h", hadamard(), target)

"""
    phase(target)

Apply the phase gate (also known as the S gate) to the `target` qubit.

The phase operator is
```math
S = \\begin{bmatrix}
    1 & 0 \\\\      
    0 & i
\\end{bmatrix}.
```
"""
phase(target) = Gate(["S"], "s", phase(), target)

"""
    pi_8(target)

Apply the π/8 gate (also known as the T gate) to the `target` qubit.

The π/8 operator is
```math
T = \\begin{bmatrix}
    1 & 0 \\\\      
    0 & e^{i\\frac{\\pi}{4}}
\\end{bmatrix}.
```
"""
pi_8(target) = Gate(["T"], "t", pi_8(), target)

"""
    x_90(target)

Apply a 90° rotation about the X axis to the `target` qubit.

The corresponding operator is
```math
R_x(\\pi) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\pi}{2}\\right) &
        -i\\mathrm{sin}\\left(\\frac{\\pi}{2}\\right) \\\\[0.5em]      
    -i\\mathrm{sin}\\left(\\frac{\\pi}{2}\\right) &
        \\mathrm{cos}\\left(\\frac{\\pi}{2}\\right)
\\end{bmatrix}.
```
"""
x_90(target) = Gate(["X_90"], "x_90", x_90(), target)

"""
rotation(target, theta, phi)

Apply a rotation `theta` to the `target` qubit about the cos(`phi`)X+sin(`phi`)Y axis.

The corresponding operator is
```math
R(\\theta, \\phi) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -i e^{-i\\phi} \\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    -i e^{i\\phi} \\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
"""
rotation(target, theta, phi) = Gate(["R(θ=$(theta),ϕ=$(phi))"], "r", rotation(theta, phi),
    target, [theta, phi])

    """
    rotation_x(target, theta)

Apply a rotation of `theta` about the X axis to the `target` qubit.

The corresponding operator is
```math
R_x(\\theta) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -i\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    -i\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
"""    
rotation_x(target, theta) = Gate(["Rx($(theta))"], "rx", rotation(theta, 0), target,
    [theta])

    """
    rotation_y(target, theta)

Apply a rotation of `theta` about the Y axis to the `target` qubit.

The corresponding operator is
```math
R_y(\\theta) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    \\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
rotation_y(target, theta) = Gate(["Ry($(theta))"], "ry", rotation(theta, pi/2), target,
    [theta])

    """
    rotation_z(target, theta)

Apply a rotation of `theta` about the Z axis to the `target` qubit.

The corresponding operator is
```math
R_z(\\theta) = \\begin{bmatrix}
    \\mathrm{exp}\\left(-i\\frac{\\theta}{2}\\right) & 0 \\\\[0.5em]      
    0 & \\mathrm{exp}\\left(i\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
rotation_z(target, theta) = Gate(["Rz($(theta))"], "rz", rotation_z(theta), target, [theta])

"""
    phase_shift(target, phi)

Apply a phase shift gate with phase shift `phi` to the `target` qubit.

The corresponding operator is
```math
P(\\phi) = \\begin{bmatrix}
    i & 0 \\\\[0.5em]      
    0 & e^{i\\phi}
\\end{bmatrix}.
```
""" 
phase_shift(target, phi) = Gate(["P($(phi))"], "p", phase_shift(phi), target, [phi])

"""
    universal(target, theta, phi, lambda)

Apply a gate which rotates the `target` qubit given the angles `theta`, `phi`, and `lambda`.

The corresponding operator is
```math
U(\\theta, \\phi, \\lambda) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -e^{i\\lambda}\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    e^{i\\phi}\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        e^{i\\left(\\phi+\\lambda\\right)}\\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
universal(target, theta, phi, lambda) = Gate(["U(θ=$(theta),ϕ=$(phi),λ=$(lambda))"], "u",
    universal(theta, phi, lambda), target, [theta, phi, lambda])




# two qubit gates

"""
    control_z(control_qubit, target_qubit)

Apply a controlled-Z gate given a `control_qubit` and a `target_qubit`.

The controlled-Z operator is
```math
CZ = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 \\\\     
    0 & 0 & 1 & 0 \\\\
    0 & 0 & 0 & -1 \\\\  
\\end{bmatrix}.
```
""" 
control_z(control_qubit, target_qubit) =
    Gate(["*" "Z"], "cz", control_z(), [control_qubit, target_qubit])

"""
    control_x(control_qubit, target_qubit)

Apply a controlled-X gate (also known as a controlled NOT gate) given a `control_qubit`
and a `target_qubit`.

The controlled-X operator is
```math
CX = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 \\\\     
    0 & 0 & 0 & 1 \\\\
    0 & 0 & 1 & 0 \\\\  
\\end{bmatrix}.
```
""" 
control_x(control_qubit, target_qubit) =
    Gate(["*" "X"], "cx", control_x(), [control_qubit, target_qubit])

"""
    iswap(qubit_1, qubit_2)

Apply an imaginary swap gate to `qubit_1` and `qubit_2`.

The imaginary swap operator is
```math
i\\mathrm{SWAP} = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 0 & i & 0 \\\\     
    0 & i & 0 & 0 \\\\
    0 & 0 & 0 & 1 \\\\  
\\end{bmatrix}.
```
""" 
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
