# Quantum Computing With Snowflake

# What is Quantum Computing?

Quantum computing is a new paradigm in high performance computing that utilizes the fundamental principles of quantum mechanics to perform calculations. Quantum computation holds great promise to outperform classical computers in some tasks such as prime factorization, quantum simulation, search, optimization, and algebraic programs such as machine learning.

The power of quantum computing stems from two fundemental properties of quantum mechanics, namely [superposition](https://en.wikipedia.org/wiki/Quantum_superposition) and [entanglement](https://en.wikipedia.org/wiki/Quantum_entanglement).

Snowflake is a Julia-based SDK for performing quantum computations. Quantum computation is achieved by building and executing _quantum circuits_. Comprised of quantum gates, instructions, and classical control logic, quantum circuits allow for expressing complex algorithms and applications in a abstract manner that can be executed on a quantum computer.

# Quantum Circuits

Algorithms and applications that utilize quantum mechanical resources use a concept known as _quantum circuit_ to represent the quantum operations. A quantum circuit is a computational pipeline consisting of a quantum register, and a classical register. Figure below shows an example of a 3-qubit quantum circuit.

![Bell State generator circuit](https://i.stack.imgur.com/NkYrk.png)

The qubits are designated on the left side of the figure with their inital state. The lines correspond to the time line of operations that are perfomed on qubits. The boxes and symbols then denote differnt single qubit or multi-qubit gates.

```@docs
QuantumCircuit
```

# Quantum Gates

A quantum gate is a basic quantum operation that affects one or a number of qubits. Quantum gates are the building blocks of quantum circuits, like classical logic gates are for conventional digital circuits.

Unlike their classic counterparts, quantum gates are reversible. Quantum gates are unitary operators, and can be represented as [unitary matrices](https://en.wikipedia.org/wiki/Unitary_matrix).
