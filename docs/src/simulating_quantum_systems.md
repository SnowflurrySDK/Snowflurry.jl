# Simulating Quantum Systems
```@meta
DocTestSetup = :(using Snowflake)
```

Snowflake provides capability to directly simulate a quantum system on a classical computer. The following sections of this page provide you with documentation and examples of how to achieve that.

Note that using a quantum computer does not involve using these objects. But, _simulating_ the operation of a quantum computer, or any quantum system for that matter, on a classical computer does!

# Basic Quantum Objects

There are three basic quantum objects defined in Snowflake to simulate a Quantum system.
These objects are [`Ket`](@ref), [`Bra`](@ref), and Operator, which inherit from `AbstractOperator`.
Particular Operators are either [`DenseOperator`](@ref), [`DiagonalOperator`](@ref), or [`AntiDiagonalOperator`](@ref).

# Multibody Systems
[`MultiBodySystem`](@ref) structures are used to represent quantum multi-body systems.
After defining a multi-body system, it is possible to build an operator for this system
given a local operator (e.g. one which acts on a qubit). An operator for a multi-body
system can be obtained by calling [`get_embed_operator`](@ref).

# Fock Space
A [`Ket`](@ref) which represents a bosonic Fock space can be created by calling
[`fock`](@ref).

```@meta
DocTestSetup = nothing
```
