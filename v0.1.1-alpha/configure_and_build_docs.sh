#!/bin/bash
# This script configures the Julia Project to use the 
# Snowflake Package located in the current path (pwd), 
# in development mode, then builds the documentation.
julia --project=docs -e 'using Pkg;
          Pkg.develop(PackageSpec(path=pwd())); 
          Pkg.instantiate();
          include("docs/make.jl")'
