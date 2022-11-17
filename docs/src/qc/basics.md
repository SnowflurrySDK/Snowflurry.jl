# What is Quantum Computing?
```@meta
DocTestSetup = :(using Snowflake)
```
Quantum computing is a new paradigm in high performance computing that utilizes the fundamental principles of quantum mechanics to perform calculations. Quantum computation holds great promise to outperform classical computers in some tasks such as prime factorization, quantum simulation, search, optimization, and algebraic programs such as machine learning.

The power of quantum computing stems from two fundamental properties of quantum mechanics, namely [superposition](https://en.wikipedia.org/wiki/Quantum_superposition) and [entanglement](https://en.wikipedia.org/wiki/Quantum_entanglement).

Snowflake is a Julia-based SDK for performing quantum computations. Quantum computation is conducted by building and executing _quantum circuits_. These circuits are comprised of quantum gates, instructions, and classical control logic. Complex algorithms and applications can be expressed in terms of quantum circuits that can be executed on a quantum computer.

# Quantum Circuits

Algorithms and applications that utilize quantum mechanical resources use a concept known as a _quantum circuit_ to represent quantum operations. A quantum circuit is a computational pipeline consisting of a quantum register and a classical register. The following figure shows an example of a 3-qubit quantum circuit:

![Bell State generator circuit](https://i.stack.imgur.com/NkYrk.png)

The initial state of each qubit is given on the left side of the figure. The lines correspond to the timeline of operations that are performed on the qubits. The boxes and symbols denote different single-qubit or multi-qubit gates.

You can define a quantum circuit with Snowflake as follows:

```jldoctest basics_quantum_circuit
julia> c = QuantumCircuit(qubit_count = 2, bit_count = 0)
Quantum Circuit Object:
   id: 0b7e9004-7b2f-11ec-0f56-c91274d7066f 
   qubit_count: 2 
   bit_count: 0 
q[1]:
     
q[2]:
  
```
The above example creates a quantum circuit with two qubits and no classical bit. It is now ready to be used to store quantum instructions, which are also known as quantum gates. 

!!! tip "Circuit UUID"
    Note that the circuit object has been given a Universally Unique Identifier (UUID). This UUID can be used later to retrieve the circuit results from a remote server such as a quantum computer on the cloud.


# Quantum Gates

A quantum gate is a basic quantum operation that affects one or more qubits. Quantum gates are the building blocks of quantum circuits, like classical logic gates are for conventional digital circuits.

Unlike their classic counterparts, quantum gates are reversible. Quantum gates are unitary operators and can be represented as [unitary matrices](https://en.wikipedia.org/wiki/Unitary_matrix).

Now, let's add a few gates to our circuit using the push_gate command:

```jldoctest basics_quantum_circuit
julia> push_gate!(c, [hadamard(1)])
Quantum Circuit Object:
   id: 0b7e9004-7b2f-11ec-0f56-c91274d7066f 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H──
          
q[2]:─────
```          
The first command added a Hadamard gate to the quantum circuit object `c`. The gate will operate on qubit 1.

```jldoctest basics_quantum_circuit
julia> push_gate!(c, [control_x(1, 2)])
Quantum Circuit Object:
   id: 0b7e9004-7b2f-11ec-0f56-c91274d7066f 
   qubit_count: 2 
   bit_count: 0 
q[1]:──H────*──
            |  
q[2]:───────X──
```

 The second command added a CNOT gate (Control-X gate) with qubit 1 as the control and qubit 2 as the target. 

 # Quantum Processing Unit (QPU)

Usually, quantum circuits cannot be immediately executed on a quantum processor. This is because QPUs typically execute only a limited number of quantum gates directly on the hardware. Such gates are commonly referred to as *native gates*. This means that once a general quantum circuit is defined, it needs to be transpiled such that it only makes use of the *native gates* of a given QPU . 

Snowflake introduces `QPU` to represent physical or virtual quantum processors. For example, the following command creates a virtual QPU which can implement Pauli matrices and Control-Z gates:

```@meta
DocTestSetup = nothing
```
