# Getting Started

## Installation

The following installation steps are for people interested in using Snowflurry in their own applications. If you are interested in helping to develop Snowflurry, head right over to our [Developing Snowflurry](./development.md) page.

### Installing Julia

Make sure your system has Julia installed. If not, download the latest version from [https://julialang.org/downloads/](https://julialang.org/downloads/).

We officially support the [latest stable release](https://julialang.org/downloads/#current_stable_release) and the [latest Long-Term Support (LTS) release](https://julialang.org/downloads/#long_term_support_release). Any release in between should work (please submit a Github issue if they don't), but we only actively test against the LTS and the latest stable version.

### Installing the Snowflurry package

The latest release of Snowflurry can be pulled from [JuliaHub](https://juliahub.com/ui/Packages/General/Snowflurry) and installed with the following command:
```julia
import Pkg
Pkg.add("Snowflurry")
```

This adds the Snowflurry package to the current [Julia Environment](https://pkgdocs.julialang.org/v1/environments/).

Snowflurry is under active development. To use the development version, the `main` branch from Github can be installed instead using the following commands in the Julia REPL:

```julia
import Pkg
Pkg.add(url="https://github.com/SnowflurrySDK/Snowflurry.jl", rev="main")
```

!!! warning
    The main branch of Snowflurry targets new internal infrastructure. Existing users should use the latest stable release instead.

### Installing the SnowflurryPlots package

Multiple visualization tools are available in the SnowflurryPlots package. After installing
Snowflurry, the SnowflurryPlots package can be installed by entering the following in the
Julia REPL:
```julia
import Pkg
Pkg.add(url="https://github.com/SnowflurrySDK/SnowflurryPlots.jl", rev="main")
```

## Typical workflow

A typical workflow to execute a quantum circuit on a quantum service consists of these three steps:

- Create: Build the circuit using quantum gates.

- Transpile: Transform the circuit into an equivalent one, but with improved performance and guaranteed compatibility with the chosen quantum service.

- Execute: Run the compiled circuits on the specified quantum service. The quantum service could be a remote quantum hardware or a local simulator.


Now is the time to start with `Snowflurry` and go over the tutorials.
