#!/bin/bash
Help()
{
   # Display Help
   echo "Configure and run benchmarks on the Snowflake package."
   echo
   echo "Syntax: test [-a|s|l]"
   echo "options:"
   echo "a     run benchmarks on all gates [Default]."
   echo "s     Run benchmarks in single target gates."
   echo "l     appends LABEL string to output files."
   echo "h     Show this help."
   echo
}

sim_type="all"
LABEL=""

while getopts ":hasl:" option; do
   case $option in
      h) # display Help
         Help
         return 0;;
      a) # run all
         sim_type="all";;
      s) 
         sim_type="single";;
      l) 
         LABEL=$OPTARG;;
     \?) # Invalid option
         echo "Error: Unrecognized option"
         exit 1;;
   esac
done


case $sim_type in
   "all") 
      echo ""
      echo -n "Running benchmarks on all gates";;
   "single")
      echo ""
      echo -n "Running benchmarks on single target gates";;
esac

if [ "$LABEL" = "" ]; then
   echo ""
   echo ""
else
   echo " using label: \"$LABEL\""
   echo ""
fi

COMMAND='using Pkg;
          Pkg.develop(PackageSpec(path=pwd())); 
          Pkg.instantiate();'

if [ "$LABEL" != "" ]; then
   COMMAND="${COMMAND} ARGS=\"${LABEL}\";"
fi

case $sim_type in
   "all") 
      COMMAND="${COMMAND} include(\"benchmarking/src/run_benchmarks_all.jl\");
          include(\"benchmarking/src/plot.jl\");";;
   "single") 
      COMMAND="${COMMAND} include(\"benchmarking/src/run_benchmarks_single_target.jl\");
          include(\"benchmarking/src/plot.jl\");";;
esac

echo $COMMAND
echo ""

julia --project=benchmarking -e "$COMMAND";


