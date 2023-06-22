# This script configures the SnowflurryBenchmarks Project to use the 
# Snowflurry Package located in the current path (pwd), 
# in development mode, in order to run the benchmarks on it.
# Must be called using:
# $ source benchmarking/setup.sh
# executing as a standalone shell script results in error.
julia --project=benchmarking -e 'using Pkg;
          Pkg.develop(PackageSpec(path=pwd())); 
          Pkg.instantiate();'
