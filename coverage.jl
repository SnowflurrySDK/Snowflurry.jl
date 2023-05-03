using Coverage
using Pkg
using Snowflake

function print_missed_lines(fcs::Vector{FileCoverage})
    for fc in fcs
        print_missed_lines(fc)
    end
end

function print_missed_lines(fc::FileCoverage;num_char_to_print::Integer=100)

    coverage=fc.coverage

    a = open("$(fc.filename)", "r")
    lines = readlines(a)

    for (i,counts) in enumerate(coverage)
        if counts==0
            print("File: $(fc.filename), \tline number: ")
            printstyled("$(i)",color=:red)
            printstyled(" : $(
                lines[i][1:minimum([num_char_to_print,length(lines[i])])])\n",
                color=:cyan)
        end
    end
end

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

if ~(isapprox(covered_lines/total_lines,1.0))
    println("\n\tDetailed results, missed lines: \n")

    print_missed_lines(coverage)
end