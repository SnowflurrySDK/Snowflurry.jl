using Snowflake
using Test
using HTTP

@testset "basic submission" begin

    qubit_count=3
    circuit = QuantumCircuit(qubit_count = qubit_count)
    push!(circuit, [sigma_x(3),control_z(2,1)])

    repetitions=10

    circuit_json=serialize_circuit(circuit,repetitions)

    expected_json="{\"num_repititions\":10,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"
    
    @test circuit_json==expected_json

    user="user_test"
    
    host        =ENV["ANYON_QUANTUM_HOST"]
    access_token=ENV["ANYON_QUANTUM_TOKEN"]
    
    wrong_client=Client("wrong_url",user,access_token)

    @test_throws ArgumentError submit_circuit(wrong_client,circuit,repetitions)

    wrong_client=Client("http://wrong_url",user,access_token)

    @test_throws HTTP.Exceptions.ConnectError submit_circuit(wrong_client,circuit,repetitions)

    test_client=Client(host,user,access_token)
    
    @test get_host(test_client)==host
    
    circuitID=submit_circuit(test_client,circuit,repetitions)

    status=get_status(test_client,circuitID)

    @test status["type"] in ["queued","running","failed","succeeded"]
end

@testset "run on qpu" begin

    qubit_count=3

    circuit = QuantumCircuit(qubit_count = qubit_count)
    
    push!(circuit, [sigma_x(2),control_z(2,1)])
    
    user="user_test"
    
    host        =ENV["ANYON_QUANTUM_HOST"]
    access_token=ENV["ANYON_QUANTUM_TOKEN"]
    
    test_client=Client(host,user,access_token)
    
    num_repetitions=100
        
    qpu=AnyonQPU(client=test_client)
    
    println(qpu) #coverage for Base.show(::IO,::AnyonQPU)

    @test get_client(qpu)==test_client
    
    histogram=run_job(qpu, circuit ,num_repetitions)
    
    @test !haskey(histogram,"error_msg")

    # rotation gate is not native on qpu, returns error
    push!(circuit, [rotation(2,π,-π/4)])

    histogram=run_job(qpu, circuit ,num_repetitions)

    @test haskey(histogram,"error_msg")

end
