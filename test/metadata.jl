using Snowflurry
using Test
using HTTP
using JSON

include("mock_functions.jl")

@testset "Construct AnyonYukonQPU with faulty metadata" begin

    faultyMetadataList = [
        ("[{\"name\":\"wrong-name\"}]", "name", "wrong-name", "yukon")
        (
            "[{\"name\":\"yukon\",\"type\":\"wrong-type\"}]",
            "type",
            "wrong-type",
            "quantum-computer",
        )
        (
            "[{\"name\":\"yukon\",\"type\":\"quantum-computer\",\"qubitCount\":0}]",
            "qubitCount",
            0,
            6,
        )
        (
            "[{\"name\":\"yukon\",\"type\":\"quantum-computer\",\"qubitCount\":6,\"bitCount\":0}]",
            "bitCount",
            0,
            6,
        )
        (
            "[{\"name\":\"yukon\",\"type\":\"quantum-computer\",\"qubitCount\":6,\"bitCount\":6,\"connectivity\":\"wrong-connectivity\"}]",
            "connectivity",
            "wrong-connectivity",
            "linear",
        )
    ]

    for (metadata, key, received_val, expected_val) in faultyMetadataList
        requestor = MockRequestor(
            stub_response_sequence([stubMetadataResponse(metadata)]),
            make_post_checker(""),
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
        @test_throws AssertionError(
            "expected: \"$expected_val\", received \"$(received_val)\" in returned metadata key \"$(key)\"",
        ) get_metadata(qpu)

    end
end

@testset "Construct AnyonYukonQPU with missing metadata keys" begin

    qpus_to_metadata = Dict(
        AnyonYukonQPU => [yukonMetadata, yukonMetadataWithDisconnectedQubits],
        AnyonYamaskaQPU => [yamaskaMetadata, yamaskaMetadataWithDisconnectedQubits],
    )

    keys_to_delete = ["name", "type", "qubitCount", "bitCount", "connectivity", "status"]

    for (qpu, metadata_list) in qpus_to_metadata
        for metadataStr in metadata_list
            for key in keys_to_delete
                metadata = JSON.parse(metadataStr)
                delete!(metadata[1], key)
                metadata_with_missing_entry = JSON.json(metadata)

                requestor = MockRequestor(
                    stub_response_sequence([
                        stubMetadataResponse(metadata_with_missing_entry),
                    ]),
                    make_post_checker(""),
                )
                q = qpu(
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
                @test_throws AssertionError("key \"$key\" missing from returned metadata") get_metadata(
                    q,
                )
            end

            # check error message for "offline" status
            metadata = JSON.parse(metadataStr)
            metadata[1]["status"] = "offline"
            metadata_with_offline_status = JSON.json(metadata)

            requestor = MockRequestor(
                stub_response_sequence([
                    stubMetadataResponse(metadata_with_offline_status),
                ]),
                make_post_checker(""),
            )
            q = qpu(
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
            @test_throws AssertionError(
                "cannot submit jobs to: $(Snowflurry.get_machine_name(q)); current status is : \"offline\"",
            ) get_metadata(q)

            # missing serial number does not throw error
            metadata = JSON.parse(metadataStr)
            delete!(metadata[1]["metadata"], "Serial Number")
            metadata_with_no_serial_number = JSON.json(metadata)

            requestor = MockRequestor(
                stub_response_sequence([
                    stubMetadataResponse(metadata_with_no_serial_number),
                ]),
                make_post_checker(""),
            )
            q = qpu(
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

            @test haskey(get_metadata(q), "serial_number")
            @test get_metadata(q)["serial_number"] == ""
        end
    end
end


@testset "Construct AnyonYamaskaQPU with faulty metadata" begin

    faultyMetadataList = [
        ("[{\"name\":\"wrong-name\"}]", "name", "wrong-name", "yamaska")
        (
            "[{\"name\":\"yamaska\",\"type\":\"wrong-type\"}]",
            "type",
            "wrong-type",
            "quantum-computer",
        )
        (
            "[{\"name\":\"yamaska\",\"type\":\"quantum-computer\",\"qubitCount\":0}]",
            "qubitCount",
            0,
            12,
        )
        (
            "[{\"name\":\"yamaska\",\"type\":\"quantum-computer\",\"qubitCount\":12,\"bitCount\":0}]",
            "bitCount",
            0,
            12,
        )
        (
            "[{\"name\":\"yamaska\",\"type\":\"quantum-computer\",\"qubitCount\":12,\"bitCount\":12,\"connectivity\":\"wrong-connectivity\"}]",
            "connectivity",
            "wrong-connectivity",
            "lattice",
        )
    ]

    for (metadata, key, received_val, expected_val) in faultyMetadataList
        requestor = MockRequestor(
            stub_response_sequence([stubMetadataResponse(metadata)]),
            make_post_checker(""),
        )
        qpu = AnyonYamaskaQPU(
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
        @test_throws AssertionError(
            "expected: \"$expected_val\", received \"$(received_val)\" in returned metadata key \"$(key)\"",
        ) get_metadata(qpu)

    end
end
