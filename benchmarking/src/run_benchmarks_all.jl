using Dates

# this timestamp will propagate to all benchmarks output filenames
time_stamp=Dates.format(now(),"dd-mm-YYYY_HHhMM")

if @isdefined(ARGS) && length(ARGS)>0
    # pass a manual label to identify this benchmark run by defining 
    # ARGS="my_label" before including this script 
    manual_label=ARGS
    
    time_stamp=string(time_stamp,manual_label)
end

println("Launching benchmarks on all gates, label: $time_stamp")

const prefix_benchmark_result_file="benchmark_"

for file in readlines(joinpath(@__DIR__, "list_all_gates"))
    include(string(prefix_benchmark_result_file,file,".jl"))
end
