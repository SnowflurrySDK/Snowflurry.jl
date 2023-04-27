# Snowflake development

!!! warning
    This page is under construction 🚧

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
