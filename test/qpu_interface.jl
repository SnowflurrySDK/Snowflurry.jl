using Snowflurry
using Test
using HTTP

include("mock_functions.jl")

requestor=MockRequestor(request_checker,post_checker)

# While testing, this throttle can be used to skip delays between status requests.
no_throttle=()->Snowflurry.default_status_request_throttle(0)

function compare_responses(expected::HTTP.Response,received::HTTP.Response)

    for f in fieldnames(typeof(received))
        if isdefined(received,f) # response.request is undefined in Julia 1.6.7
            @test getfield(received,f)==getfield(expected,f)
        end
    end

end

@testset "requestor" begin
    struct NonImplementedRequestor<:Snowflurry.Requestor end


    non_impl_requestor=NonImplementedRequestor()
    body=""
    
    @test_throws NotImplementedError get_request(non_impl_requestor,host,user,access_token)
    @test_throws NotImplementedError post_request(non_impl_requestor,host,user,access_token,body)
    
    #### request from :get_status
   
    @test_throws NotImplementedError get_request(
        requestor,
        "erroneous_url",
        user,
        access_token
    )

    expected_response=HTTP.Response(200, [], body="{\"status\":{\"type\":\"succeeded\"}}")

    circuitID="1234-abcd"

    response=get_request(
        requestor,
        host*"/"*Snowflurry.path_circuits*"/"*circuitID,
        user,
        access_token
    )

    compare_responses(expected_response,response)

    @test_throws NotImplementedError get_request(
        requestor,
        host*"/"*string(Snowflurry.path_circuits,"wrong_ending"),
        user,
        access_token
    )

    #### request from :get_result

    expected_response=HTTP.Response(200, [],body="{\"histogram\":{\"001\":100}}") 

    response=get_request(
        requestor,
        host*"/"*Snowflurry.path_circuits*"/"*circuitID*"/"*Snowflurry.path_results,
        user,
        access_token
    )

    compare_responses(expected_response,response)

    @test_throws NotImplementedError get_request(
        requestor,
        host*"/"*Snowflurry.path_circuits*"/"*circuitID*"/"*string(Snowflurry.path_results,"wrong_ending"),
        user,
        access_token
    )

end

@testset "read_response_body" begin
    my_string="abcdefghijlkmnopqrstuvwxyz"

    body=UInt8.([c for c in my_string])

    @test read_response_body(body)==my_string

    body[10]=0x00

    @test_throws ArgumentError read_response_body(body)
    
    body=codeunits(my_string)

    @test read_response_body(body)==my_string

end

@testset "Status" begin
    type="failed"
    message="Server error"

    status=Status(type=type,message=message)

    @test type==get_status_type(status)
    @test message==get_status_message(status)

    println(status)

    ###

    type="succeeded"

    status=Status(type=type)

    @test type==get_status_type(status)

    println(status)
end


@testset "basic submission" begin

    circuit = QuantumCircuit(qubit_count = 3,gates=[sigma_x(3),control_z(2,1)])

    shot_count=100

    circuit_json=serialize_job(circuit,shot_count)

    expected_json="{\"shot_count\":100,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"
    
    @test circuit_json==expected_json
       
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)

    println(test_client) #coverage for Base.show(::IO,::Client)

    @test get_host(test_client)==host
    
    circuitID=submit_circuit(test_client,circuit,shot_count)

    status=get_status(test_client,circuitID)

    @test get_status_type(status) in ["queued","running","failed","succeeded"]
end

@testset "job status" begin
    # We don't expect a POST during this test. Returning nothing should cause a
    # failure if a POST is attempted
    test_post = () -> Nothing

    test_get = stub_response_sequence([
        # Simulate a response for a failed job.
        stubFailedStatusResponse()
    ])
    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(host=host, user=user, access_token=access_token, requestor=requestor)
    status = get_status(test_client, "circuitID not used in this test")
    @test get_status_type(status) == "failed"
    @test get_status_message(status) == "mocked"

    test_get = stub_response_sequence([
        # Simulate a response containing an invalid job status.
        stubStatusResponse("not a valid status")
    ])

    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(host=host, user=user, access_token=access_token, requestor=requestor)
    @test_throws ArgumentError get_status(test_client, "circuitID not used in this test")

    malformedResponse = stubFailedStatusResponse()
    # A failure response _should_ have a 'message' field but, if things go very
    # wrong, the user should still get something useful.
    body = "{\"status\":{\"type\":\"failed\"},\"these aren't the droids you're looking for\":\"*waves-hand*\"}"
    malformedResponse.body = collect(UInt8, body)
    test_get = stub_response_sequence([
        malformedResponse
    ])
    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(host=host, user=user, access_token=access_token, requestor=requestor)
    status = get_status(test_client, "circuitID not used in this test")
    @test status.type == "failed"
    @test status.message != ""
end

@testset "Construct AnyonYukonQPU" begin
    host = "host"
    user = "user"
    token = "token"

    qpu = AnyonYukonQPU(host=host, user=user, access_token=token, status_request_throttle=no_throttle)
    client = get_client(qpu)

    @test client.host == host
    @test client.user == user
    @test client.access_token == token

    print_connectivity(qpu)
end

@testset "run_job on AnyonYukonQPU" begin

    requestor = MockRequestor(request_checker,post_checker)
    test_client = Client(host=host,user=user,access_token=access_token,requestor=requestor)
    shot_count=100
    qpu=AnyonYukonQPU(test_client, status_request_throttle=no_throttle)
    println(qpu) #coverage for Base.show(::IO,::AnyonYukonQPU)
    @test get_client(qpu)==test_client
    
    #test basic submission, no transpilation
    circuit = QuantumCircuit(qubit_count = 3, gates=[sigma_x(3), control_z(2,1)])
    histogram = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001"=>shot_count)
    @test !haskey(histogram,"error_msg")

    #verify that run_job blocks until a 'long-running' job completes
    requestor=MockRequestor(
      stub_response_sequence([
        stubStatusResponse("queued"),
        stubStatusResponse("running"),
        stubStatusResponse("running"),
        stubStatusResponse("succeeded"),
        stubResult()
      ]),
      post_checker)
    qpu = AnyonYukonQPU(Client(host,user,access_token,requestor), status_request_throttle=no_throttle)
    histogram=run_job(qpu, circuit, shot_count)
    @test histogram==Dict("001"=>shot_count)
    @test !haskey(histogram, "error_msg")

    #verify that run_job throws an error if the QPU returns an error
    requestor=MockRequestor(
      stub_response_sequence([
        stubStatusResponse("queued"),
        stubStatusResponse("running"),
        stubStatusResponse("running"),
        stubFailedStatusResponse(),
        stubFailureResult()
      ]),
      post_checker)
    qpu = AnyonYukonQPU(Client(host,user,access_token,requestor), status_request_throttle=no_throttle)
    @test_throws ErrorException histogram=run_job(qpu, circuit, shot_count)

    #verify that run_job throws an error if the job was cancelled
    requestor=MockRequestor(
      stub_response_sequence([
        stubStatusResponse("queued"),
        stubStatusResponse("running"),
        stubStatusResponse("running"),
        stubStatusResponse("cancelled"),
        stubCancelledResultResponse()
      ]),
      post_checker)
    qpu = AnyonYukonQPU(Client(host,user,access_token,requestor), status_request_throttle=no_throttle)
    @test_throws ErrorException histogram=run_job(qpu, circuit, shot_count)
end

@testset "transpile_and_run_job on AnyonYukonQPU" begin

    requestor=MockRequestor(request_checker,post_checker)
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)
    shot_count=100
    qpu=AnyonYukonQPU(test_client, status_request_throttle=no_throttle)

    # submit circuit with qubit_count_circuit>qubit_count_qpu
    circuit = QuantumCircuit(qubit_count = 10)
    @test_throws DomainError transpile_and_run_job(qpu, circuit, shot_count)

    # submit circuit with a non-native gate on this qpu (no transpilation)
    circuit = QuantumCircuit(qubit_count = 3, gates=[toffoli(1,2,3)])
    @test_throws DomainError transpile_and_run_job(
        qpu, 
        circuit,
        shot_count;
        transpiler=TrivialTranspiler()
    )
    # using AnyonYukonQPU default transpiler
    requestor=MockRequestor(request_checker,post_checker_toffoli)
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)
    qpu=AnyonYukonQPU(test_client, status_request_throttle=no_throttle)

    histogram=transpile_and_run_job(qpu, circuit, shot_count)
    
    @test histogram==Dict("001"=>shot_count)
    @test !haskey(histogram,"error_msg")
end

@testset "run on VirtualQPU" begin

    circuit = QuantumCircuit(qubit_count = 3,gates=[sigma_x(3),control_z(2,1)])
        
    shot_count=100
    
    qpu=VirtualQPU()
    
    println(qpu) #coverage for Base.show(::IO,::VirtualQPU)

    for gate in get_circuit_gates(circuit)
        @test is_native_gate(qpu,gate)
    end
       
    histogram=transpile_and_run_job(qpu, circuit, shot_count)
   
    @test histogram==Dict("001"=>shot_count)

end

@testset "AbstractQPU" begin
    struct NonExistentQPU<:Snowflurry.AbstractQPU end

    @test_throws NotImplementedError get_metadata(NonExistentQPU())
    @test_throws NotImplementedError is_native_gate(NonExistentQPU(),sigma_x(1))
    @test_throws NotImplementedError is_native_circuit(NonExistentQPU(),QuantumCircuit(qubit_count=1))
    @test_throws NotImplementedError get_transpiler(NonExistentQPU())
    @test_throws NotImplementedError run_job(NonExistentQPU(),QuantumCircuit(qubit_count=1),42)
end
