"""
    Gate(display_symbol, instruction_symbol, operator, target::Array, parameters=[])
    Gate(display_symbol, instruction_symbol, operator, target::Int, parameters=[])

Constructs a `Gate` that can be added to a `QuantumCircuit` in order to apply an `operator` to one or more `target` qubits.

Each `Gate` has a `display_symbol` which determines how the `Gate` is displayed in a `QuantumCircuit`.
The `instruction_symbol` is used by the quantum compiler to identify the `Gate`.
Optionally, a `Gate` can contain parameters.

# Examples
```jldoctest
julia> pi_x_rotation_on_qubit_1 = Gate(["Rx(π)"], "rx", Operator([0.0 -im; -im 0.0]), 1, [π])
Gate Object:
instruction symbol: rx
parameters: [π]
targets: [1]
operator:
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
0.0 + 0.0im    0.0 - 1.0im
0.0 - 1.0im    0.0 + 0.0im


```
"""
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
        println(io)
    end
    println(io, "targets: $(gate.target)")
    println(io, "operator:")
    show(io, "text/plain", gate.operator)
end

"""
    apply_gate!(state::Ket, gate::Gate)

Update the `state` by applying a `gate` to it.

# Examples
```jldoctest
julia> ψ_0 = fock(0, 2);

julia> print(ψ_0)
2-element Ket:
1.0 + 0.0im
0.0 + 0.0im

julia> apply_gate!(ψ_0, sigma_x(1));

julia> print(ψ_0)
2-element Ket:
0.0 + 0.0im
1.0 + 0.0im

```
"""
function apply_gate!(state::Ket, gate::Gate)
    qubit_count = log2(length(state))
    if mod(qubit_count, 1) != 0
        throw(DomainError(qubit_count,
            "Ket does not correspond to an integer number of qubits"))
    end
    if any(i_target->(i_target>qubit_count), gate.target)
        throw(DomainError(gate.target,
            "not enough qubits in the Ket for the Gate"))
    end
    Snowflake.apply_gate_without_ket_size_check!(state, gate, Int(qubit_count))
end


# Single Qubit Gates
"""
    sigma_x()

Return the Pauli-X `Operator`, which is defined as:
```math
\\sigma_x = \\begin{bmatrix}
    0 & 1 \\\\
    1 & 0
    \\end{bmatrix}.
```
"""
sigma_x() = Operator(reshape(Complex.([0.0, 1.0, 1.0, 0.0]), 2, 2))

"""
    sigma_y()

Return the Pauli-Y `Operator`, which is defined as:
```math
\\sigma_y = \\begin{bmatrix}
    0 & -i \\\\
    i & 0
    \\end{bmatrix}.
```
"""
sigma_y() = Operator(reshape(Complex.([0.0, im, -im, 0.0]), 2, 2))

"""
    sigma_z()

Return the Pauli-Z `Operator`, which is defined as:
```math
\\sigma_z = \\begin{bmatrix}
    1 & 0 \\\\
    0 & -1
    \\end{bmatrix}.
```
"""
sigma_z() = Operator(reshape(Complex.([1.0, 0.0, 0.0, -1.0]), 2, 2))

"""
    sigma_p()

Return the spin-\$\\frac{1}{2}\$ raising `Operator`, which is defined as:
```math
\\sigma_+ = \\begin{bmatrix}
    0 & 1 \\\\
    0 & 0
    \\end{bmatrix}.
```
"""
sigma_p() = 0.5*(sigma_x()+im*sigma_y())

"""
    sigma_m()

Return the spin-\$\\frac{1}{2}\$ lowering `Operator`, which is defined as:
```math
\\sigma_- = \\begin{bmatrix}
    0 & 0 \\\\
    1 & 0
    \\end{bmatrix}.
```
"""
sigma_m() = 0.5*(sigma_x()-im*sigma_y())

"""
    hadamard()

Return the Hadamard `Operator`, which is defined as:
```math
H = \\frac{1}{\\sqrt{2}}\\begin{bmatrix}
    1 & 1 \\\\
    1 & -1
    \\end{bmatrix}.
```
"""
hadamard() = Operator(1.0 / sqrt(2.0) * reshape(Complex.([1.0, 1.0, 1.0, -1.0]), 2, 2))

"""
    phase()

Return the phase gate `Operator`, which is defined as:
```math
S = \\begin{bmatrix}
    1 & 0 \\\\
    0 & i
    \\end{bmatrix}.
```
"""
phase() = Operator(reshape(Complex.([1.0, 0.0, 0.0, im]), 2, 2))

"""
    pi_8()

Return the `Operator` for the π/8 gate, which is defined as:
```math
T = \\begin{bmatrix}
    1 & 0 \\\\
    0 & e^{i\\frac{\\pi}{4}}
    \\end{bmatrix}.
```
"""
pi_8() = Operator(reshape(Complex.([1.0, 0.0, 0.0, exp(im*pi/4.0)]), 2, 2))

"""
    eye()

Return the identity `Operator`, which is defined as:
```math
I = \\begin{bmatrix}
    1 & 0 \\\\
    0 & 1
    \\end{bmatrix}.
```
"""
eye() = Operator(Matrix{Complex}(1.0I, 2, 2))

"""
    x_90()

Return the `Operator` which applies a π/2 rotation about the X axis.

The `Operator` is defined as:
```math
R_x\\left(\\frac{\\pi}{2}\\right) = \\frac{1}{\\sqrt{2}}\\begin{bmatrix}
    1 & -i \\\\
    -i & 1
    \\end{bmatrix}.
```
"""
x_90() = rotation(pi/2, 0)

"""
    rotation(theta, phi)

Return the `Operator` which applies a rotation `theta` about the cos(`phi`)X+sin(`phi`)Y axis.

The `Operator` is defined as:
```math
R(\\theta, \\phi) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -i e^{-i\\phi} \\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    -i e^{i\\phi} \\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
"""
rotation(theta, phi) = Operator(
    [cos(theta/2) -im*exp(-im*phi)*sin(theta/2);
     -im*exp(im*phi)*sin(theta/2) cos(theta/2)]
)

"""
    rotation_x(theta)

Return the `Operator` which applies a rotation `theta` about the X axis.

The `Operator` is defined as:
```math
R_x(\\theta) = \\begin{bmatrix}
\\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
    -i\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
-i\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
"""   
rotation_x(theta) = rotation(theta, 0)

"""
    rotation_y(theta)

Return the `Operator` that applies a rotation `theta` about the Y axis of the `target` qubit.

The `Operator` is defined as:
```math
R_y(\\theta) = \\begin{bmatrix}
\\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
    -\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
rotation_y(theta) = rotation(theta, pi/2)

"""
    rotation_z(theta)

Return the `Operator` that applies a rotation `theta` about the Z axis.

The `Operator` is defined as:
```math
R_z(\\theta) = \\begin{bmatrix}
\\mathrm{exp}\\left(-i\\frac{\\theta}{2}\\right) & 0 \\\\[0.5em]      
0 & \\mathrm{exp}\\left(i\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
rotation_z(theta) = Operator(
    [exp(-im*theta/2) 0;
     0 exp(im*theta/2)]
)

"""
    phase_shift(phi)

Return the `Operator` that applies a phase shift `phi`.

The `Operator` is defined as:
```math
P(\\phi) = \\begin{bmatrix}
    i & 0 \\\\[0.5em]      
    0 & e^{i\\phi}
\\end{bmatrix}.
```
""" 
phase_shift(phi) = Operator(
    [1 0;
    0 exp(im*phi)]
)

"""
    universal(theta, phi, lambda)

Return the `Operator` which performs a rotation about the angles `theta`, `phi`, and `lambda`.

The `Operator` is defined as:
```math
U(\\theta, \\phi, \\lambda) = \\begin{bmatrix}
    \\mathrm{cos}\\left(\\frac{\\theta}{2}\\right) &
        -e^{i\\lambda}\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) \\\\[0.5em]      
    e^{i\\phi}\\mathrm{sin}\\left(\\frac{\\theta}{2}\\right) &
        e^{i\\left(\\phi+\\lambda\\right)}\\mathrm{cos}\\left(\\frac{\\theta}{2}\\right)
\\end{bmatrix}.
```
""" 
universal(theta, phi, lambda) = Operator(
    [cos(theta/2) -exp(im*lambda)*sin(theta/2)
     exp(im*phi)*sin(theta/2) exp(im*(phi+lambda))*cos(theta/2)]
)

"""
    control_x()

Return the controlled-X (or controlled NOT) `Operator`, which is defined as:
```math
CX = CNOT = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 \\\\
    0 & 0 & 0 & 1 \\\\
    0 & 0 & 1 & 0
    \\end{bmatrix}.
```
"""
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

"""
    control_z()

Return the controlled-Z `Operator`, which is defined as:
```math
CZ = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 \\\\
    0 & 0 & 1 & 0 \\\\
    0 & 0 & 0 & -1
    \\end{bmatrix}.
```
"""
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

"""
    iswap()

Return the imaginary swap `Operator`, which is defined as:
```math
iSWAP = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 0 & i & 0 \\\\
    0 & i & 0 & 0 \\\\
    0 & 0 & 0 & 1
    \\end{bmatrix}.
```
"""
iswap() = Operator(
    Complex.(
        [[1.0, 0.0, 0.0, 0.0] [0.0, 0.0, im, 0.0] [0.0, im, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0]],
    ),
)

"""
    toffoli()

Return the Toffoli `Operator`, which is defined as:
```math
CCX = CCNOT = \\begin{bmatrix}
    1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\\\
    0 & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\\\
    0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\\\
    0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 \\\\
    0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 \\\\
    0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\\\
    0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 \\\\
    0 & 0 & 0 & 0 & 0 & 0 & 1 & 0
    \\end{bmatrix}.
```
"""
toffoli() = Operator(
    [1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0
    0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0
    0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0
    0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0
    0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0]
)

"""
    sigma_x(target)

Return the Pauli-X `Gate`, which applies the [`sigma_x()`](@ref) `Operator` to the target qubit.
"""
sigma_x(target) = Gate(["X"], "x", sigma_x(), target)

"""
    sigma_y(target)

Return the Pauli-Y `Gate`, which applies the [`sigma_y()`](@ref) `Operator` to the target qubit.
"""
sigma_y(target) = Gate(["Y"], "y", sigma_y(), target)

"""
    sigma_z(target)

Return the Pauli-Z `Gate`, which applies the [`sigma_z()`](@ref) `Operator` to the target qubit.
"""
sigma_z(target) = Gate(["Z"], "z", sigma_z(), target)

"""
    hadamard(target)

Return the Hadamard `Gate`, which applies the [`hadamard()`](@ref) `Operator` to the `target` qubit.
"""
hadamard(target) = Gate(["H"], "h", hadamard(), target)

"""
    phase(target)

Return a phase `Gate` (also known as an S `Gate`), which applies the [`phase()`](@ref) `Operator` to the target qubit.
"""
phase(target) = Gate(["S"], "s", phase(), target)

"""
    pi_8(target)

Return a π/8 `Gate` (also known as a T `Gate`), which applies the [`pi_8()`](@ref) `Operator` to the `target` qubit.
"""
pi_8(target) = Gate(["T"], "t", pi_8(), target)

"""
    x_90(target)

Return a `Gate` that applies a 90° rotation about the X axis as defined by the [`x_90()`](@ref) `Operator`.
"""
x_90(target) = Gate(["X_90"], "x_90", x_90(), target)

"""
    rotation(target, theta, phi)

Return a gate that applies a rotation `theta` to the `target` qubit about the cos(`phi`)X+sin(`phi`)Y axis.

The corresponding `Operator` is [`rotation(theta, phi)`](@ref).
"""
rotation(target, theta, phi) = Gate(["R(θ=$(theta),ϕ=$(phi))"], "r", rotation(theta, phi),
    target, [theta, phi])

    """
    rotation_x(target, theta)

Return a `Gate` that applies a rotation `theta` about the X axis of the `target` qubit.

The corresponding `Operator` is [`rotation_x(theta)`](@ref).
"""    
rotation_x(target, theta) = Gate(["Rx($(theta))"], "rx", rotation_x(theta), target,
    [theta])

    """
    rotation_y(target, theta)

Return a `Gate` that applies a rotation `theta` about the Y axis of the `target` qubit.

The corresponding `Operator` is [`rotation_y(theta)`](@ref).
""" 
rotation_y(target, theta) = Gate(["Ry($(theta))"], "ry", rotation_y(theta), target,
    [theta])

    """
    rotation_z(target, theta)

Return a `Gate` that applies a rotation `theta` about the Z axis of the `target` qubit.

The corresponding `Operator` is [`rotation_z(theta)`](@ref).
""" 
rotation_z(target, theta) = Gate(["Rz($(theta))"], "rz", rotation_z(theta), target, [theta])

"""
    phase_shift(target, phi)

Return a `Gate` that applies a phase shift `phi` to the `target` qubit as defined by the [`phase_shift(phi)`](@ref) `Operator`.
""" 
phase_shift(target, phi) = Gate(["P($(phi))"], "p", phase_shift(phi), target, [phi])

"""
    universal(target, theta, phi, lambda)

Return a gate which rotates the `target` qubit given the angles `theta`, `phi`, and `lambda`.

The corresponding `Operator` is [`universal(theta, phi, lambda)`](@ref).
""" 
universal(target, theta, phi, lambda) = Gate(["U(θ=$(theta),ϕ=$(phi),λ=$(lambda))"], "u",
    universal(theta, phi, lambda), target, [theta, phi, lambda])




# two qubit gates

"""
    control_z(control_qubit, target_qubit)

Return a controlled-Z gate given a `control_qubit` and a `target_qubit`.

The corresponding `Operator` is [`control_z()`](@ref).
""" 
control_z(control_qubit, target_qubit) =
    Gate(["*" "Z"], "cz", control_z(), [control_qubit, target_qubit])

"""
    control_x(control_qubit, target_qubit)

Return a controlled-X gate (also known as a controlled NOT gate) given a `control_qubit` and a `target_qubit`.

The corresponding `Operator` is [`control_x()`](@ref).
""" 
control_x(control_qubit, target_qubit) =
    Gate(["*" "X"], "cx", control_x(), [control_qubit, target_qubit])

"""
    iswap(qubit_1, qubit_2)

Return the imaginary swap `Gate` which applies the imaginary swap `Operator` to `qubit_1` and `qubit_2.`

The corresponding `Operator` is [`iswap()`](@ref).
""" 
iswap(qubit_1, qubit_2) = Gate(["x" "x"], "iswap", iswap(), [qubit_1, qubit_2])

"""
    toffoli(control_qubit_1, control_qubit_2, target_qubit)

Return a Toffoli gate (also known as a CCNOT gate) given two control qubits and a `target_qubit`.

The corresponding `Operator` is [`toffoli()`](@ref).
""" 
toffoli(control_qubit_1, control_qubit_2, target_qubit) =
    Gate(["*" "*" "X"], "ccx", toffoli(), [control_qubit_1, control_qubit_2, target_qubit])

"""
    Base.:*(M::Gate, x::Ket)

Return a `Ket` which results from applying `Gate` `M` to `Ket` `x`.

# Examples
```jldoctest
julia> ψ_0 = fock(0, 2);

julia> print(ψ_0)
2-element Ket:
1.0 + 0.0im
0.0 + 0.0im

julia> ψ_1 = sigma_x(1)*ψ_0;

julia> print(ψ_1)
2-element Ket:
0.0 + 0.0im
1.0 + 0.0im

```
"""
Base.:*(M::Gate, x::Ket) = get_transformed_state(x, M)

function get_transformed_state(state::Ket, gate::Gate)
    transformed_state = deepcopy(state)
    apply_gate!(transformed_state, gate)
    return transformed_state
end

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
    "ccx" => toffoli,
)

PAULI_GATES = Dict(
    "x" => sigma_x,
    "y" => sigma_y,
    "z" => sigma_z, 
    "i" => eye
)
