using Parameters
using PlotlyJS

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
    return Plots.contour(x, y, (x,y) -> wigner(ρ, x, y), fill = true)
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
    wires_width = 1.0
    axes_color = "black"
    axes_blending_alpha = 0.8
    axes_line_width = 2.0
    annotations_size = 35
    title = "Qubit"
end

function plot_bloch_sphere(bloch_sphere = BlochSphere())
    plot_unit_sphere(bloch_sphere)
end

function plot_unit_sphere(bloch_sphere)
    plot = plot_unit_sphere_surface(bloch_sphere)
    plot = plot_vertical_circular_wires(bloch_sphere, plot)
    plot = plot_horizontal_circular_wires(bloch_sphere, plot)
    plot = plot_axes_lines(bloch_sphere, plot)
end

function plot_unit_sphere_surface(bloch_sphere)
    inclination = range(0, stop=π, length=bloch_sphere.num_points_per_line)
    azimuth = range(0, stop=2*π, length=bloch_sphere.num_points_per_line)
    x = sin.(inclination) * cos.(azimuth)'
    y = sin.(inclination) * sin.(azimuth)'
    z = cos.(inclination) * ones(bloch_sphere.num_points_per_line)'
    color_scale = [[0, bloch_sphere.sphere_color],
        [1, bloch_sphere.sphere_color]]
    surface_color = zeros(size(z))
    sphere_surface = PlotlyJS.surface(x=x, y=y, z=z,
        surfacecolor=surface_color,
        colorscale=color_scale,
        cmin=0,
        cmax=1,
        opacity=bloch_sphere.sphere_blending_alpha,
        showscale=false)
    layout = Layout(width=bloch_sphere.window_width,
        height=bloch_sphere.window_height,
        autosize=false,
        scene=attr(xaxis=attr(showbackground=false,
                showaxeslabels=false,
                showline=false,
                showspikes=false,
                showticklabels=false,
                title=attr(text="")),
            yaxis=attr(showbackground=false,
                showaxeslabels=false,
                showline=false,
                showspikes=false,
                showticklabels=false,
                title=attr(text="")),
            zaxis=attr(showbackground=false,
                showaxeslabels=false,
                showline=false,
                showspikes=false,
                showticklabels=false,
                title=attr(text="")),
        annotations=[attr(x=1.1, y=0, z=0,
                text="x",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size)),
            attr(x=0, y=1.1, z=0,
                text="y",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size)),
            attr(x=0, y=0, z=1.1,
                text="|0⟩",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size)),
            attr(x=0, y=0, z=-1.1,
                text="|1⟩",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size)),
            attr(x=0, y=0, z=1.4,
                text=bloch_sphere.title,
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size))]))
        return PlotlyJS.Plot(sphere_surface, layout)
end

function plot_vertical_circular_wires(bloch_sphere, plot)
    inclination = range(0, stop=π, length=bloch_sphere.num_points_per_line)
    num_semi_circles = 2*bloch_sphere.num_vertical_wires
    for i in 1:num_semi_circles
        azimuth = 2*π*(i-1)/num_semi_circles
        x = sin.(inclination)*cos(azimuth)
        y = sin.(inclination)*sin(azimuth)
        z = cos.(inclination)
        trace = PlotlyJS.scatter3d(x=x, y=y, z=z,
            mode="lines",
            opacity=bloch_sphere.wire_blending_alpha,
            line=attr(color=bloch_sphere.wire_color,
                width=bloch_sphere.wires_width),
            showlegend=false)
        push!(plot.data, trace)
    end
    return plot
end

function plot_horizontal_circular_wires(bloch_sphere, plot)
    azimuth = range(0, stop=2*π, length=bloch_sphere.num_points_per_line)
    num_circles = bloch_sphere.num_horizontal_wires
    for i in 1:num_circles
        inclination = π*i/(num_circles+1)
        x = sin(inclination)*cos.(azimuth)
        y = sin(inclination)*sin.(azimuth)
        z = cos(inclination)*ones(length(azimuth))
        trace = PlotlyJS.scatter3d(x=x, y=y, z=z,
            mode="lines",
            opacity=bloch_sphere.wire_blending_alpha,
            line=attr(color=bloch_sphere.wire_color,
                width=bloch_sphere.wires_width),
            showlegend=false)
        push!(plot.data, trace)
    end
    return plot
end

function plot_axes_lines(bloch_sphere, plot)
    axes_points = range(-1, 1, length=bloch_sphere.num_points_per_line)
    zeros_points = zeros(bloch_sphere.num_points_per_line)
    x_trace = PlotlyJS.scatter3d(x=axes_points, y=zeros_points, z=zeros_points,
        mode="lines",
        opacity=bloch_sphere.axes_blending_alpha,
        line=attr(color=bloch_sphere.axes_color,
        width=bloch_sphere.axes_line_width),
        showlegend=false)
    y_trace = PlotlyJS.scatter3d(x=zeros_points, y=axes_points, z=zeros_points,
        mode="lines",
        opacity=bloch_sphere.axes_blending_alpha,
        line=attr(color=bloch_sphere.axes_color,
        width=bloch_sphere.axes_line_width),
        showlegend=false)
    z_trace = PlotlyJS.scatter3d(x=zeros_points, y=zeros_points, z=axes_points,
        mode="lines",
        opacity=bloch_sphere.axes_blending_alpha,
        line=attr(color=bloch_sphere.axes_color,
        width=bloch_sphere.axes_line_width),
        showlegend=false)
    push!(plot.data, x_trace, y_trace, z_trace)
    return plot
end
