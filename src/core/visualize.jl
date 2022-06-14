using Parameters

function plot_histogram(circuit::QuantumCircuit, shots_count::Int)
    data = simulate_shots(circuit, shots_count)
    datamap = proportionmap(data)

    labels = String[]
    for (key, value) in datamap
        push!(labels, key)
    end

    Plots.bar(
        (x -> datamap[x]).(labels),
        xticks = (1:length(data), labels),
        legends = false,
        ylabel = "probabilities",
    )
end

function viz_wigner(ρ, x, y)
    return contour(x, y, (x,y) -> wigner(ρ, x, y), fill = true)
end

@with_kw struct BlochSphere
    num_points_per_horizontal_circle::Int = 50
    sphere_color = "#FFEEDD"
    sphere_blending_alpha = 0.4
end

function plot_unit_sphere(bloch_sphere = BlochSphere())
    plotly()
    (x, y, z) = get_unit_sphere_coordinates(bloch_sphere.num_points_per_horizontal_circle)
    surface(x, y, z, linewidth=0, color=bloch_sphere.sphere_color,
        alpha=bloch_sphere.sphere_blending_alpha)
end


function get_unit_sphere_coordinates(num_points_per_horizontal_circle)
    inclination = range(0, stop=π, length=num_points_per_horizontal_circle)
    azimuth = range(0, stop=2*π, length=num_points_per_horizontal_circle)
    x = sin.(inclination) * sin.(azimuth)'
    y = sin.(inclination) * cos.(azimuth)'
    z = cos.(inclination) * ones(num_points_per_horizontal_circle)'
    return (x, y, z)
end
