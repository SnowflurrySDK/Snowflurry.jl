# Snowflake development

## Installing Snowflake for local development

When developing Snowflake, you must ensure that you are using a local copy of Snowflake, not the latest released version. The easiest way to achieve that is to set the project to the local directory.

If you are starting a new instance of Julia, then you can activate the Snowflake project with

```bash
julia --project=.
```

Or, if you are inside a script or interpreter, you can use

```julia
using Pkg
Pkg.activate(".")
```

If the current directory is not the Snowflake project, replace `.` with the Snowflake project path.


## Running tests

First open a julia REPL in the current project

```bash
julia --project=.
```

and run the tests

``julia
using Pkg
Pkg.test()
```

## Run coverage locally
If you haven't already, instantiate the project with Julia's package manager.
```bash
julia --project=. -e 'using Pkg; Pkg.Instantiate()'
``` .
You run coverage locally from the project directory using

```bash
julia --project=. coverage.jl
```

The script returns the covered and total line as output. An example output is shown below

```text
Covered lines: 1373
Total lines: 1383
Coverage percentage: 0.9927693420101229
```
