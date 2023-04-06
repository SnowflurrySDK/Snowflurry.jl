using Coverage
using Pkg
using SnowflakePlots

Pkg.test("SnowflakePlots"; coverage = true)
# process '*.cov' files
coverage = process_folder("SnowflakePlots.jl/src") # defaults to src/; alternatively, supply the folder name as argument
# coverage = append!(coverage, process_folder("deps"))  # useful if you want to analyze more than just src/
# process '*.info' files, if you collected them
coverage = merge_coverage_counts(
    coverage,
    filter!(
        let prefixes = (joinpath(pwd(), "SnowflakePlots.jl/src", ""))
            c -> any(p -> startswith(c.filename, p), prefixes)
        end,
        LCOV.readfolder("SnowflakePlots.jl/test"),
    ),
)
LCOV.writefile("SnowflakePlots.jl/lcov.info", coverage)

# Get total coverage for all Julia files
covered_lines, total_lines = get_summary(coverage)
# Or process a single file
# @show get_summary(process_file(joinpath("src", "Snowflake.jl")

#clean .cov files
clean_folder("SnowflakePlots.jl/src")
clean_folder("SnowflakePlots.jl/test")
clean_folder("src")
clean_folder("test")
clean_folder("protobuf")

return covered_lines, total_lines
