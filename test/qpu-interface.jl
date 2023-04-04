using Snowflake
using Test
using HTTP

@testset "basic submission" begin

    qubit_count=3
    circuit = QuantumCircuit(qubit_count = qubit_count)
    push!(circuit, [sigma_x(3),control_z(2,1)])

    repetitions=10

    circuit_json=serialize_circuit(circuit,repetitions,indentation=false)

    expected_json="{\"num_repititions\":10,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"
    
    @test circuit_json==expected_json

    user="user_test"
    
    host        =ENV["ANYON_QUANTUM_HOST"]
    access_token=ENV["ANYON_QUANTUM_TOKEN"]
    
    wrong_client=Client("wrong_url",user,access_token)

    @test_throws ArgumentError submit_circuit(wrong_client,circuit_json;verbose=false)

    wrong_client=Client("http://wrong_url",user,access_token)

    @test_throws HTTP.Exceptions.ConnectError submit_circuit(wrong_client,circuit_json;verbose=false)

    test_client=Client(host,user,access_token)
    
    @test get_host(test_client)==host
    
    circuitID=submit_circuit(test_client,circuit_json;verbose=false)

    status=get_status(test_client,circuitID)

    @test status["type"] in ["queued","running","failed","succeeded"]
end

@testset "run on qpu" begin

    qubit_count_circuit=3

    circuit = QuantumCircuit(qubit_count = qubit_count_circuit)
    
    push!(circuit, [sigma_x(3),control_z(2,1)])
    
    user="user_test"
    
    host        =ENV["ANYON_QUANTUM_HOST"]
    access_token=ENV["ANYON_QUANTUM_TOKEN"]
    
    test_client=Client(host,user,access_token)
    
    qubit_count_qpu=3
    connectivity=Matrix([1 1 0; 1 1 1 ; 0 1 1])
    
    native_gates=["x" , "y" , "z" , "i", "cz"]
    
    num_repetitions=100
    
    verbose=true
        
    qpu=QPU(
        "Anyon Systems Inc.",   # manufacturer
        "Yukon",                # generation
        "0000-0000-0001",       # serial_number
        host,                   # host
        qubit_count_qpu,        # qubit_count
        connectivity,           # connectivity
        native_gates            # native_gates
    )
    
    qpu_service=QPUService(test_client,qpu)
    
    println("run with qpu_service: $qpu_service and circuit: $circuit")
    
    histogram=Snowflake.run(qpu_service, circuit ,num_repetitions,verbose=verbose)
    
    if haskey(histogram,"error_msg")
        println("Job failed: \n\t$(histogram["error_msg"]) \n")
    else
        println("Result of circuit computation:")
        println("State\t|\tPopulation")
        for (key,val) in histogram
            println("$key \t \t$val")
        end
    end

end
