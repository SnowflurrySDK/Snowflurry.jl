using Documenter
using JKet

makedocs(
    sitename="JKet",
    format=Documenter.HTML(),
    modules=[JKet]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#= deploydocs(
    repo = "<repository url>"
) =#
