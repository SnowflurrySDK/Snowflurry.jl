using Snowflake
using Test
using HTTP

@testset "requestor" begin
    struct NonImplementedRequestor<:Snowflake.Requestor end

    host="http://example.anyonsys.com"
    access_token="not_a_real_access_token"
    requestor=NonImplementedRequestor()
    body=""
    
    @test_throws NotImplementedError get_request(requestor,host,access_token,body) 
    @test_throws NotImplementedError post_request(requestor,host,access_token,body) 
    
    @test_throws NotImplementedError get_request(
        MockRequestor(),
        "erroneous_url",
        "not_a_real_access_token"
    )
end

@testset "basic submission" begin

    qubit_count=3
    circuit = QuantumCircuit(qubit_count = qubit_count)
    push!(circuit, [sigma_x(3),control_z(2,1)])

    num_repetitions=100

    circuit_json=serialize_circuit(circuit,num_repetitions)

    expected_json="{\"num_repititions\":100,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"
    
    @test circuit_json==expected_json

    host="http://example.anyonsys.com"
    user="test_user"
    access_token="not_a_real_access_token"
    requestor=MockRequestor()
    
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)

    println(test_client) #coverage for Base.show(::IO,::Client)

    @test get_host(test_client)==host
    
    circuitID=submit_circuit(test_client,circuit,num_repetitions)

    status=get_status(test_client,circuitID)

    @test status["type"] in ["queued","running","failed","succeeded"]
end

@testset "run on qpu" begin

    qubit_count=3

    circuit = QuantumCircuit(qubit_count = qubit_count)
    
    push!(circuit, [sigma_x(3),control_z(2,1)])
    
    host="http://example.anyonsys.com"
    user="test_user"
    access_token="not_a_real_access_token"
    requestor=MockRequestor()
    
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)

    num_repetitions=100
        
    qpu=AnyonQPU(client=test_client)
    
    println(qpu) #coverage for Base.show(::IO,::AnyonQPU)
    @test Snowflake.get_printout_delay(qpu)>=0.

    @test get_client(qpu)==test_client
    
    histogram=run_job(qpu, circuit ,num_repetitions)
    
    @test !haskey(histogram,"error_msg")

end
