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

function test_print_connectivity(
    input::Union{
        Snowflake.AbstractAnyonQPU,
        Snowflake.LatticeConnectivity,
        Snowflake.LineConnectivity
        }, 
    expected::String
    )
    io = IOBuffer()

    print_connectivity(input,io)

    @test String(take!(io)) == expected
end

@testset "print_connectivity" begin

    test_print_connectivity(
        Snowflake.LineConnectivity(12),
        "1──2──3──4──5──6──7──8──9──10──11──12\n"
    )

    test_print_connectivity(Snowflake.LatticeConnectivity((4,5)),
    "  1 ──  2 ──  3 ──  4 ──  5 \n" *
    "  |     |     |     |     | \n" *
    "  6 ──  7 ──  8 ──  9 ── 10 \n" *
    "  |     |     |     |     | \n" *
    " 11 ── 12 ── 13 ── 14 ── 15 \n" *
    "  |     |     |     |     | \n" *
    " 16 ── 17 ── 18 ── 19 ── 20 \n")

    struct UnknownConnectivity <: Snowflake.AbstractConnectivity end
    @test_throws NotImplementedError print_connectivity(UnknownConnectivity())
    @test_throws NotImplementedError Snowflake.get_connectivity_label(UnknownConnectivity())
end

@testset "get_qubits_distance" begin
    # LineConnectivity
    qubit_count = 6
    c=Snowflake.LineConnectivity(qubit_count)

    for target_1 in 1:qubit_count
        for target_2 in 1:qubit_count
            @test get_qubits_distance(target_1, target_2,c) == abs(target_1-target_2)
        end
    end

    ##########################################
    # LatticeConnectivity
    nrows = 4
    ncols = 3
    c=Snowflake.LatticeConnectivity((nrows,ncols))

    qubit_num_matrix=Matrix(transpose(reshape([v for v in 1:nrows*ncols],ncols,nrows)))

    for (target_1,ind_1) in zip(qubit_num_matrix,CartesianIndices(qubit_num_matrix))
        for (target_2,ind_2) in zip(qubit_num_matrix,CartesianIndices(qubit_num_matrix))

            target_1_row = ind_1[1]
            target_1_col = ind_1[2]
        
            target_2_row = ind_2[1]
            target_2_col = ind_2[2]

            @test get_qubits_distance(target_1, target_2,c) == 
                abs(target_1_row - target_2_row)+abs(target_1_col - target_2_col)
        end
    end
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

    test_print_connectivity(qpu,"1──2──3──4──5──6\n")

    @test Snowflake.get_connectivity_label(qpu.connectivity) == Snowflake.line_connectivity_label

    @test get_metadata(qpu) == Dict{String,Union{String,Int}}(
        "manufacturer"  =>"Anyon Systems Inc.",
        "generation"    =>"Yukon",
        "serial_number" =>"ANYK202201",
        "qubit_count"   =>get_num_qubits(qpu.connectivity),
        "connectivity_type"  =>Snowflake.get_connectivity_label(qpu.connectivity)
    )
end

@testset "Construct AnyonMonarqQPU" begin
    host = "host"
    user = "user"
    token = "token"

    qpu = AnyonMonarqQPU(host=host, user=user, access_token=token, status_request_throttle=no_throttle)
    client = get_client(qpu)

    @test client.host == host
    @test client.user == user
    @test client.access_token == token

    test_print_connectivity(qpu,
    "  1 ──  2 ──  3 ──  4 \n" *
    "  |     |     |     | \n" *
    "  5 ──  6 ──  7 ──  8 \n" *
    "  |     |     |     | \n" *
    "  9 ── 10 ── 11 ── 12 \n")

    @test Snowflake.get_connectivity_label(qpu.connectivity) == Snowflake.lattice_connectivity_label

    @test get_metadata(qpu) == Dict{String,Union{String,Int}}(
        "manufacturer"  =>"Anyon Systems Inc.",
        "generation"    =>"MonarQ",
        "serial_number" =>"ANYK202301",
        "qubit_count"   =>get_num_qubits(qpu.connectivity),
        "connectivity_type"  =>Snowflake.get_connectivity_label(qpu.connectivity)
    )

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
    qubit_count = 10
    circuit = QuantumCircuit(qubit_count = qubit_count)

    msg="Circuit qubit count $qubit_count exceeds $(typeof(qpu)) qubit count: 6" 
    @test_throws DomainError(qpu,msg) transpile_and_run_job(qpu, circuit, shot_count)

    # submit circuit with a non-native gate on this qpu (no transpilation)
    gate = toffoli(1,2,3)
    circuit = QuantumCircuit(qubit_count = get_num_qubits(qpu), gates=[gate])

    msg="Gate type $(get_gate_type(gate)) with targets $(get_connected_qubits(gate)) is not native on $(typeof(qpu))"
    @test_throws DomainError(qpu,msg) transpile_and_run_job(
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

    # submit circuit with qubit_count_circuit==qubit_count_qpu
    requestor=MockRequestor(request_checker,post_checker_last_qubit)
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)
    qpu=AnyonYukonQPU(test_client, status_request_throttle=no_throttle)

    qubit_count = get_num_qubits(qpu)
    circuit = QuantumCircuit(qubit_count = qubit_count, gates=[sigma_x(qubit_count)])

    transpile_and_run_job(qpu, circuit, shot_count) # no error thrown
    

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

