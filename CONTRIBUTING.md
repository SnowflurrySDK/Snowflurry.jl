# How to Contribute

Snowflurry is a community driven project and we'd love to accept your patches and
contributions to this project.

To streamline the process, we have some guidelines to follow. Please also
note that we have a [code of conduct](CODE_OF_CONDUCT.md) to make Snowflurry an
open and welcoming environment.

## Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution;
this simply gives us permission to use and redistribute your contributions as
part of the project.

## Pull Request Process and Code Review

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose.
[GitHub Help](https://help.github.com/articles/about-pull-requests/) has
information on using pull requests.

The preferred manner for submitting pull requests is for users to fork
the Snowflurry [repository](https://github.com/SnowflurrySDK/Snowflurry.jl) and then use a
branch from this fork to create a pull request to the main Snowflurry repository.

The basic process for setting up a fork is

1.  Fork the Snowflurry repository (Fork button in upper right corner of
    [repository page](https://github.com/SnowflurrySDK/Snowflurry.jl)).
    Forking creates a new Github repository at the location
    `https://github.com/USERNAME/Snowflurry.jl` where `USERNAME` is
    your Github id. Use the directions on the
    [development page](docs/src/development.md) to download a copy to
    your local machine. You need only do this once.
1.  Checkout master and create a new branch from this master
    ```shell
    git checkout master -b new_branch_name
    ```
    where `new_branch_name` is the name of your new branch.
1.  Do your work and commit your changes to this branch.
1.  If you have drifted out of sync with the master from the
    main Snowflurry repository, you may need to merge in changes. To do this,
    first update your local master and then merge the local master
    into your branch:

    ```shell 
    # Track the upstream repository (if your local repository hasn't):
    git remote add upstream https://github.com/SnowflurrySDK/Snowflurry.jl.git

    # Update your local master.
    git fetch upstream
    git checkout master
    git merge upstream/master
    # Merge local master into your branch.
    git checkout new_branch_name
    git merge master
    
    #You may need to fix merge conflicts for both of these merge commands.
    ```

1.  Finally, push your change to your clone
    ```shell
    git push origin new_branch_name
    ```
1.  Now, when you navigate to the
    [Snowflurry page on GitHub](https://github.com/SnowflurrySDK/Snowflurry.jl),
    you should see the option to create a new pull request from
    your cloned repository. Alternatively, you can create the pull request
    by navigating to the "Pull requests" tab in the page, and selecting
    the appropriate branches.
1.  The reviewer will comment on your code and may ask for changes.
    You can perform these changes locally and push the new commits following
    the same process as above.

## Julia Coding Style Guide

We adhere to the recommended Julia
[Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/). Please consult this
document before getting started!

## Code Testing Standards

When a pull request is created or updated, various automatic checks will
run to ensure that the changes won't break Snowflurry and meet our coding standards.

Snowflurry contains a continuous integration tool to verify testing. See our
[development page](docs/src/development.md) to learn how to run the continuous
integration checks locally.

Please be aware that all changes have to meet the following coding standards.

- **Tests**.
  Existing tests must continue to pass (or be updated) when new changes are
  introduced. There are two ways to run the unit tests:

1. Use `Pkg.test` by typing the following in the REPL:

```julia
julia>using Pkg; Pkg.test("Snowflurry"; coverage=true)
```

2. Run `test/runtests.jl` by including the `test/runtests.jl` script in the REPL:

```julia
julia> include("test/runtests.jl")
Test Summary: | Pass  Total
ket           |    7      7
Test Summary: | Pass  Total
multi_body    |    1      1
Test Summary: | Pass  Total
cnot          |    1      1
Test Summary:  | Pass  Total
phase_kickback |    1      1
```

- **Coverage**.
  Code should be covered by tests.
  We use [Coverage.jl](https://github.com/JuliaCI/Coverage.jl) to compute
  coverage. We don't require 100% coverage, but expect better than 80% code coverage.
- **Formatting**.
  We require the use of [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl)
  for formatting. The files in Snowflurry can be formatted by entering the following in the
  REPL from the Snowflurry root directory:

```julia
julia> using JuliaFormatter

julia> format(".");

```

