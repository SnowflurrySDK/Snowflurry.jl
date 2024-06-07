push!(LOAD_PATH, "../src/")

using Documenter
using Snowflurry

DocMeta.setdocmeta!(
    Snowflurry,
    :DocTestSetup,
    quote
        using Snowflurry
        using Printf
        ENV["COLUMNS"] = 200
        include("../test/mock_functions.jl")

        client = Client(
            host = "http://example.anyonsys.com",
            user = "test_user",
            access_token = "not_a_real_access_token",
            requestor = yukon_requestor_with_realm,
            realm = "test-realm",
        )

        requestor_transpilation = MockRequestor(
            stub_request_checker_sequence([
                function (args...; kwargs...)
                    return stubMetadataResponse(yukonMetadata)
                end,
                make_request_checker(expected_realm, expected_empty_queries),
            ]),
            make_post_checker(expected_json_transpiled, expected_realm),
        )
        client_anyon = Client(
            host = "http://example.anyonsys.com",
            user = "test_user",
            access_token = "not_a_real_access_token",
            requestor = requestor_transpilation,
            realm = "test-realm",
        )

        yukon_requestor_with_realm_for_get_status = MockRequestor(
            make_request_checker(expected_realm, expected_empty_queries),
            make_post_checker(expected_json_yukon, expected_realm),
        )

        # this client expects one POST request from submit_job, and one GET request from get_status
        submit_job_client = Client(
            host = "http://example.anyonsys.com",
            user = "test_user",
            access_token = "not_a_real_access_token",
            requestor = yukon_requestor_with_realm_for_get_status,
            realm = "test-realm",
        )

        # Overload constructor so the docs show the method that interacts with the server,
        # but use a client that returns canned responses
        function Snowflurry.AnyonYukonQPU(;
            host::String,
            user::String,
            access_token::String,
            project_id::String,
            realm::String = "",
            status_request_throttle = Snowflurry.default_status_request_throttle,
        )
            @assert realm == expected_realm "overridden function expects an realm: $expected_realm, received: $realm"

            return AnyonYukonQPU(
                Client(
                    host = host,
                    user = user,
                    access_token = access_token,
                    requestor = yukon_requestor_with_realm,
                    realm = realm,
                ),
                project_id,
                status_request_throttle = no_throttle,
            )
        end

        # Overload constructor so the docs show the method that interacts with the server,
        # but use a client that returns canned responses
        function Snowflurry.AnyonYamaskaQPU(;
            host::String,
            user::String,
            access_token::String,
            project_id::String,
            realm::String = "",
            status_request_throttle = Snowflurry.default_status_request_throttle,
        )
            @assert realm == expected_realm "overridden function expects an realm: $expected_realm, received: $realm"

            return AnyonYamaskaQPU(
                Client(
                    host = host,
                    user = user,
                    access_token = access_token,
                    requestor = yamaska_requestor_with_realm,
                    realm = realm,
                ),
                project_id,
                status_request_throttle = no_throttle,
            )
        end
    end;
    recursive = true,
)
uuid_regex =
    r"[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}"

println()
@info "Generating docs using HTMLWriter"

makedocs(
    sitename = "Snowflurry",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "false",
        sidebar_sitename = false,
    ),
    modules = [Snowflurry],
    build = "build",
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Tutorials" => [
            "Basics" => "tutorials/basics.md"
            "Virtual QPU" => "tutorials/virtual_qpu.md"
            "Real hardware" => "tutorials/anyon_qpu.md"
        ],
        "Advanced Examples" => ["Asynchronous Jobs" => "tutorials/advanced/async_jobs.md"],
        "API Reference" => [
            "Quantum Toolkit" => "library/quantum_toolkit.md",
            "Quantum Gates" => "library/quantum_gates.md",
            "Quantum Circuits" => "library/quantum_circuit.md",
            "QPU" => "library/qpu.md",
            "Pauli Simulator" => "library/pauli_sim.md",
            "Visualization" => "library/viz.md",
        ],
        "Developing" => "development.md",
    ],
    doctestfilters = [uuid_regex],
    checkdocs = :exports,
)
