push!(LOAD_PATH, "../src/")

using Documenter
using Snowflake

makedocs(
    sitename = "Snowflake",
    format = Documenter.HTML(),
    modules = [Snowflake],
    # pages = [
    #     "index.md",
    #     "Getting Started" => "get_started.md",
    #     ],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#= deploydocs(
    repo = "<repository url>"
) =#
