# Simulating Quantum Systems
```@meta
DocTestSetup = :(using Snowflake)
```

Snowflake provides capability to directly simulate a quantum system on a classical computer. The following sections of this page provide you with documentation and examples of how to achieve that.

Note that using a quantum computer does not involve using these objects. But, _simulating_ the operation of a quantum computer, or any quantum system for that matter, on a classical computer does!

# Basic Quantum Objects

There are three basic quantum objects defined in Snowflake to simulate a Quantum system. These objects are Ket, Bra, and Operator.

```@docs
Ket
Bra
Operator
```

# Multibody Systems

```@docs
MultiBodySystem
get_embed_operator
```

# Fock Space

```@docs
fock
```

```@meta
DocTestSetup = nothing
```
