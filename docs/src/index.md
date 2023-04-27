# Snowflake.jl
```@meta
DocTestSetup = :(using Snowflake)
```
*A library for quantum computing using Julia*

Snowflake is a pure Julia quantum computing stack that allows you to easily design quantum circuits, experiments and algorithms. Snowflake can run these quantum applications on real quantum computers or classical simulators.

!!! warning
	Snowflake has yet to reach version 1.0, but we intend to keep compatibility with what is documented here. We will only make a breaking change if something is broken. After version 1.0, the public API will be stable and only change with major releases.

# Installation

The following installation steps are for people interested in using Snowflake in their own applications. If you are interested in helping to develop Snowflake, head right over to our [Developing Snowflake](./development.md) page.

### Installing Julia

Make sure your system has Julia installed. If not, download the latest version from [https://julialang.org/downloads/](https://julialang.org/downloads/).

We officially support the [latest stable release](https://julialang.org/downloads/#current_stable_release) and the [latest Long-term support release](https://julialang.org/downloads/#long_term_support_release). Any release in-between should work (please file a bug if they don't), but we only actively test against the LTS and the latest stable version.

### Installing the Snowflake package
Snowflake is still in pre-release phase. Therefore, and for the time being, we recommand installing it by checking out the `main` branch from github. This can be achieved by typing the following commands in the Julia REPL:

```julia
import Pkg
Pkg.add(url="https://github.com/anyonlabs/Snowflake.jl", rev="main")
```
This will add the Snowflake  package to the current [Julia Environment](https://pkgdocs.julialang.org/v1/environments/).

Once `Snowflake.jl` is released, you can install the latest release using the following command:
```julia
import Pkg
Pkg.add("Snowflake")
```

### Installing the SnowflakePlots package


Multiple visualization tools are available in the SnowflakePlots package. After installing
Snowflake, the SnowflakePlots package can be installed by entering the following in the
Julia REPL:
```julia
import Pkg
Pkg.add(url="https://github.com/anyonlabs/SnowflakePlots.jl", rev="main")
```

