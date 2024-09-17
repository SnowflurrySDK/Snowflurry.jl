using Snowflurry
using Test
using HTTP

include("mock_functions.jl")

generic_requestor = MockRequestor(
    make_request_checker(expected_realm),
    make_post_checker(expected_json_generic, expected_realm),
)

no_realm_requestor_generic =
    MockRequestor(make_request_checker(""), make_post_checker(expected_json_generic))

yukon_requestor_with_empty_realm = MockRequestor(
    stub_request_checker_sequence([
        function (args...; kwargs...)
            return stubMetadataResponse(yukonMetadata)
        end,
        make_request_checker(""),
    ]),
    make_post_checker(expected_json_yukon),
)

yukon_requestor = MockRequestor(
    make_request_checker(expected_realm),
    make_post_checker(expected_json_yukon, expected_realm),
)

yamaska_requestor = MockRequestor(
    make_request_checker(expected_realm),
    make_post_checker(
        make_expected_json(Snowflurry.AnyonYamaskaMachineName),
        expected_realm,
    ),
)

yamaska_requestor_with_empty_realm = MockRequestor(
    stub_request_checker_sequence([
        function (args...; kwargs...)
            return stubMetadataResponse(yamaskaMetadata)
        end,
        make_request_checker(""),
    ]),
    make_post_checker(expected_json_yamaska),
)

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

@testset "requestor: NotImplementedErrors" begin
    struct NonImplementedRequestor <: Snowflurry.Requestor end

    non_impl_requestor = NonImplementedRequestor()
    body = ""

    @test_throws NotImplementedError get_request(
        non_impl_requestor,
        expected_host,
        expected_user,
        expected_access_token,
        expected_realm,
    )
    @test_throws NotImplementedError post_request(
        non_impl_requestor,
        expected_host,
        expected_user,
        expected_access_token,
        body,
        expected_realm,
    )

end

@testset "requestor: MockRequestor" begin
    #ensure MockRequestor behaves as expected

    expected_response = HTTP.Response(200, [], body = expected_get_status_response_body)

    jobID = "1234-abcd"

    response = get_request(
        yukon_requestor,
        expected_host * "/" * Snowflurry.path_jobs * "/" * jobID,
        expected_user,
        expected_access_token,
        expected_realm,
    )

    compare_responses(expected_response, response)

    @test_throws AssertionError("received: \nwrong-user, expected: \n$expected_user") get_request(
        yukon_requestor,
        expected_host * "/" * Snowflurry.path_jobs * "/" * jobID,
        "wrong-user",
        expected_access_token,
        expected_realm,
    )

    @test_throws AssertionError(
        "received: \nwrong-access-token, expected: \n$expected_access_token",
    ) get_request(
        yukon_requestor,
        expected_host * "/" * Snowflurry.path_jobs * "/" * jobID,
        expected_user,
        "wrong-access-token",
        expected_realm,
    )

    @test_throws AssertionError("received: \nwrong-realm, expected: \n$expected_realm") get_request(
        yukon_requestor,
        expected_host * "/" * Snowflurry.path_jobs * "/" * jobID,
        expected_user,
        expected_access_token,
        "wrong-realm",
    )

end

@testset "read_response_body" begin
    my_string = "abcdefghijlkmnopqrstuvwxyz"

    body = UInt8.([c for c in my_string])

    @test read_response_body(body) == my_string

    # misplaced null terminator does not crash reader
    body[10] = 0x00
    my_string = "abcdefghi\0lkmnopqrstuvwxyz"
    @test read_response_body(body) == my_string

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

    circuit = QuantumCircuit(
        qubit_count = 3,
        instructions = [sigma_x(3), control_z(2, 1), readout(1, 1)],
    )

    shot_count = 100

    circuit_json =
        serialize_job(circuit, shot_count, expected_machine_name, expected_project_id)

    job_str = make_job_str(expected_machine_name)
    @test circuit_json ==
          job_str[1:length(job_str)-1] *
          ",\"circuit\":{\"operations\":" *
          expected_operations_substr

    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = generic_requestor,
        realm = expected_realm,
    )

    println(test_client) #coverage for Base.show(::IO,::Client)

    @test get_host(test_client) == expected_host

    jobID = submit_job(
        test_client,
        circuit,
        shot_count,
        expected_project_id,
        expected_machine_name,
    )

    status, histogram, qpu_time = get_status(test_client, jobID)

    @test get_status_type(status) in [
        Snowflurry.queued_status,
        Snowflurry.running_status,
        Snowflurry.failed_status,
        Snowflurry.succeeded_status,
    ]
end

@testset "serialize_job: empty project_id should not throw error" begin

    circuit = QuantumCircuit(qubit_count = 1)

    shot_count = 100

    serialize_job(circuit, shot_count, Snowflurry.AnyonYukonMachineName, "")
end

@testset "serialize_job: non-default bit_count" begin

    circuit = QuantumCircuit(
        qubit_count = 3,
        bit_count = 7,
        instructions = [sigma_x(3), control_z(2, 1), readout(1, 1)],
    )

    shot_count = 100

    circuit_json = serialize_job(
        circuit,
        shot_count,
        Snowflurry.AnyonYukonMachineName,
        expected_project_id,
    )

    @test circuit_json == expected_json_non_default_bit_count
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
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    status, histogram, qpu_time = get_status(test_client, "jobID not used in this test")
    @test get_status_type(status) == Snowflurry.failed_status
    @test get_status_message(status) == "mocked"
    @test qpu_time == 0

    test_get = stub_response_sequence([
        # Simulate a response containing an invalid job status.
        stubStatusResponse("not a valid status"),
    ])

    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    @test_throws ArgumentError get_status(test_client, "jobID not used in this test")

    malformedResponse = stubFailedStatusResponse()
    # A failure response _should_ have a 'message' field but, if things go very
    # wrong, the user should still get something useful.
    body = "{\"job\":{\"status\":{\"type\":\"FAILED\"}},\"these aren't the droids you're looking for\":\"*waves-hand*\"}"
    malformedResponse.body = collect(UInt8, body)
    test_get = stub_response_sequence([malformedResponse])
    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    status, histogram, qpu_time = get_status(test_client, "jobID not used in this test")
    @test status.type == Snowflurry.failed_status
    @test status.message != ""
    @test qpu_time == 0

    test_get = stub_response_sequence([
        # Simulate a response with an invalid qpuTimeMilliSeconds.
        HTTP.Response(
            200,
            [],
            body = "{\"job\":{\"status\":{\"type\":\"$(Snowflurry.succeeded_status)\"},\"qpuTimeMilliSeconds\":\"not-an-integer\"},\"result\":{\"histogram\":{}}}",
        ),
    ])
    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    @test_throws AssertionError(
        "Invalid server response: \"qpuTimeMilliSeconds\" value: not-an-integer is not an integer",
    ) get_status(test_client, "jobID not used in this test")

    test_get = stub_response_sequence([
        # Simulate a response with 0 qpuTimeMilliSeconds.
        HTTP.Response(
            200,
            [],
            body = "{\"job\":{\"status\":{\"type\":\"$(Snowflurry.succeeded_status)\"},\"qpuTimeMilliSeconds\":0},\"result\":{\"histogram\":{}}}",
        ),
    ])
    requestor = HTTPRequestor(test_get, test_post)
    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = requestor,
    )
    @test_throws AssertionError(
        "Invalid server response: \"qpuTimeMilliSeconds\" value: 0 is not a positive integer",
    ) get_status(test_client, "jobID not used in this test")
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

    expected_adjacency_list = Dict{Int,Vector{Int}}(
        1 => [2],
        2 => [1, 3],
        3 => [2, 4],
        4 => [3, 5],
        5 => [4, 6],
        6 => [5, 7],
        8 => [7, 9],
        7 => [6, 8],
        9 => [8, 10],
        10 => [9, 11],
        11 => [10, 12],
        12 => [11],
    )

    @test get_adjacency_list(connectivity) == expected_adjacency_list

    io = IOBuffer()
    println(io, connectivity)
    @test String(take!(io)) ==
          "LineConnectivity{12}\n1──2──3──4──5──6──7──8──9──10──11──12\n\n"

    @test path_search(1, 12, connectivity) == Vector{Int}(reverse(collect(1:12)))
    @test path_search(7, 4, connectivity) == Vector{Int}(collect(4:7))
    @test path_search(1, 1, connectivity) == [1]

    exclusion_cases = [[2], [2, 6], [1], [12]]
    for excluded in exclusion_cases
        @test path_search(1, 12, connectivity, excluded) == []
    end

    @test path_search(12, 11, connectivity, [2]) == Vector{Int}(collect(11:12))

    @test_throws AssertionError path_search(1, 44, connectivity)
    @test_throws AssertionError path_search(44, 1, connectivity)
    @test_throws AssertionError path_search(-1, 4, connectivity)
    @test_throws AssertionError path_search(4, -1, connectivity)
    @test_throws AssertionError path_search(1, 12, connectivity, [-1])

    test_print_connectivity(
        LatticeConnectivity(4, 5),
        "        1 \n" *
        "        | \n" *
        " 11 ──  6 ──  2 \n" *
        "  |     |     | \n" *
        " 16 ── 12 ──  7 ──  3 \n" *
        "        |     |     | \n" *
        "       17 ── 13 ──  8 ──  4 \n" *
        "              |     |     | \n" *
        "             18 ── 14 ──  9 ──  5 \n" *
        "                    |     |     | \n" *
        "                   19 ── 15 ── 10 \n" *
        "                          | \n" *
        "                         20 \n" *
        "\n",
    )

    io = IOBuffer()
    connectivity = LatticeConnectivity(6, 4)
    expected_adjacency_list = Dict{Int,Vector{Int}}(
        5 => [1, 10, 9, 2],
        16 => [12, 20],
        20 => [15, 24, 23, 16],
        12 => [7, 16, 15, 8],
        24 => [20],
        8 => [4, 12],
        17 => [21, 13],
        1 => [5],
        19 => [14, 23, 22, 15],
        22 => [18, 19],
        23 => [19, 20],
        6 => [2, 11, 10, 3],
        11 => [6, 15, 14, 7],
        9 => [13, 5],
        14 => [10, 19, 18, 11],
        3 => [7, 6],
        7 => [3, 12, 11, 4],
        13 => [9, 18, 17, 10],
        15 => [11, 20, 19, 12],
        21 => [17, 18],
        2 => [6, 5],
        10 => [5, 14, 13, 6],
        18 => [13, 22, 21, 14],
        4 => [8, 7],
    )

    @test expected_adjacency_list == get_adjacency_list(connectivity)

    print_connectivity(connectivity, path_search(3, 22, connectivity), io)

    @test String(take!(io)) ==
          "              1 \n" *
          "              | \n" *
          "        9 ──  5 ──  2 \n" *
          "        |     |     | \n" *
          " 17 ── 13 ── 10 ──  6 ── (3)\n" *
          "  |     |     |     |     | \n" *
          " 21 ── 18 ── 14 ── 11 ── (7)──  4 \n" *
          "        |     |     |     |     | \n" *
          "      (22)──(19)──(15)──(12)──  8 \n" *
          "              |     |     | \n" *
          "             23 ── 20 ── 16 \n" *
          "                    | \n" *
          "                   24 \n" *
          "\n"

    io = IOBuffer()
    println(io, connectivity)
    @test String(take!(io)) ==
          "LatticeConnectivity{6,4}\n" *
          "              1 \n" *
          "              | \n" *
          "        9 ──  5 ──  2 \n" *
          "        |     |     | \n" *
          " 17 ── 13 ── 10 ──  6 ──  3 \n" *
          "  |     |     |     |     | \n" *
          " 21 ── 18 ── 14 ── 11 ──  7 ──  4 \n" *
          "        |     |     |     |     | \n" *
          "       22 ── 19 ── 15 ── 12 ──  8 \n" *
          "              |     |     | \n" *
          "             23 ── 20 ── 16 \n" *
          "                    | \n" *
          "                   24 \n" *
          "\n\n"


    @test path_search(1, 24, connectivity) == [24, 20, 23, 19, 14, 10, 5, 1]
    excluded = [10]
    @test path_search(1, 24, connectivity, excluded) == [24, 20, 15, 11, 6, 2, 5, 1]
    @test path_search(1, 1, connectivity) == [1]

    @test path_search(1, 9, connectivity, [5, 6]) == []
    @test path_search(24, 1, connectivity, [20]) == []
    @test path_search(1, 3, connectivity, [1]) == []
    @test path_search(1, 3, connectivity, [3]) == []

    @test_throws AssertionError path_search(1, 44, connectivity)
    @test_throws AssertionError path_search(44, 1, connectivity)
    @test_throws AssertionError path_search(-1, 4, connectivity)
    @test_throws AssertionError path_search(4, -1, connectivity)
    @test_throws AssertionError path_search(1, 3, connectivity, [-1])

    struct UnknownConnectivity <: AbstractConnectivity end
    @test_throws NotImplementedError print_connectivity(UnknownConnectivity())
    @test_throws NotImplementedError get_connectivity_label(UnknownConnectivity())
    @test_throws NotImplementedError path_search(1, 1, UnknownConnectivity())
    @test_throws NotImplementedError get_adjacency_list(UnknownConnectivity())

end


@testset "AbstractConnectivity: excluded positions and connections" begin

    excluded_positions = [1, 2, 3, 9, 10]
    excluded_connections = [(2, 3), (5, 4), (5, 6)]

    connectivity = LineConnectivity(12, excluded_positions, excluded_connections)

    @test get_excluded_positions(connectivity) == excluded_positions
    @test get_excluded_connections(connectivity) == [(2, 3), (4, 5), (5, 6)]

    alternate_positions = Snowflurry.with_excluded_positions(
        LineConnectivity(12, [1], excluded_connections),
        excluded_positions,
    )

    @test connectivity.dimension == alternate_positions.dimension
    @test connectivity.excluded_positions == alternate_positions.excluded_positions
    @test connectivity.excluded_connections == alternate_positions.excluded_connections

    alternate_connection = Snowflurry.with_excluded_connections(
        LineConnectivity(12, excluded_positions),
        excluded_connections,
    )

    @test connectivity.dimension == alternate_connection.dimension
    @test connectivity.excluded_positions == alternate_connection.excluded_positions
    @test connectivity.excluded_connections == alternate_connection.excluded_connections

    expected_adjacency_list = Dict{Int,Vector{Int}}(
        4 => [],
        5 => [],
        6 => [7],
        7 => [6, 8],
        8 => [7],
        11 => [12],
        12 => [11],
    )

    @test get_adjacency_list(connectivity) == expected_adjacency_list

    io = IOBuffer()
    println(io, connectivity)
    @test String(take!(io)) ==
          "LineConnectivity{12}\n" *
          "1──2──3──4──5──6──7──8──9──10──11──12\n" *
          "excluded positions: [1, 2, 3, 9, 10]\n" *
          "excluded connections: [(2, 3), (4, 5), (5, 6)]\n" *
          "\n"

    @test path_search(1, 12, connectivity) == []
    @test path_search(7, 4, connectivity) == []
    @test path_search(8, 6, connectivity) == Vector{Int}(collect(6:8))
    @test path_search(1, 1, connectivity) == []

    exclusion_cases = [[5], [5, 7], [8]]
    for excluded in exclusion_cases
        @test path_search(4, 8, connectivity, excluded) == []
    end

    @test path_search(8, 7, connectivity, [5]) == Vector{Int}(collect(7:8))

    @test_throws AssertionError path_search(1, 44, connectivity)
    @test_throws AssertionError path_search(44, 1, connectivity)
    @test_throws AssertionError path_search(-1, 4, connectivity)
    @test_throws AssertionError path_search(4, -1, connectivity)
    @test_throws AssertionError path_search(1, 12, connectivity, [-1])

    @test_throws AssertionError("elements in excluded_positions must be > 0") LineConnectivity(
        12,
        [0],
    )
    @test_throws AssertionError("elements in excluded_positions must be ≤ 12") LineConnectivity(
        12,
        [13],
    )
    @test_throws AssertionError("elements in excluded_positions must be unique") LineConnectivity(
        12,
        [2, 2],
    )

    @test_throws AssertionError("connection (3, 3) must connect to different qubits") LineConnectivity(
        12,
        Int[],
        [(3, 3)],
    )

    @test_throws AssertionError("connection (1, 3) is not nearest-neighbor") LineConnectivity(
        12,
        Int[],
        [(1, 3)],
    )

    @test_throws AssertionError(
        "connection (0, 1) must have qubits with indices greater than 0",
    ) LineConnectivity(12, Int[], [(0, 1)])

    @test_throws AssertionError(
        "connection (12, 13) must have qubits with indices smaller than 13",
    ) LineConnectivity(12, Int[], [(12, 13)])

    @test_throws AssertionError("excluded_connections must be unique") LineConnectivity(
        12,
        Int[],
        [(1, 2), (2, 1)],
    )

    @test isinf(get_qubits_distance(1, 12, connectivity))
    @test isinf(get_qubits_distance(1, 12, LineConnectivity(12, Int[], [(6, 5)])))

    io = IOBuffer()

    excluded_positions = collect(13:24)
    excluded_connections = [(9, 13), (13, 10), (13, 18), (13, 17), (7, 4), (4, 8)]
    sorted_connections = [(9, 13), (10, 13), (13, 18), (13, 17), (4, 7), (4, 8)]

    connectivity = LatticeConnectivity(6, 4, excluded_positions, excluded_connections)

    @test get_excluded_positions(connectivity) == excluded_positions
    @test get_excluded_connections(connectivity) == sorted_connections

    alternate_positions = Snowflurry.with_excluded_positions(
        LatticeConnectivity(6, 4, Int[], excluded_connections),
        excluded_positions,
    )
    @test connectivity.qubits_per_printout_line ==
        alternate_positions.qubits_per_printout_line
    @test connectivity.dimensions == alternate_positions.dimensions
    @test connectivity.excluded_positions == alternate_positions.excluded_positions
    @test connectivity.excluded_connections == alternate_positions.excluded_connections

    alternate_connections = Snowflurry.with_excluded_connections(
        LatticeConnectivity(6, 4, excluded_positions),
        excluded_connections,
    )
    @test connectivity.qubits_per_printout_line ==
        alternate_connections.qubits_per_printout_line
    @test connectivity.dimensions == alternate_connections.dimensions
    @test connectivity.excluded_positions == alternate_connections.excluded_positions
    @test connectivity.excluded_connections == alternate_connections.excluded_connections

    expected_adjacency_list = Dict{Int,Vector{Int}}(
        1 => [5],
        2 => [6, 5],
        3 => [7, 6],
        4 => [8, 7],
        5 => [1, 10, 9, 2],
        6 => [2, 11, 10, 3],
        7 => [3, 12, 11, 4],
        8 => [4, 12],
        9 => [5],
        10 => [5, 6],
        11 => [6, 7],
        12 => [7, 8],
    )

    @test expected_adjacency_list == get_adjacency_list(connectivity)

    print_connectivity(connectivity, path_search(1, 8, connectivity), io)

    @test String(take!(io)) ==
          "             (1)\n" *
          "              | \n" *
          "        9 ── (5)──  2 \n" *
          "        |     |     | \n" *
          " 17 ── 13 ──(10)── (6)──  3 \n" *
          "  |     |     |     |     | \n" *
          " 21 ── 18 ── 14 ──(11)── (7)──  4 \n" *
          "        |     |     |     |     | \n" *
          "       22 ── 19 ── 15 ──(12)── (8)\n" *
          "              |     |     | \n" *
          "             23 ── 20 ── 16 \n" *
          "                    | \n" *
          "                   24 \n" *
          "\n"

    io = IOBuffer()
    println(io, connectivity)
    @test String(take!(io)) ==
          "LatticeConnectivity{6,4}\n" *
          "              1 \n" *
          "              | \n" *
          "        9 ──  5 ──  2 \n" *
          "        |     |     | \n" *
          " 17 ── 13 ── 10 ──  6 ──  3 \n" *
          "  |     |     |     |     | \n" *
          " 21 ── 18 ── 14 ── 11 ──  7 ──  4 \n" *
          "        |     |     |     |     | \n" *
          "       22 ── 19 ── 15 ── 12 ──  8 \n" *
          "              |     |     | \n" *
          "             23 ── 20 ── 16 \n" *
          "                    | \n" *
          "                   24 \n" *
          "\n" *
          "excluded positions: [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]\n" *
          "excluded connections: [(9, 13), (10, 13), (13, 18), (13, 17), (4, 7), (4, 8)]" *
          "\n\n"

    @test path_search(1, 8, connectivity) == [8, 12, 7, 11, 6, 10, 5, 1]
    excluded = [12, 11]
    @test path_search(1, 8, connectivity, excluded) == [8, 4, 7, 3, 6, 10, 5, 1]
    @test path_search(1, 1, connectivity) == [1]

    @test path_search(1, 9, connectivity, [5, 6]) == []
    @test path_search(21, 1, connectivity, [17]) == []
    @test path_search(1, 3, connectivity, [1]) == []
    @test path_search(1, 3, connectivity, [3]) == []

    @test_throws AssertionError path_search(1, 44, connectivity)
    @test_throws AssertionError path_search(44, 1, connectivity)
    @test_throws AssertionError path_search(-1, 4, connectivity)
    @test_throws AssertionError path_search(4, -1, connectivity)
    @test_throws AssertionError path_search(1, 3, connectivity, [-1])

    @test_throws AssertionError("elements in excluded_positions must be > 0") LatticeConnectivity(
        6,
        4,
        [0],
    )
    @test_throws AssertionError("elements in excluded_positions must be ≤ 24") LatticeConnectivity(
        6,
        4,
        [25],
    )
    @test_throws AssertionError("elements in excluded_positions must be unique") LatticeConnectivity(
        6,
        4,
        [2, 2],
    )

    @test_throws(
        AssertionError("connection (1, 1) must connect to different qubits"),
        LatticeConnectivity(6, 4, Int[], [(1, 1)])
    )
    @test_throws(
        AssertionError("connection (0, 1) must have qubits with indices greater than 0"),
        LatticeConnectivity(6, 4, Int[], [(0, 1)])
    )
    @test_throws(
        AssertionError("connection (24, 25) must have qubits with indices less than 25"),
        LatticeConnectivity(6, 4, Int[], [(24, 25)])
    )

    @test_throws(
        AssertionError("connection (1, 2) does not exist"),
        LatticeConnectivity(6, 4, Int[], [(1, 2)])
    )

    excluded_positions = [5, 6, 2]
    connectivity = LatticeConnectivity(6, 4, excluded_positions)
    @test isinf(get_qubits_distance(1, 9, connectivity))

    excluded_connections = [(2, 5), (2, 6)]
    connectivity = LatticeConnectivity(6, 4, Int[], excluded_connections)
    @test isinf(get_qubits_distance(2, 10, connectivity))
end

@testset "is_native_instruction: NotImplemented" begin

    struct NonExistentConnectivity <: AbstractConnectivity end
    struct NonExistentInstruction <: AbstractInstruction end

    @test_throws NotImplementedError is_native_instruction(
        sigma_x(1),
        NonExistentConnectivity(),
    )
    @test_throws NotImplementedError is_native_instruction(
        NonExistentInstruction(),
        LineConnectivity(2),
    )
    @test_throws NotImplementedError is_native_instruction(
        NonExistentInstruction(),
        NonExistentConnectivity(),
    )

    @test_throws NotImplementedError Snowflurry.with_excluded_positions(
        NonExistentConnectivity(),
        Int[],
    )
    @test_throws NotImplementedError get_excluded_positions(NonExistentConnectivity())

    @test_throws NotImplementedError Snowflurry.with_excluded_connections(
        NonExistentConnectivity(),
        Tuple{Int,Int}[],
    )
    @test_throws NotImplementedError get_excluded_connections(NonExistentConnectivity())
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

        qubits_per_printout_line = connectivity.qubits_per_printout_line

        ncols = 0
        for (qubit_count, offset) in zip(qubits_per_printout_line, offsets)
            ncols = maximum([ncols, qubit_count + offset])
        end

        nrows = length(qubits_per_printout_line)
        qubit_placement = zeros(Int, nrows, ncols)
        qubit_count = get_num_qubits(connectivity)

        qubit_numbering = Snowflurry.assign_qubit_numbering(
            qubits_per_printout_line,
            connectivity.dimensions[2],
        )

        for (irow, qubit_count) in enumerate(qubits_per_printout_line)
            offset = offsets[irow]
            qubit_placement[irow, 1+offset:qubit_count+offset] = qubit_numbering[irow]
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
    expected_metadata_str_list = [yukonMetadata, yukonMetadataWithExcludedComponents]
    expected_excluded_positions_list = [Int[], Int[3, 4, 5, 6]]
    expected_excluded_connections_list = [Tuple{Int,Int}[], Tuple{Int,Int}[(4, 5), (5, 6)]]

    for (i_metadata, expected_metadata_str) in enumerate(expected_metadata_str_list)

        expected_excluded_positions = expected_excluded_positions_list[i_metadata]
        expected_excluded_connections = expected_excluded_connections_list[i_metadata]
        requestor = MockRequestor(
            stub_response_sequence([stubMetadataResponse(expected_metadata_str)]),
            make_post_checker(expected_json_yukon),
        )

        qpu = AnyonYukonQPU(
            Client(
                host = expected_host,
                user = expected_user,
                access_token = expected_access_token,
                requestor = requestor,
            ),
            expected_project_id,
            status_request_throttle = no_throttle,
        )
        client = get_client(qpu)

        io = IOBuffer()
        println(io, qpu)
        @test String(take!(io)) ==
              "Quantum Processing Unit:\n" *
              "   manufacturer:  Anyon Systems Inc.\n" *
              "   generation:    Yukon\n" *
              "   serial_number: ANYK202201\n" *
              "   project_id:    project_id\n" *
              "   qubit_count:   6\n" *
              "   connectivity_type:  linear\n" *
              "\n"

        io = IOBuffer()
        println(io, client)
        @test String(take!(io)) ==
              "Client for QPU service:\n" *
              "   host:         http://example.anyonsys.com\n" *
              "   user:         test_user \n" *
              "\n"

        connectivity = get_connectivity(qpu)

        @test get_excluded_positions(qpu) ==
              get_excluded_positions(connectivity) ==
              expected_excluded_positions

        @test client.host == expected_host
        @test client.user == expected_user
        @test client.access_token == expected_access_token

        test_print_connectivity(qpu, "1──2──3──4──5──6\n")

        @test get_connectivity_label(get_connectivity(qpu)) ==
              Snowflurry.line_connectivity_label

        @test get_metadata(qpu) == Metadata(
            "manufacturer" => "Anyon Systems Inc.",
            "generation" => "Yukon",
            "serial_number" => "ANYK202201",
            "project_id" => expected_project_id,
            "qubit_count" => 6,
            "connectivity_type" => Snowflurry.line_connectivity_label,
            "excluded_positions" => expected_excluded_positions,
            "excluded_connections" => expected_excluded_connections,
            "status" => "online",
        )

    end
end

@testset "Construct AnyonYukonQPU with invalid coupler entries" begin
    expected_metadata_str = yukonMetadataWithInvalidCouplerEntries

    requestor = MockRequestor(
        stub_response_sequence([stubMetadataResponse(expected_metadata_str)]),
        make_post_checker(expected_json_yukon),
    )

    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )

    @test_throws ErrorException get_metadata(qpu)
end

@testset "Construct AnyonYukonQPU with non default realm" begin

    requestor = MockRequestor(
        stub_response_sequence([stubMetadataResponse(yukonMetadata)]),
        make_post_checker(expected_json_yukon),
    )
    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
            realm = expected_realm,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )

    @test Snowflurry.get_realm(qpu) == expected_realm

    @test get_metadata(qpu) == Metadata(
        "manufacturer" => "Anyon Systems Inc.",
        "generation" => "Yukon",
        "serial_number" => "ANYK202201",
        "project_id" => expected_project_id,
        "qubit_count" => 6,
        "connectivity_type" => Snowflurry.line_connectivity_label,
        "realm" => expected_realm,
        "excluded_positions" => Vector{Int}(),
        "excluded_connections" => Vector{Tuple{Int,Int}}(),
        "status" => "online",
    )
end

@testset "Construct AnyonYamaskaQPU" begin
    expected_metadata_str_list = [yamaskaMetadata, yamaskaMetadataWithExcludedComponents]
    expected_excluded_positions_list = [Int[], Int[7, 8, 9, 10, 11, 12]]
    expected_excluded_connections_list =
        [Tuple{Int,Int}[], Tuple{Int,Int}[(7, 12), (12, 8)]]

    for (i_metadata, expected_metadata_str) in enumerate(expected_metadata_str_list)

        expected_excluded_positions = expected_excluded_positions_list[i_metadata]
        expected_excluded_connections = expected_excluded_connections_list[i_metadata]
        requestor = MockRequestor(
            stub_response_sequence([stubMetadataResponse(expected_metadata_str)]),
            make_post_checker(""),
        )

        qpu = AnyonYamaskaQPU(
            Client(
                host = expected_host,
                user = expected_user,
                access_token = expected_access_token,
                requestor = requestor,
            ),
            expected_project_id,
            status_request_throttle = no_throttle,
        )
        client = get_client(qpu)

        io = IOBuffer()
        println(io, qpu)
        @test String(take!(io)) ==
              "Quantum Processing Unit:\n" *
              "   manufacturer:  Anyon Systems Inc.\n" *
              "   generation:    Yamaska\n" *
              "   serial_number: ANYK202301\n" *
              "   project_id:    project_id\n" *
              "   qubit_count:   24\n" *
              "   connectivity_type:  2D-lattice\n" *
              "\n"

        io = IOBuffer()
        println(io, client)
        @test String(take!(io)) ==
              "Client for QPU service:\n" *
              "   host:         http://example.anyonsys.com\n" *
              "   user:         test_user \n" *
              "\n"

        connectivity = get_connectivity(qpu)

        @test get_excluded_positions(qpu) ==
              get_excluded_positions(connectivity) ==
              expected_excluded_positions

        @test client.host == expected_host
        @test client.user == expected_user
        @test client.access_token == expected_access_token

        test_print_connectivity(
            qpu,
            "              1 \n" *
            "              | \n" *
            "        9 ──  5 ──  2 \n" *
            "        |     |     | \n" *
            " 17 ── 13 ── 10 ──  6 ──  3 \n" *
            "  |     |     |     |     | \n" *
            " 21 ── 18 ── 14 ── 11 ──  7 ──  4 \n" *
            "        |     |     |     |     | \n" *
            "       22 ── 19 ── 15 ── 12 ──  8 \n" *
            "              |     |     | \n" *
            "             23 ── 20 ── 16 \n" *
            "                    | \n" *
            "                   24 \n" *
            "\n",
        )


        @test get_connectivity_label(get_connectivity(qpu)) ==
              Snowflurry.lattice_connectivity_label

        @test get_metadata(qpu) == Metadata(
            "manufacturer" => "Anyon Systems Inc.",
            "generation" => "Yamaska",
            "serial_number" => "ANYK202301",
            "project_id" => expected_project_id,
            "qubit_count" => 24,
            "connectivity_type" => Snowflurry.lattice_connectivity_label,
            "excluded_positions" => expected_excluded_positions,
            "excluded_connections" => expected_excluded_connections,
            "status" => "online",
        )
    end
end

@testset "AnyonQPUs with empty project_id succeeds" begin
    qpus = [AnyonYukonQPU, AnyonYamaskaQPU]

    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = yukon_requestor,
    )

    for qpu in qpus

        qpu(test_client, "")

        qpu(;
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            status_request_throttle = no_throttle,
            project_id = "",
        )
    end

end

@testset "run_job on AnyonYukonQPU" begin

    # without optional realm
    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = yukon_requestor_with_empty_realm,
    )
    shot_count = 100
    qpu = AnyonYukonQPU(
        test_client,
        expected_project_id,
        status_request_throttle = no_throttle,
    )
    println(qpu) #coverage for Base.show(::IO,::AnyonYukonQPU)
    @test get_client(qpu) == test_client

    @test Snowflurry.get_realm(qpu) == ""
    @test Snowflurry.get_realm(test_client) == ""

    io = IOBuffer()
    println(io, test_client)
    @test String(take!(io)) ==
          "Client for QPU service:\n" *
          "   host:         http://example.anyonsys.com\n" *
          "   user:         test_user \n" *
          "\n"

    #test basic submission, no transpilation
    circuit = QuantumCircuit(
        qubit_count = 3,
        instructions = [sigma_x(3), control_z(2, 1), readout(1, 1)],
    )
    histogram, qpu_time = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")
    @test qpu_time == expected_qpu_time

    #verify that run_job blocks until a 'long-running' job completes
    requestor = MockRequestor(
        stub_response_sequence([
            stubMetadataResponse(yukonMetadata),
            stubStatusResponse(Snowflurry.queued_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.succeeded_status),
            stubResult(),
        ]),
        make_post_checker(expected_json_yukon),
    )
    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )
    histogram, qpu_time = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")
    @test qpu_time == expected_qpu_time

    #verify that run_job throws an error if the QPU returns an error
    requestor = MockRequestor(
        stub_response_sequence([
            stubMetadataResponse(yukonMetadata),
            stubStatusResponse(Snowflurry.queued_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.running_status),
            stubFailedStatusResponse(),
        ]),
        make_post_checker(expected_json_yukon),
    )
    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )
    @test_throws ErrorException histogram, qpu_time = run_job(qpu, circuit, shot_count)

    #verify that run_job throws an error if the job was cancelled
    requestor = MockRequestor(
        stub_response_sequence([
            stubMetadataResponse(yukonMetadata),
            stubStatusResponse(Snowflurry.queued_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.running_status),
            stubStatusResponse(Snowflurry.cancelled_status),
            stubCancelledResultResponse(),
        ]),
        make_post_checker(expected_json_yukon),
    )
    qpu = AnyonYukonQPU(
        Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        ),
        expected_project_id,
        status_request_throttle = no_throttle,
    )
    @test_throws ErrorException histogram, qpu_time = run_job(qpu, circuit, shot_count)
end

@testset "run_job on AnyonQPUs: with realm" begin


    yukon_test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = yukon_requestor_with_realm,
        realm = expected_realm,
    )

    yamaska_test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = yamaska_requestor_with_realm,
        realm = expected_realm,
    )

    io = IOBuffer()
    println(io, yukon_test_client)
    @test String(take!(io)) ==
          "Client for QPU service:\n" *
          "   host:         http://example.anyonsys.com\n" *
          "   user:         test_user \n" *
          "   realm:        test-realm \n" *
          "\n"

    @test Snowflurry.get_realm(yukon_test_client) == expected_realm

    #test basic submission, no transpilation
    circuit = QuantumCircuit(
        qubit_count = 3,
        instructions = [sigma_x(3), control_z(2, 1), readout(1, 1)],
    )
    shot_count = 100

    qpu = AnyonYukonQPU(
        yukon_test_client,
        expected_project_id,
        status_request_throttle = no_throttle,
    )

    io = IOBuffer()
    println(io, qpu)
    @test String(take!(io)) ==
          "Quantum Processing Unit:\n" *
          "   manufacturer:  Anyon Systems Inc.\n" *
          "   generation:    Yukon\n" *
          "   serial_number: ANYK202201\n" *
          "   project_id:    project_id\n" *
          "   qubit_count:   6\n" *
          "   connectivity_type:  linear\n" *
          "   realm:         test-realm\n" *
          "\n"

    @test Snowflurry.get_realm(qpu) == expected_realm

    histogram, qpu_time = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")
    @test qpu_time == expected_qpu_time

    qpu = AnyonYamaskaQPU(
        yamaska_test_client,
        expected_project_id,
        status_request_throttle = no_throttle,
    )

    io = IOBuffer()
    println(io, qpu)
    @test String(take!(io)) ==
          "Quantum Processing Unit:\n" *
          "   manufacturer:  Anyon Systems Inc.\n" *
          "   generation:    Yamaska\n" *
          "   serial_number: ANYK202301\n" *
          "   project_id:    project_id\n" *
          "   qubit_count:   24\n" *
          "   connectivity_type:  2D-lattice\n" *
          "   realm:         test-realm\n" *
          "\n"

    @test Snowflurry.get_realm(qpu) == expected_realm

    histogram, qpu_time = run_job(qpu, circuit, shot_count)
    @test histogram == Dict("001" => shot_count)
    @test !haskey(histogram, "error_msg")
    @test qpu_time == expected_qpu_time
end

@testset "run_job with invalid circuits on AnyonYukonQPU" begin

    test_client = Client(
        host = expected_host,
        user = expected_user,
        access_token = expected_access_token,
        requestor = yukon_requestor,
    )
    shot_count = 100
    qpu = AnyonYukonQPU(
        test_client,
        expected_project_id,
        status_request_throttle = no_throttle,
    )

    invalid_instructions = [
        (
            [sigma_x(1)],
            ArgumentError(
                "QuantumCircuit is missing a `Readout`. Would not return any result.",
            ),
        ),
        (
            [readout(1, 1), readout(2, 1)],
            ArgumentError(
                "`Readouts` in `QuantumCircuit` have conflicting destination bit: 1",
            ),
        ),
        (
            [readout(1, 1), readout(1, 2)],
            AssertionError("Found multiple `Readouts` on qubit: 1"),
        ),
        (
            [readout(1, 1), sigma_x(1)],
            AssertionError("Cannot perform `Gate` following `Readout` on qubit: 1"),
        ),
        (
            [controlled(hadamard(2), [1, 3]), readout(2, 1)],
            NotImplementedError{Gate{Controlled{Snowflurry.Hadamard}}},
        ),
    ]

    for (instrs, e) in invalid_instructions
        circuit = QuantumCircuit(qubit_count = 3, instructions = instrs)
        @test_throws e run_job(qpu, circuit, shot_count)
    end

end

@testset "transpile_and_run_job on AnyonYukonQPU and AnyonYamaskaQPU" begin

    test_specs = [
        ("yukon", AnyonYukonQPU, yukonMetadata, Snowflurry.AnyonYukonConnectivity),
        ("yamaska", AnyonYamaskaQPU, yamaskaMetadata, Snowflurry.AnyonYamaskaConnectivity),
    ]
    post_checkers_toffoli = [
        make_post_checker(expected_json_Toffoli_Yukon),
        make_post_checker(expected_json_Toffoli_Yamaska),
    ]
    post_checkers_last_qubit = [
        make_post_checker(expected_json_last_qubit_Yukon),
        make_post_checker(expected_json_last_qubit_Yamaska),
    ]

    for (
        (qpu_name, QPU, metadata, connectivity),
        post_checker_toffoli,
        post_checker_last_qubit,
    ) in zip(test_specs, post_checkers_toffoli, post_checkers_last_qubit)

        requestor = MockRequestor(
            make_request_checker(
                "",
                Dict("machineName" => qpu_name),
                return_metadata = metadata,
            ),
            make_post_checker(expected_json_yukon),
        )
        test_client = Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        )
        shot_count = 100

        qpu = QPU(test_client, expected_project_id, status_request_throttle = no_throttle)

        # submit circuit with qubit_count_circuit>qubit_count_qpu
        circuit = QuantumCircuit(
            qubit_count = get_num_qubits(qpu) + 1,
            instructions = [readout(1, 1)],
        )
        @test_throws DomainError transpile_and_run_job(qpu, circuit, shot_count)

        # submit circuit with a non-native gate on this qpu
        circuit = QuantumCircuit(
            qubit_count = get_num_qubits(qpu) - 1,
            instructions = [toffoli(1, 2, 3), readout(1, 1)],
        )

        # using default transpiler with full connectivity
        requestor = MockRequestor(
            stub_request_checker_sequence(
                Function[
                    make_request_checker(
                        "",
                        Dict("machineName" => qpu_name),
                        return_metadata = metadata,
                    ),
                    make_request_checker(""),
                ],
            ),
            post_checker_toffoli,
        )
        test_client = Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        )

        qpu = QPU(test_client, expected_project_id, status_request_throttle = no_throttle)

        histogram, qpu_time = transpile_and_run_job(
            qpu,
            circuit,
            shot_count;
            transpiler = Snowflurry.get_anyon_transpiler(connectivity = connectivity),
        )

        @test histogram == Dict("001" => shot_count)
        @test !haskey(histogram, "error_msg")
        @test qpu_time == expected_qpu_time

        # submit circuit with qubit_count_circuit==qubit_count_qpu
        requestor = MockRequestor(
            stub_request_checker_sequence(
                Function[
                    make_request_checker(
                        "",
                        Dict("machineName" => qpu_name),
                        return_metadata = metadata,
                    ),
                    make_request_checker(""),
                ],
            ),
            post_checker_last_qubit,
        )
        test_client = Client(
            host = expected_host,
            user = expected_user,
            access_token = expected_access_token,
            requestor = requestor,
        )
        qpu = QPU(test_client, expected_project_id, status_request_throttle = no_throttle)

        qubit_count = get_num_qubits(qpu)
        circuit = QuantumCircuit(
            qubit_count = qubit_count,
            instructions = [sigma_x(qubit_count), readout(1, 1)],
        )

        transpile_and_run_job(
            qpu,
            circuit,
            shot_count;
            transpiler = Snowflurry.get_anyon_transpiler(connectivity = connectivity),
        ) # no error thrown
    end
end

@testset "Submission failure: status offline" begin

    expected_metadata_str_list =
        [yukonMetadataWithOfflineStatus, yamaskaMetadataWithOfflineStatus]

    qpus = [AnyonYukonQPU, AnyonYamaskaQPU]

    for (expected_metadata_str, qpu_ctor) in zip(expected_metadata_str_list, qpus)
        requestor = MockRequestor(
            stub_response_sequence([stubMetadataResponse(expected_metadata_str)]),
            () -> Nothing,
        )

        qpu = qpu_ctor(
            Client(
                host = expected_host,
                user = expected_user,
                access_token = expected_access_token,
                requestor = requestor,
            ),
            expected_project_id,
            status_request_throttle = no_throttle,
        )

        circuit = QuantumCircuit(
            qubit_count = 2,
            instructions = [sigma_x(1), readout(1, 1)],
            name = "sigma_x job",
        )
        shot_count = 100

        @test_throws AssertionError(
            "cannot submit jobs to: $(Snowflurry.get_machine_name(qpu)); current status is : \"offline\"",
        ) run_job(qpu, circuit, shot_count)
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

    histogram, qpu_time = transpile_and_run_job(qpu, circuit, shot_count)

    @test histogram == Dict("001" => shot_count)

    connectivity = get_connectivity(qpu)

    @test Snowflurry.get_machine_name(qpu) == Snowflurry.AnyonVirtualMachineName

    @test connectivity isa AllToAllConnectivity
    @test get_connectivity_label(connectivity) == Snowflurry.all2all_connectivity_label
    test_print_connectivity(connectivity, "AllToAllConnectivity()\n")

    @test_throws DomainError(
        "All qubits are adjacent in AllToAllConnectivity, without upper" *
        " limit on qubit count. A finite list of adjacent qubits thus cannot be constructed.",
    ) get_adjacency_list(connectivity)

end

@testset "run on VirtualQPU: partial readouts" begin

    circuit = QuantumCircuit(
        qubit_count = 5,
        instructions = [hadamard(1), control_x(1, 2), control_x(2, 3), readout(3, 1)],
    )

    shot_count = 100

    qpu = VirtualQPU()

    histogram, qpu_time = transpile_and_run_job(qpu, circuit, shot_count)

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

    histogram, qpu_time = transpile_and_run_job(qpu, circuit, shot_count)

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

        histogram, qpu_time = transpile_and_run_job(qpu, circuit, shot_count)

        @test haskey(histogram, "1")
        pop!(histogram, "1")
        @test length(histogram) == 0
    end
end

@testset "AbstractQPU" begin
    struct NonExistentQPU <: Snowflurry.AbstractQPU end

    @test_throws NotImplementedError get_metadata(NonExistentQPU())
    @test_throws NotImplementedError get_connectivity(NonExistentQPU())
    @test_throws NotImplementedError get_transpiler(NonExistentQPU())
    @test_throws NotImplementedError run_job(
        NonExistentQPU(),
        QuantumCircuit(qubit_count = 1),
        42,
    )
end
