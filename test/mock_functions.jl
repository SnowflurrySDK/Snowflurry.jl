using Snowflake
using HTTP

host="http://example.anyonsys.com"
user="test_user"
access_token="not_a_real_access_token"

function post_checker(url::String,access_token::String,body::String)

    expected_url=joinpath(host,Snowflake.path_circuits)
    expected_access_token=access_token
    expected_json="{\"num_repititions\":100,\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"

    @assert url==expected_url ("received: \n$url, \nexpected: \n$expected_url")
    @assert access_token==expected_access_token  ("received: \n$access_token, expected: \n$expected_access_token")
    @assert body==expected_json  ("received: \n$body, expected: \n$expected_json")

    return HTTP.Response(200, [], 
        body="{\"circuitID\":\"8050e1ed-5e4c-4089-ab53-cccda1658cd0\"}";
    )
end

function request_checker(url::String,access_token::String)
    myregex=Regex("(.*)(/$(Snowflake.path_circuits)/)(.*)")
    match_obj=match(myregex,url)

    if !isnothing(match_obj)

        myregex=Regex("(.*)(/$(Snowflake.path_circuits)/)(.*)(/$(Snowflake.path_results))\$")   
        match_obj=match(myregex,url)
                
        if !isnothing(match_obj)
            # caller is :get_result
            return HTTP.Response(200, [], 
                body="{\"histogram\":{\"001\":\"100\"}}"
            ) 
        else
            myregex=Regex("(.*)(/$(Snowflake.path_circuits)/)([^/]*)\$")
            match_obj=match(myregex,url)

            if !isnothing(match_obj)
                # caller is :get_status
                return HTTP.Response(200, [], 
                    body="{\"status\":{\"type\":\"succeeded\"}}"
                )
            end
        end
    end

    throw(NotImplementedError(:get_request,url))
end