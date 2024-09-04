using Snowflurry

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
        make_request_checker(expected_realm),
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
    make_request_checker(expected_realm),
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
