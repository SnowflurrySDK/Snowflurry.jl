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
            stub_response_sequence([
                stubMetadataResponse(makeMetadataResponseJSON(metadata)),
            ]),
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

@testset "Construct AnyonYukonQPU with faulty metadata object" begin
    faultyMetadataList = [
        "{\"items\":[],\"total\":0,\"skipped\":0}",
        "{\"items\":[{\"name\":\"first-machine\"},{\"name\":\"second-machine\"}],\"total\":2,\"skipped\":0}",
        "{\"items\":[],\"total\":1,\"skipped\":0}",
        "{}",
        "",
    ]

    for metadata in faultyMetadataList
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

        @test_throws AssertionError get_metadata(qpu)
    end

end

@testset "Construct AnyonYukonQPU with missing metadata keys" begin

    qpus_to_metadata = Dict(
        AnyonYukonQPU => [yukonMetadata, yukonMetadataWithExcludedComponents],
        AnyonYamaskaQPU => [yamaskaMetadata, yamaskaMetadataWithExcludedComponents],
    )

    keys_to_delete = ["name", "type", "qubitCount", "bitCount", "connectivity", "status"]

    for (qpu, metadata_list) in qpus_to_metadata
        for metadataStr in metadata_list
            for key in keys_to_delete
                metadata = JSON.parse(metadataStr)
                delete!(metadata["items"][1], key)
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

            # missing serial number does not throw error
            metadata = JSON.parse(metadataStr)
            delete!(metadata["items"][1]["metadata"], "Serial Number")
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
        (
            makeMetadataResponseJSON("[{\"name\":\"wrong-name\"}]"),
            "name",
            "wrong-name",
            "yamaska",
        )
        (
            makeMetadataResponseJSON("[{\"name\":\"yamaska\",\"type\":\"wrong-type\"}]"),
            "type",
            "wrong-type",
            "quantum-computer",
        )
        (
            makeMetadataResponseJSON(
                "[{\"name\":\"yamaska\",\"type\":\"quantum-computer\",\"qubitCount\":0}]",
            ),
            "qubitCount",
            0,
            24,
        )
        (
            makeMetadataResponseJSON(
                "[{\"name\":\"yamaska\",\"type\":\"quantum-computer\",\"qubitCount\":24,\"bitCount\":0}]",
            ),
            "bitCount",
            0,
            24,
        )
        (
            makeMetadataResponseJSON(
                "[{\"name\":\"yamaska\",\"type\":\"quantum-computer\",\"qubitCount\":24,\"bitCount\":24,\"connectivity\":\"wrong-connectivity\"}]",
            ),
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

@testset "Getting metadata for offline QPUs succeeds" begin

    qpus_to_metadata = [
        (
            AnyonYukonQPU,
            yukonMetadataWithOfflineStatus,
            Metadata(
                "manufacturer" => "Anyon Systems Inc.",
                "generation" => "Yukon",
                "serial_number" => "ANYK202201",
                "project_id" => expected_project_id,
                "qubit_count" => 6,
                "connectivity_type" => Snowflurry.line_connectivity_label,
                "excluded_positions" => Int[],
                "excluded_couplers" => Tuple{Int,Int}[],
                "status" => "offline",
                "realm" => "test-realm",
            ),
        ),
        (
            AnyonYamaskaQPU,
            yamaskaMetadataWithOfflineStatus,
            Metadata(
                "manufacturer" => "Anyon Systems Inc.",
                "generation" => "Yamaska",
                "serial_number" => "ANYK202301",
                "project_id" => expected_project_id,
                "qubit_count" => 24,
                "connectivity_type" => Snowflurry.lattice_connectivity_label,
                "excluded_positions" => Int[],
                "excluded_couplers" => Tuple{Int,Int}[],
                "status" => "offline",
                "realm" => "test-realm",
            ),
        ),
    ]

    for (qpu_ctor, metadata, expected_metadata) in qpus_to_metadata
        requestor = MockRequestor(
            stub_response_sequence([stubMetadataResponse(metadata)]),
            make_post_checker(""),
        )
        qpu = qpu_ctor(
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

        @test expected_metadata == get_metadata(qpu)
    end
end
