using Snowflurry
using Test
using HTTP

include("mock_functions.jl")

requestor = MockRequestor(request_checker, make_post_checker(expected_json))

# While testing, this throttle can be used to skip delays between status requests.
no_throttle = () -> Snowflurry.default_status_request_throttle(0)

function compare_responses(expected::HTTP.Response, received::HTTP.Response)

    for f in fieldnames(typeof(received))
        if isdefined(received, f) # response.request is undefined in Julia 1.6.7
            if getfield(received, f) != getfield(expected, f)
                receivedStr = read_response_body(getfield(received, f))
                expectedStr = read_response_body(getfield(expected, f))
                @test receivedStr == expectedStr
            end
        end
    end

end

@testset "requestor" begin
    struct NonImplementedRequestor <: Snowflurry.Requestor end

    non_impl_requestor = NonImplementedRequestor()
    body = ""

    @test_throws NotImplementedError get_request(
        non_impl_requestor,
        host,
        user,
        expected_access_token,
    )
    @test_throws NotImplementedError post_request(
        non_impl_requestor,
        host,
        user,
        expected_access_token,
        body,
    )

    #### request from :get_status

    @test_throws NotImplementedError get_request(
        requestor,
        "erroneous_url",
        user,
        expected_access_token,
    )

    expected_response = HTTP.Response(200, [], body = expected_get_status_response_body)

    jobID = "1234-abcd"

    response = get_request(
        requestor,
        host * "/" * Snowflurry.path_jobs * "/" * jobID,
        user,
        expected_access_token,
    )

    compare_responses(expected_response, response)

    @test_throws NotImplementedError get_request(
        requestor,
        host * "/" * string(Snowflurry.path_jobs, "wrong_ending"),
        user,
        expected_access_token,
    )

    #### request from :get_result

    expected_response = HTTP.Response(200, [], body = "{\"histogram\":{\"001\":100}}")

    response = get_request(
        requestor,
        host * "/" * Snowflurry.path_jobs * "/" * jobID * "/" * Snowflurry.path_results,
        user,
        expected_access_token,
    )

    compare_responses(expected_response, response)

    @test_throws NotImplementedError get_request(
        requestor,
        host *
        "/" *
        Snowflurry.path_jobs *
        "/" *
        jobID *
        "/" *
        string(Snowflurry.path_results, "wrong_ending"),
        user,
        expected_access_token,
    )

end

@testset "read_response_body" begin
    my_string = "abcdefghijlkmnopqrstuvwxyz"

    body = UInt8.([c for c in my_string])

    @test read_response_body(body) == my_string

    body[10] = 0x00

    @test_throws ArgumentError read_response_body(body)

    body = codeunits(my_string)

    @test read_response_body(body) == my_string

end

@testset "Status" begin
    type = "failed"
    message = "Server error"

    status = Status(type = type, message = message)

    @test type == get_status_type(status)
    @test message == get_status_message(status)

    println(status)

    ###

    type = "succeeded"

    status = Status(type = type)

    @test type == get_status_type(status)

    println(status)
end


@testset "basic submission" begin

    circuit = QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1)])

    shot_count = 100

    circuit_json = serialize_job(circuit, shot_count, "http://test.anyonsys.com")

    expected_json = "{\"name\":\"default\",\"machine_id\":\"http://test.anyonsys.com\",\"shot_count\":100,\"type\":\"circuit\",\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"

    @test circuit_json == expected_json

    test_client = Client(
        host = host,
        user = user,
        access_token = expected_access_token,
        requestor = requestor,
    )

    println(test_client) #coverage for Base.show(::IO,::Client)

    @test get_host(test_client) == host

    jobID = submit_job(test_client, circuit, shot_count)

    status, histogram = get_status(test_client, jobID)

    @test get_status_type(status) in [
        Snowflurry.queued_status,
        Snowflurry.running_status,
        Snowflurry.failed_status,
        Snowflurry.succeeded_status,
    ]
end

@testset "job status" begin
    # We don't expect a POST during this test. Returning nothing should cause a
    # failure if a POST is attempted
    test_post = () -> Nothing

    test_get = stub_response_sequence([
        # Simulate a response for a failed job.
        stubFailedStatusResponse(),
    ])
    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(
        host = host,
        user = user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    status, histogram = get_status(test_client, "jobID not used in this test")
    @test get_status_type(status) == Snowflurry.failed_status
    @test get_status_message(status) == "mocked"

    test_get = stub_response_sequence([
        # Simulate a response containing an invalid job status.
        stubStatusResponse("not a valid status"),
    ])

    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(
        host = host,
        user = user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    @test_throws ArgumentError get_status(test_client, "jobID not used in this test")

    malformedResponse = stubFailedStatusResponse()
    # A failure response _should_ have a 'message' field but, if things go very
    # wrong, the user should still get something useful.
    body = "{\"status\":{\"type\":\"FAILED\"},\"these aren't the droids you're looking for\":\"*waves-hand*\"}"
    malformedResponse.body = collect(UInt8, body)
    test_get = stub_response_sequence([malformedResponse])
    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(
        host = host,
        user = user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    status, histogram = get_status(test_client, "jobID not used in this test")
    @test status.type == Snowflurry.failed_status
    @test status.message != ""
end


function test_print_connectivity(input::Snowflurry.UnionAnyonQPU, expected::String)
    io = IOBuffer()
    print_connectivity(input, io)
    @test String(take!(io)) == expected
end

function test_print_connectivity(input::AbstractConnectivity, expected::String)
    io = IOBuffer()
    print_connectivity(input, Int[], io)
    @test String(take!(io)) == expected

end

@testset "AbstractConnectivity" begin

    connectivity = LineConnectivity(12)

    test_print_connectivity(connectivity, "1──2──3──4──5──6──7──8──9──10──11──12\n")

    io = IOBuffer()
    println(io, connectivity)
    @test String(take!(io)) ==
          "LineConnectivity{12}\n1──2──3──4──5──6──7──8──9──10──11──12\n\n"

    @test path_search(1, 12, connectivity) == reverse(collect(1:12))
    @test path_search(7, 4, connectivity) == collect(4:7)
    @test path_search(1, 1, connectivity) == [1]

    @test_throws AssertionError path_search(1, 44, connectivity)
    @test_throws AssertionError path_search(44, 1, connectivity)
    @test_throws AssertionError path_search(-1, 4, connectivity)
    @test_throws AssertionError path_search(4, -1, connectivity)

    test_print_connectivity(
        LatticeConnectivity(4, 5),
        "        1 ──  2 \n" *
        "        |     | \n" *
        "  3 ──  4 ──  5 ──  6 \n" *
        "        |     |     | \n" *
        "        7 ──  8 ──  9 ── 10 \n" *
        "              |     |     | \n" *
        "             11 ── 12 ── 13 ── 14 \n" *
        "                    |     |     | \n" *
        "                   15 ── 16 ── 17 ── 18 \n" *
        "                          |     | \n" *
        "                         19 ── 20 \n" *
        "\n",
    )

    io = IOBuffer()
    connectivity = LatticeConnectivity(6, 4)
    print_connectivity(connectivity, path_search(3, 22, connectivity), io)

    @test String(take!(io)) ==
          "              1 ──  2 \n" *
          "              |     | \n" *
          "       (3)──  4 ──  5 ──  6 \n" *
          "        |     |     |     | \n" *
          "  7 ── (8)──  9 ── 10 ── 11 ── 12 \n" *
          "        |     |     |     |     | \n" *
          "      (13)──(14)── 15 ── 16 ── 17 ── 18 \n" *
          "              |     |     |     | \n" *
          "            (19)──(20)──(21)──(22)\n" *
          "                    |     | \n" *
          "                   23 ── 24 \n\n"

    io = IOBuffer()
    println(io, connectivity)
    @test String(take!(io)) ==
          "LatticeConnectivity{6,4}\n" *
          "              1 ──  2 \n" *
          "              |     | \n" *
          "        3 ──  4 ──  5 ──  6 \n" *
          "        |     |     |     | \n" *
          "  7 ──  8 ──  9 ── 10 ── 11 ── 12 \n" *
          "        |     |     |     |     | \n" *
          "       13 ── 14 ── 15 ── 16 ── 17 ── 18 \n" *
          "              |     |     |     | \n" *
          "             19 ── 20 ── 21 ── 22 \n" *
          "                    |     | \n" *
          "                   23 ── 24 \n\n\n"


    @test path_search(1, 24, connectivity) == [24, 23, 20, 19, 14, 9, 4, 1]
    @test path_search(1, 1, connectivity) == [1]

    @test_throws AssertionError path_search(1, 44, connectivity)
    @test_throws AssertionError path_search(44, 1, connectivity)
    @test_throws AssertionError path_search(-1, 4, connectivity)
    @test_throws AssertionError path_search(4, -1, connectivity)

    struct UnknownConnectivity <: AbstractConnectivity end
    @test_throws NotImplementedError print_connectivity(UnknownConnectivity())
    @test_throws NotImplementedError get_connectivity_label(UnknownConnectivity())
    @test_throws NotImplementedError path_search(1, 1, UnknownConnectivity())

    # Customized Lattice specifying qubits_per_row
    connectivity = LatticeConnectivity([1, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3, 1])

    # path_search works on arbitrary lattice shape
    io = IOBuffer()
    print_connectivity(connectivity, path_search(5, 48, connectivity), io)
    @test String(take!(io)) ==
          "        1 \n" *
          "        | \n" *
          "  2 ──  3 ──  4 \n" *
          "  |     |     | \n" *
          " (5)──  6 ──  7 ──  8 \n" *
          "  |     |     |     | \n" *
          " (9)── 10 ── 11 ── 12 ── 13 \n" *
          "  |     |     |     |     | \n" *
          "(14)── 15 ── 16 ── 17 ── 18 ── 19 \n" *
          "  |     |     |     |     |     | \n" *
          "(20)──(21)── 22 ── 23 ── 24 ── 25 ── 26 \n" *
          "        |     |     |     |     |     | \n" *
          "      (27)──(28)── 29 ── 30 ── 31 ── 32 ── 33 \n" *
          "              |     |     |     |     |     | \n" *
          "            (34)──(35)── 36 ── 37 ── 38 ── 39 \n" *
          "                    |     |     |     |     | \n" *
          "                  (40)──(41)── 42 ── 43 ── 44 \n" *
          "                          |     |     |     | \n" *
          "                        (45)──(46)──(47)──(48)\n" *
          "                                |     |     | \n" *
          "                               49 ── 50 ── 51 \n" *
          "                                      | \n" *
          "                                     52 \n\n"



end

@testset "get_qubits_distance" begin
    # LineConnectivity
    qubit_count_list = [6, 12]
    for qubit_count in qubit_count_list
        connectivity = LineConnectivity(qubit_count)

        for target_1 = 1:qubit_count
            for target_2 = 1:qubit_count
                @test get_qubits_distance(target_1, target_2, connectivity) ==
                      abs(target_1 - target_2)
            end
        end
    end

    ##########################################
    # LatticeConnectivity
    nrows_list = [4, 6, 5]
    ncols_list = [3, 4, 5]

    for (nrows, ncols) in zip(nrows_list, ncols_list)

        connectivity = LatticeConnectivity(nrows, ncols)

        (offsets, _, _) = Snowflurry.get_lattice_offsets(connectivity)

        qubits_per_row = connectivity.qubits_per_row

        ncols = 0
        for (qubit_count, offset) in zip(qubits_per_row, offsets)
            ncols = maximum([ncols, qubit_count + offset])
        end

        nrows = length(qubits_per_row)
        qubit_placement = zeros(Int, nrows, ncols)
        qubit_count = get_num_qubits(connectivity)

        placed_qubits = 0

        for (irow, qubit_count) in enumerate(qubits_per_row)
            offset = offsets[irow]
            qubit_placement[irow, 1+offset:qubit_count+offset] =
                [v + placed_qubits for v in (1:qubit_count)]

            placed_qubits += qubit_count
        end

        qubit_coordinates = Dict{Int,CartesianIndex{2}}()

        for (origin, ind) in zip(qubit_placement, CartesianIndices(qubit_placement))
            if origin != 0
                qubit_coordinates[origin] = ind

            end
        end

        for (target_1, ind_1) in qubit_coordinates
            for (target_2, ind_2) in qubit_coordinates

                target_1_row = ind_1[1]
                target_1_col = ind_1[2]

                target_2_row = ind_2[1]
                target_2_col = ind_2[2]

                @test get_qubits_distance(target_1, target_2, connectivity) ==
                      abs(target_1_row - target_2_row) + abs(target_1_col - target_2_col)
            end
        end
    end
end

@testset "Construct AnyonYukonQPU" begin
    host = "host"
    user = "user"
    token = "token"
    project = "project-id"

    qpu = AnyonYukonQPU(
        host = host,
        user = user,
        access_token = token,
        status_request_throttle = no_throttle,
        project_id = project,
    )
    client = get_client(qpu)

    connectivity = get_connectivity(qpu)

    @test client.host == host
    @test client.user == user
    @test client.access_token == token

    test_print_connectivity(qpu, "1──2──3──4──5──6\n")

    @test get_connectivity_label(get_connectivity(qpu)) ==
          Snowflurry.line_connectivity_label

    @test get_metadata(qpu) == Dict{String,Union{String,Int}}(
        "manufacturer" => "Anyon Systems Inc.",
        "generation" => "Yukon",
        "serial_number" => "ANYK202201",
        "project_id" => get_project_id(qpu),
        "qubit_count" => get_num_qubits(connectivity),
        "connectivity_type" => get_connectivity_label(connectivity),
    )
end

@testset "Construct AnyonYamaskaQPU" begin
    host = "host"
    user = "user"
    token = "token"
    project = "project-id"

    qpu = AnyonYamaskaQPU(
        host = host,
        user = user,
        access_token = token,
        status_request_throttle = no_throttle,
        project_id = project,
    )
    client = get_client(qpu)

    connectivity = get_connectivity(qpu)

    @test client.host == host
    @test client.user == user
    @test client.access_token == token

    test_print_connectivity(
        qpu,
        "        1 ──  2 \n" *
        "        |     | \n" *
        "  3 ──  4 ──  5 ──  6 \n" *
        "        |     |     | \n" *
        "        7 ──  8 ──  9 ── 10 \n" *
        "              |     | \n" *
        "             11 ── 12 \n" *
        "\n",
    )

    @test get_connectivity_label(connectivity) == Snowflurry.lattice_connectivity_label

    @test get_metadata(qpu) == Dict{String,Union{String,Int}}(
        "manufacturer" => "Anyon Systems Inc.",
        "generation" => "Yamaska",
        "serial_number" => "ANYK202301",
        "project_id" => get_project_id(qpu),
        "qubit_count" => get_num_qubits(connectivity),
        "connectivity_type" => get_connectivity_label(connectivity),
    )

end

@testset "run_job on AnyonYukonQPU" begin

    requestor = MockRequestor(request_checker, make_post_checker(expected_json))
    test_client = Client(
        host = host,
        user = user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    shot_count = 100
    qpu = AnyonYukonQPU(test_client, status_request_throttle = no_throttle)
    println(qpu) #coverage for Base.show(::IO,::AnyonYukonQPU)
    @test get_client(qpu) == test_client

    #test basic submission, no transpilation
    circuit = QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), control_z(2, 1)])
    histogram = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")

    #verify that run_job blocks until a 'long-running' job completes
    requestor = MockRequestor(
        stub_response_sequence([
            stubStatusResponse(Snowflurry.queued_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.succeeded_status),
            stubResult(),
        ]),
        make_post_checker(expected_json),
    )
    qpu = AnyonYukonQPU(
        Client(host, user, expected_access_token, requestor),
        status_request_throttle = no_throttle,
    )
    histogram = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")

    #verify that run_job throws an error if the QPU returns an error
    requestor = MockRequestor(
        stub_response_sequence([
            stubStatusResponse(Snowflurry.queued_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.running_status),
            stubFailedStatusResponse(),
            stubFailureResult(),
        ]),
        make_post_checker(expected_json),
    )
    qpu = AnyonYukonQPU(
        Client(host, user, expected_access_token, requestor),
        status_request_throttle = no_throttle,
    )
    @test_throws ErrorException histogram = run_job(qpu, circuit, shot_count)

    #verify that run_job throws an error if the job was cancelled
    requestor = MockRequestor(
        stub_response_sequence([
            stubStatusResponse(Snowflurry.queued_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.cancelled_status),
            stubCancelledResultResponse(),
        ]),
        make_post_checker(expected_json),
    )
    qpu = AnyonYukonQPU(
        Client(host, user, expected_access_token, requestor),
        status_request_throttle = no_throttle,
    )
    @test_throws ErrorException histogram = run_job(qpu, circuit, shot_count)
end

@testset "run_job with Readout on AnyonYukonQPU" begin

    requestor = MockRequestor(request_checker, make_post_checker(expected_json_readout))
    test_client = Client(
        host = host,
        user = user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    shot_count = 100
    qpu = AnyonYukonQPU(test_client, status_request_throttle = no_throttle)

    circuit = QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3), readout(3, 3)])
    histogram = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")
end


@testset "run_job on AnyonYukonQPU with project_id" begin

    requestor =
        MockRequestor(request_checker, make_post_checker(expected_json_with_project_id))
    test_client = Client(
        host = host,
        user = user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    shot_count = 100
    project_id = "test_project_id"
    qpu = AnyonYukonQPU(
        test_client,
        status_request_throttle = no_throttle,
        project_id = project_id,
    )

    #test basic submission, no transpilation
    circuit = QuantumCircuit(qubit_count = 3, instructions = [sigma_x(3)])
    histogram = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")

end

@testset "transpile_and_run_job on AnyonYukonQPU and AnyonYamaskaQPU" begin

    qpus = [AnyonYukonQPU, AnyonYamaskaQPU]
    post_checkers_toffoli = [
        make_post_checker(expected_json_Toffoli_Yukon),
        make_post_checker(expected_json_Toffoli_Yamaska),
    ]
    post_checkers_last_qubit = [
        make_post_checker(expected_json_last_qubit_Yukon),
        make_post_checker(expected_json_last_qubit_Yamaska),
    ]

    for (QPU, post_checker_toffoli, post_checker_last_qubit) in
        zip(qpus, post_checkers_toffoli, post_checkers_last_qubit)

        requestor = MockRequestor(request_checker, make_post_checker(expected_json))
        test_client = Client(
            host = host,
            user = user,
            access_token = expected_access_token,
            requestor = requestor,
        )
        shot_count = 100

        qpu = QPU(test_client, status_request_throttle = no_throttle)

        # submit circuit with qubit_count_circuit>qubit_count_qpu
        circuit = QuantumCircuit(
            qubit_count = get_num_qubits(qpu) + 1,
            instructions = [readout(1, 1)],
        )
        @test_throws DomainError transpile_and_run_job(qpu, circuit, shot_count)

        # submit circuit with a non-native gate on this qpu (no transpilation)
        circuit = QuantumCircuit(
            qubit_count = get_num_qubits(qpu) - 1,
            instructions = [toffoli(1, 2, 3), readout(1, 1)],
        )
        @test_throws DomainError transpile_and_run_job(
            qpu,
            circuit,
            shot_count;
            transpiler = TrivialTranspiler(),
        )

        # using default transpiler
        requestor = MockRequestor(request_checker, post_checker_toffoli)
        test_client = Client(
            host = host,
            user = user,
            access_token = expected_access_token,
            requestor = requestor,
        )

        qpu = QPU(test_client, status_request_throttle = no_throttle)

        histogram = transpile_and_run_job(qpu, circuit, shot_count)

        @test histogram == Dict("001" => shot_count)
        @test !haskey(histogram, "error_msg")

        # submit circuit with qubit_count_circuit==qubit_count_qpu
        requestor = MockRequestor(request_checker, post_checker_last_qubit)
        test_client = Client(
            host = host,
            user = user,
            access_token = expected_access_token,
            requestor = requestor,
        )
        qpu = QPU(test_client, status_request_throttle = no_throttle)

        qubit_count = get_num_qubits(qpu)
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = [sigma_x(qubit_count), readout(1, 1)],
        )

        transpile_and_run_job(qpu, circuit, shot_count) # no error thrown
    end
end

@testset "run on VirtualQPU" begin

    circuit = QuantumCircuit(
        qubit_count = 3,
        instructions = [
            sigma_x(3),
            control_z(2, 1),
            readout(1, 1),
            readout(2, 2),
            readout(3, 3),
        ],
    )

    shot_count = 100

    qpu = VirtualQPU()

    println(qpu) #coverage for Base.show(::IO,::VirtualQPU)

    for instr in get_circuit_instructions(circuit)
        @test is_native_instruction(qpu, instr)
    end

    histogram = transpile_and_run_job(qpu, circuit, shot_count)

    @test histogram == Dict("001" => shot_count)

    connectivity = get_connectivity(qpu)

    @test connectivity isa AllToAllConnectivity
    @test get_connectivity_label(connectivity) == Snowflurry.all2all_connectivity_label
    test_print_connectivity(connectivity, "AllToAllConnectivity()\n")
end

@testset "run on VirtualQPU: partial readouts" begin

    circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [hadamard(1), control_x(1, 2), control_x(2, 3), readout(3, 1)],
    )

    shot_count = 100

    qpu = VirtualQPU()

    histogram = transpile_and_run_job(qpu, circuit, shot_count)

    @test haskey(histogram, "0")
    @test haskey(histogram, "1")

    pop!(histogram, "0")
    pop!(histogram, "1")

    @test length(histogram) == 0

    circuit = QuantumCircuit(
        qubit_count = 6,
        instructions = [
            hadamard(1),
            control_x(1, 2),
            control_x(2, 3),
            control_x(3, 4),
            control_x(4, 5),
            control_x(5, 6),
            readout(1, 1),
            readout(6, 2),
        ],
    )

    histogram = transpile_and_run_job(qpu, circuit, shot_count)

    @test haskey(histogram, "00")
    @test haskey(histogram, "11")

    pop!(histogram, "00")
    pop!(histogram, "11")

    @test length(histogram) == 0
end

@testset "run on VirtualQPU: ensure state representation convention" begin

    shot_count = 100

    for qubit = 1:6
        circuit = QuantumCircuit(
            qubit_count = qubit,
            instructions = [sigma_x(qubit), readout(qubit, 1)],
        )

        qpu = VirtualQPU()

        histogram = transpile_and_run_job(qpu, circuit, shot_count)

        @test haskey(histogram, "1")
        pop!(histogram, "1")
        @test length(histogram) == 0
    end
end

@testset "AbstractQPU" begin
    struct NonExistentQPU <: Snowflurry.AbstractQPU end

    @test_throws NotImplementedError get_metadata(NonExistentQPU())
    @test_throws NotImplementedError get_connectivity(NonExistentQPU())
    @test_throws NotImplementedError is_native_instruction(NonExistentQPU(), sigma_x(1))
    @test_throws NotImplementedError is_native_circuit(
        NonExistentQPU(),
        QuantumCircuit(qubit_count = 1),
    )
    @test_throws NotImplementedError get_transpiler(NonExistentQPU())
    @test_throws NotImplementedError run_job(
        NonExistentQPU(),
        QuantumCircuit(qubit_count = 1),
        42,
    )
end
