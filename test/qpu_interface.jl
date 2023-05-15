using Snowflake
using Test
using HTTP

include("mock_functions.jl")

requestor=MockRequestor(request_checker,post_checker)

function compare_responses(expected::HTTP.Response,received::HTTP.Response)

    for f in fieldnames(typeof(received))
        if isdefined(received,f) # response.request is undefined in Julia 1.6.7
            @test getfield(received,f)==getfield(expected,f)
        end
    end

end

@testset "requestor" begin
    struct NonImplementedRequestor<:Snowflake.Requestor end


    non_impl_requestor=NonImplementedRequestor()
    body=""
    
    @test_throws NotImplementedError get_request(non_impl_requestor,host,access_token,body) 
    @test_throws NotImplementedError post_request(non_impl_requestor,host,access_token,body) 
    
    #### request from :get_status
   
    @test_throws NotImplementedError get_request(
        requestor,
        "erroneous_url",
        access_token
    )

    expected_response=HTTP.Response(200, [], body="{\"status\":{\"type\":\"succeeded\"}}")

    circuitID="1234-abcd"

    response=get_request(
        requestor,
        host*"/"*Snowflake.path_circuits*"/"*circuitID,
        access_token
    )

    compare_responses(expected_response,response)

    @test_throws NotImplementedError get_request(
        requestor,
        host*"/"*string(Snowflake.path_circuits,"wrong_ending"),
        access_token
    )

    #### request from :get_result

    expected_response=HTTP.Response(200, [],body="{\"histogram\":{\"001\":\"100\"}}") 

    response=get_request(
        requestor,
        host*"/"*Snowflake.path_circuits*"/"*circuitID*"/"*Snowflake.path_results,
        access_token
    )

    compare_responses(expected_response,response)

    @test_throws NotImplementedError get_request(
        requestor,
        host*"/"*Snowflake.path_circuits*"/"*circuitID*"/"*string(Snowflake.path_results,"wrong_ending"),
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

    num_repetitions=100

    circuit_json=serialize_job(circuit,num_repetitions)

    expected_json="{\"num_repetitions\":100,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"
    
    @test circuit_json==expected_json
       
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)

    println(test_client) #coverage for Base.show(::IO,::Client)

    @test get_host(test_client)==host
    
    circuitID=submit_circuit(test_client,circuit,num_repetitions)

    status=get_status(test_client,circuitID)

    @test get_status_type(status) in ["queued","running","failed","succeeded"]
end

@testset "Construct AnyonQPU" begin
    host = "host"
    user = "user"
    token = "token"

    qpu = AnyonQPU(host=host, user=user, access_token=token)
    client = get_client(qpu)

    @test client.host == host
    @test client.user == user
    @test client.access_token == token

    print_connectivity(qpu)
end

@testset "run_job on AnyonQPU" begin

    requestor=MockRequestor(request_checker,post_checker)
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)
    num_repetitions=100
    qpu=AnyonQPU(test_client)
    println(qpu) #coverage for Base.show(::IO,::AnyonQPU)
    @test get_client(qpu)==test_client
    
    #test basic submission, no transpilation
    circuit = QuantumCircuit(qubit_count = 3,gates=[sigma_x(3),control_z(2,1)])
    histogram=run_job(qpu, circuit ,num_repetitions)
    @test histogram==Dict("001"=>num_repetitions)
    @test !haskey(histogram,"error_msg")

end

@testset "transpile_and_run_job on AnyonQPU" begin

    requestor=MockRequestor(request_checker,post_checker)
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)
    num_repetitions=100
    qpu=AnyonQPU(test_client)

    # submit circuit with qubit_count_circuit>qubit_count_qpu
    circuit = QuantumCircuit(qubit_count = 10)
    @test_throws DomainError transpile_and_run_job(qpu, circuit ,num_repetitions)

    # submit circuit with a non-native gate on this qpu (no transpilation)
    circuit = QuantumCircuit(qubit_count = 3, gates=[toffoli(1,2,3)])
    @test_throws DomainError transpile_and_run_job(
        qpu, 
        circuit,
        num_repetitions;
        transpiler=TrivialTranspiler()
    )

    # using AnyonQPU default transpiler
    requestor=MockRequestor(request_checker,post_checker_toffoli)
    test_client=Client(host=host,user=user,access_token=access_token,requestor=requestor)
    qpu=AnyonQPU(test_client)

    histogram=transpile_and_run_job(qpu, circuit ,num_repetitions)
    
    @test histogram==Dict("001"=>num_repetitions)
    @test !haskey(histogram,"error_msg")
end

@testset "run on VirtualQPU" begin

    circuit = QuantumCircuit(qubit_count = 3,gates=[sigma_x(3),control_z(2,1)])
        
    num_repetitions=100
    
    qpu=VirtualQPU()
    
    println(qpu) #coverage for Base.show(::IO,::VirtualQPU)

    for gate in get_circuit_gates(circuit)
        @test is_native_gate(qpu,gate)
    end
       
    histogram=transpile_and_run_job(qpu, circuit ,num_repetitions)
   
    @test histogram==Dict("001"=>num_repetitions)

end

@testset "AbstractQPU" begin
    struct NonExistentQPU<:Snowflake.AbstractQPU end

    @test_throws NotImplementedError get_metadata(NonExistentQPU())
    @test_throws NotImplementedError is_native_gate(NonExistentQPU(),sigma_x(1))
    @test_throws NotImplementedError is_native_circuit(NonExistentQPU(),QuantumCircuit(qubit_count=1))
    @test_throws NotImplementedError get_transpiler(NonExistentQPU())  

end
