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
    num_points_per_line = 50
    sphere_color = "#FFEEDD"
    sphere_blending_alpha = 0.4
    frame_color = "black"
    frame_blending_alpha = 0.4
    window_height = 1200
    window_width = 800
    wire_color = "black"
    wire_blending_alpha = 0.2
    num_vertical_wires = 4
    num_horizontal_wires = 5
end

function plot_bloch_sphere(bloch_sphere = BlochSphere())
    plotlyjs()
    plot_unit_sphere(bloch_sphere)
    Base.invokelatest(gui)
end

function plot_unit_sphere(bloch_sphere)
    (x, y, z) = get_unit_sphere_coordinates(bloch_sphere.num_points_per_line)
    surface(x, y, z,
        color=bloch_sphere.sphere_color,
        alpha=bloch_sphere.sphere_blending_alpha,
        showaxis=false,
        size=(bloch_sphere.window_width, bloch_sphere.window_height),
        colorbar=false,
        framestyle=:none)
    plot_vertical_circular_wires(bloch_sphere)
    plot_horizontal_circular_wires(bloch_sphere)
end

function get_unit_sphere_coordinates(num_points_per_line)
    inclination = range(0, stop=π, length=num_points_per_line)
    azimuth = range(0, stop=2*π, length=num_points_per_line)
    x = sin.(inclination) * cos.(azimuth)'
    y = sin.(inclination) * sin.(azimuth)'
    z = cos.(inclination) * ones(num_points_per_line)'
    return (x, y, z)
end

function plot_vertical_circular_wires(bloch_sphere)
    inclination = range(0, stop=π, length=bloch_sphere.num_points_per_line)
    num_semi_circles = 2*bloch_sphere.num_vertical_wires
    for i in 1:num_semi_circles
        azimuth = 2*π*(i-1)/num_semi_circles
        x = sin.(inclination)*cos(azimuth)
        y = sin.(inclination)*sin(azimuth)
        z = cos.(inclination)
        path3d!(x, y, z,
            color=bloch_sphere.wire_color,
            alpha=bloch_sphere.wire_blending_alpha,
            legend=false)
    end
end

function plot_horizontal_circular_wires(bloch_sphere)
    azimuth = range(0, stop=2*π, length=bloch_sphere.num_points_per_line)
    num_circles = bloch_sphere.num_horizontal_wires
    for i in 1:num_circles
        inclination = π*i/(num_circles+1)
        x = sin(inclination)*cos.(azimuth)
        y = sin(inclination)*sin.(azimuth)
        z = cos(inclination)*ones(length(azimuth))
        path3d!(x, y, z,
            color=bloch_sphere.wire_color,
            alpha=bloch_sphere.wire_blending_alpha,
            legend=false)
    end
end
