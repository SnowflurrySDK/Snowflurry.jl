# Quantum Computing With Snowflake

# What is Quantum Computing? 

Quantum computing is a new paradigm in high performance computing that utilizes the fundamental principles of quantum mechanics to perform calculations. Quantum computation holds great promise to outperform classical computers in some tasks such as prime factorization, quantum simulation, search, optimization, and algebraic programs such as machine learning.

The power of quantum computing stems from two fundemental properties of quantum mechanics, namely [superposition](https://en.wikipedia.org/wiki/Quantum_superposition) and [entanglement](https://en.wikipedia.org/wiki/Quantum_entanglement).

Snowflake is a Julia-based SDK for performing quantum computations. Quantum computation is achieved by building and executing *quantum circuits*. Comprised of quantum gates, instructions, and classical control logic, quantum circuits allow for expressing complex algorithms and applications in a abstract manner that can be executed on a quantum computer. 

# Quantum Circuits
Algorithms and applications that utilize quantum mechanical resources use a concept known as *quantum circuit* to represent the quantum operations. A quantum circuit is a computational pipeline consisting of a quantum register, and a classical register. Analegous to The quantum register consits of several quantum bits (qubits), while a classical register 