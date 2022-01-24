push!(LOAD_PATH, "../src/")

using Documenter
using Snowflake

DocMeta.setdocmeta!(Snowflake, :DocTestSetup, :(using Snowflake); recursive = true)
makedocs(
    sitename = "Snowflake",
    format = Documenter.HTML(),
    modules = [Snowflake],
    pages = [
        "Home" => "index.md",
        "Quantum Computing With Snowflake" => 
            [
                "Basics" => "qc/basics.md"
            ],
        #"Simulating Quantum Systems" => "simulating_quantum_systems.md",            
        "Library" => "library.md"
        ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#= deploydocs(
    repo = "<repository url>"
) =#
