module SnowflakePlots

using Snowflake
using Plots
using Parameters
using StatsBase

export

    # Types
    BlochSphere,
    AnimatedBlochSphere,

    # Functions
    viz_wigner,
    plot_histogram,
    plot_bloch_sphere,
    plot_bloch_sphere_animation

include("bloch_sphere.jl")
include("visualize.jl")

end # end module
