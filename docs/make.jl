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
        include("../test/docstest_helpers.jl")
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
            "Real Hardware" => "tutorials/anyon_qpu.md"
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
