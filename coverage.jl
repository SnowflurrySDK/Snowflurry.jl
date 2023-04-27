using Coverage
using Pkg
using Snowflake

# Run tests with coverage
Pkg.test(coverage = true)

# process '*.cov' files
coverage = process_folder("src")

# process '*.info' files, if you collected them
coverage = merge_coverage_counts(
    coverage,
    LCOV.readfolder("test"),
)
LCOV.writefile("lcov.info", coverage)

# Get total coverage for all Julia files
covered_lines, total_lines = get_summary(coverage)

#clean .cov files
clean_folder("src")
clean_folder("test")

# Print summaru
println("Covered lines: $(covered_lines)")
println("Total lines: $(total_lines)")
println("Coverage percentage: $(covered_lines/total_lines)")
