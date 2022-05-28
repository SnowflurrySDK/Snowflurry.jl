# What is Quantum Computing?
```@meta
DocTestSetup = :(using Snowflake)
```
Quantum computing is a new paradigm in high performance computing that utilizes the fundamental principles of quantum mechanics to perform calculations. Quantum computation holds great promise to outperform classical computers in some tasks such as prime factorization, quantum simulation, search, optimization, and algebraic programs such as machine learning.

The power of quantum computing stems from two fundemental properties of quantum mechanics, namely [superposition](https://en.wikipedia.org/wiki/Quantum_superposition) and [entanglement](https://en.wikipedia.org/wiki/Quantum_entanglement).

Snowflake is a Julia-based SDK for performing quantum computations. Quantum computation is achieved by building and executing _quantum circuits_. Comprised of quantum gates, instructions, and classical control logic, quantum circuits allow for expressing complex algorithms and applications in a abstract manner that can be executed on a quantum computer.

# Quantum Circuits

Algorithms and applications that utilize quantum mechanical resources use a concept known as _quantum circuit_ to represent the quantum operations. A quantum circuit is a computational pipeline consisting of a quantum register, and a classical register. Figure below shows an example of a 3-qubit quantum circuit.

![Bell State generator circuit](https://i.stack.imgur.com/NkYrk.png)

The qubits are designated on the left side of the figure with their inital state. The lines correspond to the time line of operations that are perfomed on qubits. The boxes and symbols then denote differnt single qubit or multi-qubit gates.

You can defined a quantum circuit with Snowflake through

```jldoctest basics_quantum_circuit
julia> c = QuantumCircuit(qubit_count = 2, bit_count = 0)
Quantum Circuit Object:
   id: 0b7e9004-7b2f-11ec-0f56-c91274d7066f 
   qubit_count: 2 
   bit_count: 0 
q[1]:
     
q[2]:
  
```
The above example creates a quantum circuit with two qubits and no classical bit and is now ready to be used to store quantum instuctions also known as quantum gates. 

!!! tip "Circuit UUID"
    Note the circuit object has been given a Universally Unique Identifier (UUID). This UUID can be used later to retrieve the circuit results from a remote server such as a quantum computer on the cloud.


# Quantum Gates

A quantum gate is a basic quantum operation that affects one or a number of qubits. Quantum gates are the building blocks of quantum circuits, like classical logic gates are for conventional digital circuits.

Unlike their classic counterparts, quantum gates are reversible. Quantum gates are unitary operators, and can be represented as [unitary matrices](https://en.wikipedia.org/wiki/Unitary_matrix).

Now let's add a few gates to our circuit using the following commands:

```jldoctest basics_quantum_circuit
julia> push_gate!(c, [hadamard(1)])
Quantum Circuit Object:
   id: 0b7e9004-7b2f-11ec-0f56-c91274d7066f 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:-----
```          
Here use use the push_gate commands adds a Hadamrd gate, which will operate on qubit 1, to the quantum circuit object `c`.
```jldoctest basics_quantum_circuit
julia> push_gate!(c, [control_x(1, 2)])
Quantum Circuit Object:
   id: 0b7e9004-7b2f-11ec-0f56-c91274d7066f 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H----*--
            |  
q[2]:-------X--
```

 The second line adds a CNOT gate (Control-X gate) with control qubit being qubit 1 and target qubit being qubit 2. 

 # Quantum Processor Unit (QPU)

Quantum circuits cannot typically be immidiately executed on a quantum processor. This is because QPUs typically execute only a limited number of quantum gates directly on the hardware. Such gates are commonly referred to as *native gates*. This means that once a general quantum circuit is defined, it needs to be transpiled such that it only makes use of *native gates* for a given QPU . 

Snowflake introduces `QPU` to represent physical or virtual quantum processors. For example the following command creates a virtual QPU assuming it can implement Pauli matrices and Control-Z:

```@meta
DocTestSetup = nothing
```
