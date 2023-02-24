using Parameters

"""
    Gate

A `Gate` can be added to a `QuantumCircuit` in order to apply an operator to one or more `target` qubits.

A `Gate` is an abstract type, which means that it cannot be instantiated.
Instead, each type of gate must have a struct which is a descendant of `Gate`.
Each descendant of `Gate` must have at least the following fields:
- `display_symbol::Vector{String}`: determines how the `Gate` is displayed in a `QuantumCircuit`.
- `instruction_symbol::String`: used by the quantum compiler to identify the `Gate`.
- `target::Vector{Int}`: to which qubits the `Gate` is applied.
- `parameters::Vector`: affect which operation is applied (e.g. rotation angles).
- `type::Type{<:Complex}`: datatype used to construct underlying operator, default being ComplexF64.

# Examples
A struct must be defined for each new gate type, such as the following X_45 gate which
applies a 45° rotation about the X axis:
```jldoctest gate_struct
julia> struct X45 <: Gate
           display_symbol::Vector{String}
           instruction_symbol::String
           target::Vector{Int}
           parameters::Vector
           type::Type{<:Complex}
       end;

```

For convenience, a constructor can be defined:
```jldoctest gate_struct
julia> x_45(target,T::Type{<:Complex}=ComplexF64) = X45(["X_45"], "x_45", [target], [], T);

```

To simulate the effect of the gate in a `QuantumCircuit` or when applied to a `Ket`,
the function `get_operator` must be extended.
```jldoctest gate_struct
julia> Snowflake.get_operator(gate::X45) = rotation_x(π/4, gate.type);

```

The gate inverse can also be specified by extending the `get_inverse` function.
```jldoctest gate_struct
julia> Snowflake.get_inverse(gate::X45) = rotation_x(gate.target[1], -π/4, gate.type);

```

An instance of the X_45 gate can now be created:
```jldoctest gate_struct
julia> x_45_gate = x_45(1)
Gate Object:
instruction symbol: x_45
targets: [1]
operator:
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.9238795325112867 + 0.0im    0.0 - 0.3826834323650898im
0.0 - 0.3826834323650898im    0.9238795325112867 + 0.0im


julia> get_inverse(x_45_gate)
Gate Object:
instruction symbol: rx
parameters: [-0.7853981633974483]
targets: [1]
operator:
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.9238795325112867 + 0.0im    -0.0 + 0.3826834323650898im
-0.0 + 0.3826834323650898im    0.9238795325112867 + 0.0im


```

Alternatively, an instance of the X_45 gate using ComplexF32 datatype is constructed as per:
```jldoctest gate_struct
julia> x_45_gate_ComplexF32 = x_45(1, ComplexF32)
Gate Object:
instruction symbol: x_45
targets: [1]
operator:
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF32}:
0.9238795f0 + 0.0f0im    0.0f0 - 0.38268343f0im
0.0f0 - 0.38268343f0im    0.9238795f0 + 0.0f0im

```

"""
abstract type Gate end

function Base.show(io::IO, gate::Gate)
    println(io, "Gate Object:")
    println(io, "instruction symbol: " * gate.instruction_symbol)
    if !isempty(gate.parameters)
        print(io, "parameters: " )
        show(io, gate.parameters)
        println(io)
    end
    println(io, "targets: $(gate.target)")
    if applicable(get_operator, gate)
        println(io, "operator:")
        show(io, "text/plain", get_operator(gate))
    end
end

"""
    apply_gate!(state::Ket, gate::Gate)

Update the `state` by applying a `gate` to it.

# Examples
```jldoctest
julia> ψ_0 = fock(0, 2);

julia> print(ψ_0)
2-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im

julia> apply_gate!(ψ_0, sigma_x(1));

julia> print(ψ_0)
2-element Ket{ComplexF64}:
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
sigma_x(T::Type{<:Complex}=ComplexF64)=Operator{T}( T[[0.0, 1.0] [1.0, 0.0]])

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
sigma_y(T::Type{<:Complex}=ComplexF64)=Operator{T}(T[[0.0, im] [-im, 0.0]])

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
sigma_z(T::Type{<:Complex}=ComplexF64)=Operator{T}(T[[1.0, 0.0] [0.0, -1.0]])

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
sigma_p(T::Type{<:Complex}=ComplexF64) = 0.5*(sigma_x(T)+im*sigma_y(T))

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
sigma_m(T::Type{<:Complex}=ComplexF64) = 0.5*(sigma_x(T)-im*sigma_y(T))

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
hadamard(T::Type{<:Complex}=ComplexF64) = Operator{T}(1.0 / sqrt(2.0) * T[[1.0, 1.0] [1.0, -1.0]])

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
phase(T::Type{<:Complex}=ComplexF64) = Operator{T}(T[[1.0, 0.0] [0.0, im]])

"""
    phase_dagger()

Return the adjoint phase gate `Operator`, which is defined as:
```math
S^\\dagger = \\begin{bmatrix}
    1 & 0 \\\\
    0 & -i
    \\end{bmatrix}.
```
"""
phase_dagger(T::Type{<:Complex}=ComplexF64) = Operator{T}(T[[1.0, 0.0] [0.0, -im]])

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
pi_8(T::Type{<:Complex}=ComplexF64) = Operator{T}(T[[1.0, 0.0] [0.0, exp(im*pi/4.0)]])

"""
    pi_8_dagger()

Return the adjoint `Operator` of the π/8 gate, which is defined as:
```math
T^\\dagger = \\begin{bmatrix}
    1 & 0 \\\\
    0 & e^{-i\\frac{\\pi}{4}}
    \\end{bmatrix}.
```
"""
pi_8_dagger(T::Type{<:Complex}=ComplexF64) = Operator{T}(T[[1.0, 0.0] [0.0, exp(-im*pi/4.0)]])

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
eye(T::Type{<:Complex}=ComplexF64) = Operator(Matrix{T}(1.0I, 2, 2))

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
x_90(T::Type{<:Complex}=ComplexF64) = rotation(pi/2, 0,T)

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
rotation(theta, phi,T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[cos(theta/2) -im*exp(-im*phi)*sin(theta/2);
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
rotation_x(theta,T::Type{<:Complex}=ComplexF64) = rotation(theta, 0,T)

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
rotation_y(theta,T::Type{<:Complex}=ComplexF64) = rotation(theta, pi/2,T)

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
rotation_z(theta,T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[exp(-im*theta/2) 0;
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
phase_shift(phi,T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[1 0;
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
universal(theta, phi, lambda,T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[cos(theta/2) -exp(im*lambda)*sin(theta/2)
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
control_x(T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0] [
            0.0,
            0.0,
            1.0,
            0.0,
    ]],
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
control_z(T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[[1.0, 0.0, 0.0, 0.0] [0.0, 1.0, 0.0, 0.0] [0.0, 0.0, 1.0, 0.0] [
            0.0,
            0.0,
            0.0,
            -1.0,
    ]]
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
iswap(T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[[1.0, 0.0, 0.0, 0.0] [0.0, 0.0, im, 0.0] [0.0, im, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0]]
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
toffoli(T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[1.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
    0.0 1.0 0.0 0.0 0.0 0.0 0.0 0.0
    0.0 0.0 1.0 0.0 0.0 0.0 0.0 0.0
    0.0 0.0 0.0 1.0 0.0 0.0 0.0 0.0
    0.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0
    0.0 0.0 0.0 0.0 0.0 1.0 0.0 0.0
    0.0 0.0 0.0 0.0 0.0 0.0 0.0 1.0
    0.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0]
)

"""
    iswap_dagger()

Return the adjoint of the imaginary swap `Operator`, which is defined as:
```math
iSWAP^\\dagger = \\begin{bmatrix}
    1 & 0 & 0 & 0 \\\\
    0 & 0 & -i & 0 \\\\
    0 & -i & 0 & 0 \\\\
    0 & 0 & 0 & 1
    \\end{bmatrix}.
```
"""
iswap_dagger(T::Type{<:Complex}=ComplexF64) = Operator{T}(
    T[[1.0, 0.0, 0.0, 0.0] [0.0, 0.0, -im, 0.0] [0.0, -im, 0.0, 0.0] [0.0, 0.0, 0.0, 1.0]],
)

"""
    sigma_x(target)

Return the Pauli-X `Gate`, which applies the [`sigma_x()`](@ref) `Operator` to the target qubit.
"""
sigma_x(target,T::Type{<:Complex}=ComplexF64) = SigmaX(["X"], "x", [target], [], T)

struct SigmaX <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

"""
    get_operator(gate::Gate)

Returns the `Operator` which is associated to a `Gate`.

# Examples
```jldoctest
julia> x = sigma_x(1);

julia> get_operator(x)
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.0 + 0.0im    1.0 + 0.0im
1.0 + 0.0im    0.0 + 0.0im


```
"""
get_operator(gate::SigmaX) = sigma_x(gate.type)

get_inverse(gate::SigmaX) = gate

"""
    sigma_y(target)

Return the Pauli-Y `Gate`, which applies the [`sigma_y()`](@ref) `Operator` to the target qubit.
"""
sigma_y(target,T::Type{<:Complex}=ComplexF64) = SigmaY(["Y"], "y", [target], [], T)

struct SigmaY <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::SigmaY) = sigma_y(gate.type)

get_inverse(gate::SigmaY) = gate

"""
    sigma_z(target)

Return the Pauli-Z `Gate`, which applies the [`sigma_z()`](@ref) `Operator` to the target qubit.
"""
sigma_z(target,T::Type{<:Complex}=ComplexF64) = SigmaZ(["Z"], "z", [target], [], T)

struct SigmaZ <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::SigmaZ) = sigma_z(gate.type)

get_inverse(gate::SigmaZ) = gate

"""
    hadamard(target)

Return the Hadamard `Gate`, which applies the [`hadamard()`](@ref) `Operator` to the `target` qubit.
"""
hadamard(target,T::Type{<:Complex}=ComplexF64) = Hadamard(["H"], "h", [target], [], T)

struct Hadamard <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::Hadamard) = hadamard(gate.type)

get_inverse(gate::Hadamard) = gate

"""
    phase(target)

Return a phase `Gate` (also known as an ``S`` `Gate`), which applies the [`phase()`](@ref) `Operator` to the target qubit.
"""
phase(target, T::Type{<:Complex}=ComplexF64) = Phase(["S"], "s", [target], [], T)

struct Phase <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::Phase) = phase(gate.type)

get_inverse(gate::Phase) = phase_dagger(gate.target[1],gate.type)
"""
    phase_dagger(target)

Return an adjoint phase `Gate` (also known as an ``S^\\dagger`` `Gate`), which applies the [`phase_dagger()`](@ref) `Operator` to the target qubit.
"""
phase_dagger(target, T::Type{<:Complex}=ComplexF64) = PhaseDagger(["S†"], "s_dag", [target], [], T)

struct PhaseDagger <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::PhaseDagger) = phase_dagger(gate.type)

get_inverse(gate::PhaseDagger) = phase(gate.target[1])

"""
    pi_8(target)

Return a π/8 `Gate` (also known as a ``T`` `Gate`), which applies the [`pi_8()`](@ref) `Operator` to the `target` qubit.
"""
pi_8(target, T::Type{<:Complex}=ComplexF64) = Pi8(["T"], "t", [target], [], T)

struct Pi8 <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::Pi8) = pi_8(gate.type)

get_inverse(gate::Pi8) = pi_8_dagger(gate.target[1],gate.type)

"""
    pi_8_dagger(target)

Return an adjoint π/8 `Gate` (also known as a ``T^\\dagger`` `Gate`), which applies the [`pi_8_dagger()`](@ref) `Operator` to the `target` qubit.
"""
pi_8_dagger(target, T::Type{<:Complex}=ComplexF64) = Pi8Dagger(["T†"], "t_dag", [target], [], T)

struct Pi8Dagger <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::Pi8Dagger) = pi_8_dagger(gate.type)

get_inverse(gate::Pi8Dagger) = pi_8(gate.target[1], gate.type)

"""
    x_90(target)

Return a `Gate` that applies a 90° rotation about the X axis as defined by the [`x_90()`](@ref) `Operator`.
"""
x_90(target, T::Type{<:Complex}=ComplexF64) = X90(["X_90"], "x_90", [target], [], T)

struct X90 <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::X90) = x_90(gate.type)

get_inverse(gate::X90) = rotation_x(gate.target[1], -pi/2,gate.type)

"""
    rotation(target, theta, phi)

Return a gate that applies a rotation `theta` to the `target` qubit about the cos(`phi`)X+sin(`phi`)Y axis.

The corresponding `Operator` is [`rotation(theta, phi)`](@ref).
"""
rotation(target, theta, phi, T::Type{<:Complex}=ComplexF64) = Rotation(["R(θ=$(theta),ϕ=$(phi))"], "r", [target],
    [theta, phi], T)

struct Rotation <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::Rotation) = rotation(gate.parameters...,gate.type)

get_inverse(gate::Rotation) = rotation(gate.target[1], -gate.parameters[1],
    gate.parameters[2],gate.type)

    """
    rotation_x(target, theta)

Return a `Gate` that applies a rotation `theta` about the X axis of the `target` qubit.

The corresponding `Operator` is [`rotation_x(theta)`](@ref).
"""    
rotation_x(target, theta, T::Type{<:Complex}=ComplexF64) = RotationX(["Rx($(theta))"], "rx", [target], [theta], T)

struct RotationX <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::RotationX) = rotation_x(gate.parameters[1],gate.type)

get_inverse(gate::RotationX) = rotation_x(gate.target[1], -gate.parameters[1],gate.type)

    """
    rotation_y(target, theta)

Return a `Gate` that applies a rotation `theta` about the Y axis of the `target` qubit.

The corresponding `Operator` is [`rotation_y(theta)`](@ref).
""" 
rotation_y(target, theta, T::Type{<:Complex}=ComplexF64) = RotationY(["Ry($(theta))"], "ry", [target], [theta], T)

struct RotationY <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::RotationY) = rotation_y(gate.parameters[1],gate.type)

get_inverse(gate::RotationY) = rotation_y(gate.target[1], -gate.parameters[1],gate.type)    

    """
    rotation_z(target, theta)

Return a `Gate` that applies a rotation `theta` about the Z axis of the `target` qubit.

The corresponding `Operator` is [`rotation_z(theta)`](@ref).
""" 
rotation_z(target, theta, T::Type{<:Complex}=ComplexF64) = RotationZ(["Rz($(theta))"], "rz", [target], [theta], T)

struct RotationZ <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::RotationZ) = rotation_z(gate.parameters[1],gate.type)

get_inverse(gate::RotationZ) = rotation_z(gate.target[1], -gate.parameters[1],gate.type)  

"""
    phase_shift(target, phi)

Return a `Gate` that applies a phase shift `phi` to the `target` qubit as defined by the [`phase_shift(phi)`](@ref) `Operator`.
""" 
phase_shift(target, phi, T::Type{<:Complex}=ComplexF64) = PhaseShift(["P($(phi))"], "p", [target], [phi], T)

struct PhaseShift <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::PhaseShift) = phase_shift(gate.parameters[1],gate.type)

get_inverse(gate::PhaseShift) = phase_shift(gate.target[1], -gate.parameters[1],gate.type)

"""
    universal(target, theta, phi, lambda)

Return a gate which rotates the `target` qubit given the angles `theta`, `phi`, and `lambda`.

The corresponding `Operator` is [`universal(theta, phi, lambda)`](@ref).
""" 
universal(target, theta, phi, lambda, T::Type{<:Complex}=ComplexF64) = Universal(["U(θ=$(theta),ϕ=$(phi),λ=$(lambda))"],
    "u", [target], [theta, phi, lambda], T)

struct Universal <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::Universal) = universal(gate.parameters..., gate.type)

get_inverse(gate::Universal) = universal(gate.target[1], -gate.parameters[1],
    -gate.parameters[3], -gate.parameters[2], gate.type)




# two qubit gates

"""
    control_z(control_qubit, target_qubit)

Return a controlled-Z gate given a `control_qubit` and a `target_qubit`.

The corresponding `Operator` is [`control_z()`](@ref).
""" 
function control_z(control_qubit, target_qubit, T::Type{<:Complex}=ComplexF64)
    target = [control_qubit, target_qubit]
    ensure_target_qubits_are_different(target)
    return ControlZ(["*", "Z"], "cz", target, [], T)
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

struct ControlZ <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::ControlZ) = control_z(gate.type)

get_inverse(gate::ControlZ) = gate

"""
    control_x(control_qubit, target_qubit)

Return a controlled-X gate (also known as a controlled NOT gate) given a `control_qubit` and a `target_qubit`.

The corresponding `Operator` is [`control_x()`](@ref).
""" 
function control_x(control_qubit, target_qubit, T::Type{<:Complex}=ComplexF64)
    target = [control_qubit, target_qubit]
    ensure_target_qubits_are_different(target)
    return ControlX(["*", "X"], "cx", target, [], T)
end

struct ControlX <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::ControlX) = control_x(gate.type)

get_inverse(gate::ControlX) = gate

"""
    iswap(qubit_1, qubit_2)

Return the imaginary swap `Gate` which applies the imaginary swap `Operator` to `qubit_1` and `qubit_2.`

The corresponding `Operator` is [`iswap()`](@ref).
""" 
function iswap(qubit_1, qubit_2, T::Type{<:Complex}=ComplexF64)
    target = [qubit_1, qubit_2]
    ensure_target_qubits_are_different(target)
    return ISwap(["x", "x"], "iswap", target, [], T)
end

struct ISwap <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::ISwap) = iswap(gate.type)

get_inverse(gate::ISwap) = iswap_dagger(gate.target...,gate.type)

"""
    toffoli(control_qubit_1, control_qubit_2, target_qubit)

Return a Toffoli gate (also known as a CCNOT gate) given two control qubits and a `target_qubit`.

The corresponding `Operator` is [`toffoli()`](@ref).
"""
function toffoli(control_qubit_1, control_qubit_2, target_qubit, T::Type{<:Complex}=ComplexF64)
    target = [control_qubit_1, control_qubit_2, target_qubit]
    ensure_target_qubits_are_different(target)
    return Toffoli(["*", "*", "X"], "ccx", target, [], T)
end

struct Toffoli <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::Toffoli) = toffoli(gate.type)

get_inverse(gate::Toffoli) = gate

"""
    iswap_dagger(qubit_1, qubit_2)

Return the adjoint imaginary swap `Gate` which applies the adjoint imaginary swap `Operator` to `qubit_1` and `qubit_2.`

The corresponding `Operator` is [`iswap_dagger()`](@ref).
""" 
function iswap_dagger(qubit_1, qubit_2, T::Type{<:Complex}=ComplexF64)
    target = [qubit_1, qubit_2]
    ensure_target_qubits_are_different(target)
    return ISwapDagger(["x†", "x†"], "iswap_dag", target, [], T)
end

struct ISwapDagger <: Gate
    display_symbol::Vector{String}
    instruction_symbol::String
    target::Vector{Int}
    parameters::Vector
    type::Type{<:Complex}
end

get_operator(gate::ISwapDagger) = iswap_dagger(gate.type)

get_inverse(gate::ISwapDagger) = iswap(gate.target..., gate.type)

"""
    Base.:*(M::Gate, x::Ket)

Return a `Ket` which results from applying `Gate` `M` to `Ket` `x`.

# Examples
```jldoctest
julia> ψ_0 = fock(0, 2);

julia> print(ψ_0)
2-element Ket{ComplexF64}:
1.0 + 0.0im
0.0 + 0.0im

julia> ψ_1 = sigma_x(1)*ψ_0;

julia> print(ψ_1)
2-element Ket{ComplexF64}:
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

"""
    get_inverse(gate::Gate)

Return a `Gate` which is the inverse of the input `gate`.

# Examples
```jldoctest
julia> u = universal(1, -pi/2, pi/3, pi/4)
Gate Object:
instruction symbol: u
parameters: [-1.5707963267948966, 1.0471975511965976, 0.7853981633974483]
targets: [1]
operator:
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.7071067811865476 + 0.0im    0.5 + 0.4999999999999999im
-0.3535533905932738 - 0.6123724356957945im    -0.18301270189221924 + 0.6830127018922194im


julia> get_inverse(u)
Gate Object:
instruction symbol: u
parameters: [1.5707963267948966, -0.7853981633974483, -1.0471975511965976]
targets: [1]
operator:
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{ComplexF64}:
0.7071067811865476 + 0.0im    -0.3535533905932738 + 0.6123724356957945im
0.5 - 0.4999999999999999im    -0.18301270189221924 - 0.6830127018922194im


```
"""
function get_inverse(gate::Gate)
    if is_hermitian(get_operator(gate))
        return gate
    end
    sym = gate.instruction_symbol
    throw(ErrorException("no adjoint is available for the $sym gate"))
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
