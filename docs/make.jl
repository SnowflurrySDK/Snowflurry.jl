push!(LOAD_PATH, "../src/")

using Documenter
using Snowflake


DocMeta.setdocmeta!(
    Snowflake, 
    :DocTestSetup, 
    quote
        using Snowflake
        ENV["COLUMNS"] = 200
        include("../test/mock_functions.jl")
        requestor=MockRequestor(request_checker,post_checker)
        client = Client(
            host="http://example.anyonsys.com",
            user="test_user",
            access_token="not_a_real_access_token",
            requestor=requestor
        );
        requestor_transpilation=MockRequestor(
            request_checker,
            post_checker_transpiled
        )
        client_anyon = Client(
            host="http://example.anyonsys.com",
            user="test_user",
            access_token="not_a_real_access_token",
            requestor=requestor_transpilation
        );
    end; 
    recursive = true
)
uuid_regex = r"[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}"
makedocs(
    sitename = "Snowflake",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "false"),
    modules = [Snowflake],
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Tutorials" => "tutorials/index.md",
        "Library" => "library.md",
    ],
    doctestfilters = [uuid_regex],
    strict = true,
    checkdocs = :exports
)
