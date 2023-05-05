#!/bin/bash
##################################################################
# Must be run as an executable shell script, (not using $ source).
#
# Call as:
#
# $ benchmarking/benchmarks.sh [OPTIONS]
#
##################################################################

Help()
{
   # Display Help
   echo "Run benchmarks on the Snowflake package and plot the results."
   echo
   echo "Syntax: benchmarking/benchmarks.sh [-a|s|l|v|h]"
   echo "options:"
   echo "--all|-a       Run benchmarks on all gates [Default]."
   echo "--single|-s    Run benchmarks in single target gates."
   echo "--label|-l     Following argument is appended to output filenames: -l \"_my_label\""
   echo "--verbose|-v   Verbose: prints command sent to Julia REPL."
   echo "--help|-h      Show this help."
   echo
}

sim_type="all"
LABEL=""
VERBOSE=false

while [ ! -z "$1" ]; do
  case "$1" in
      --help|-h) 
         Help
         exit 0;;
      --all|-a) 
         sim_type="all";;
      --single|-s) 
         sim_type="single";;
      --label|-l) 
         shift
         LABEL="$1";;
      --verbose|-v) 
         VERBOSE=true;;
      *) # Invalid option
         echo "Error: Unrecognized option: $1"
         exit 1;;
  esac
shift
done


case $sim_type in
   "all") 
      echo ""
      echo -n "Running benchmarks on all gates";;
   "single")
      echo ""
      echo -n "Running benchmarks on single-target gates";;
esac

COMMAND=""

if [ "$LABEL" = "" ]; then
   echo ""
   echo ""
else
   echo " using label: \"$LABEL\""
   echo ""
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

if $VERBOSE; then
   echo "Command sent to Julia REPL:"
   echo ""
   echo $COMMAND
   echo ""
fi

julia --project=benchmarking -e "$COMMAND";


