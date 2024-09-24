# Snowflurry development

## Installing Snowflurry for local development

When developing Snowflurry, you must ensure that you are using a local copy of Snowflurry,
not the latest released version. The easiest way to achieve that is to set the project to
the local directory.

If you are starting a new instance of Julia, then you can activate the Snowflurry project
with

```bash
julia --project=.
```

or, if you are inside a script or REPL, you can use

```julia
using Pkg
Pkg.activate(".")
```

If the current directory is not the Snowflurry project, replace `.` with the Snowflurry
project path.


## Running tests

First open a Julia REPL in the current project

```bash
julia --project=.
```

and run the tests

```julia
using Pkg
Pkg.test()
```

## Build the documentation

Open a Julia REPL using the docs project:

```bash
julia --project=./docs
```

If it is your first time building the docs, you need to instantiate the Julia project and
add the Snowflurry project as a development dependency:

```julia
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()
```
In other words, Julia's package manager must add the version of Snowflurry which is located
in the current working directory, `pwd()`, not the one which is registered at JuliaHub.

At this point, the project status should be similar to the one below:

```julia
Pkg.status()

# output
      Status `<pwd()>/Snowflurry.jl/docs/Project.toml`
  [e30172f5] Documenter v0.27.24
  [cd3eb016] HTTP v1.7.4
  [682c06a0] JSON v0.21.4
  [7bd9edc1] Snowflurry v0.1.0 `<pwd()>/Snowflurry.jl`
  [90137ffa] StaticArrays v1.5.21
  [2913bbd2] StatsBase v0.33.21
  [de0858da] Printf
```
The versions might be slightly different, but what is important is that the `Status` line
refers to the `docs/Project.toml` and that `Snowflurry` refers to `<pwd()>/Snowflurry.jl`.

You can then run the following to build the documentation website:

```julia
include("./docs/make.jl")
```

## Determine the coverage locally

If you haven't already, instantiate the project with Julia's package manager:

```bash
julia --project=. -e 'using Pkg; Pkg.Instantiate()'
```

You can determine the coverage by executing the following command from the project
root directory:

```bash
julia --project=. coverage.jl
```

The script returns the number of covered and total lines. An example of the script's output
is shown below:

```text
Covered lines: 1373
Total lines: 1383
Coverage percentage: 0.9927693420101229
```
