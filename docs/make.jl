push!(LOAD_PATH, "../src/")

using Documenter
using Snowflurry

DocMeta.setdocmeta!(
    Snowflurry, 
    :DocTestSetup, 
    quote
        using Snowflurry
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

formattersAndDirs=[
    (Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "false"), "build", "HTMLWriter"),
]

for (formatter,build_dir, name) in formattersAndDirs
    println()
    @info "Generating docs using $name"

    makedocs(
        sitename = "Snowflurry",
        format = formatter,
        modules = [Snowflurry],
        build = build_dir,
        pages = [
            "Home" => "index.md",
            "Getting Started" => "getting_started.md",
            "Tutorials" => [
                "Basics"=>"tutorials/basics.md"
                "Virtual QPU" =>"tutorials/virtual_qpu.md"
                "Real hardware" =>"tutorials/anyon_qpu.md"
            ],
            "Advanced Examples" => [
                "Asynchronous Jobs"=>"tutorials/advanced/async_jobs.md"
            ],
            "API Reference" => [
                "Quantum Toolkit"=>"library/quantum_toolkit.md",
                "Quantum Gates"=>"library/quantum_gates.md",
                "Quantum Circuits"=>"library/quantum_circuit.md",
                "QPU"=>"library/qpu.md",
                "Pauli Simulator"=>"library/pauli_sim.md",
                "Visualization"=>"library/viz.md",
            ],

            "Developing" => "development.md",
        ],
        doctestfilters = [uuid_regex],
        strict = true,
        checkdocs = :exports
    )
end