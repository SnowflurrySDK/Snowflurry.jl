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
    vector_color = "purple"
    vector_width = 15.0
    relative_arrow_size = 0.2
    show_hover_info = false
end

function plot_bloch_sphere(bloch_sphere = BlochSphere())
    plot_unit_sphere(bloch_sphere, [cos(3*π/4)*sin(π/4), sin(3*π/4)*sin(π/4), cos(π/4)], 0)
end

function plot_unit_sphere(bloch_sphere, coordinates, qubit_id)
    plot = plot_unit_sphere_surface(bloch_sphere, qubit_id)
    plot_vertical_circular_wires!(plot, bloch_sphere)
    plot_horizontal_circular_wires!(plot, bloch_sphere)
    plot_axes_lines!(plot, bloch_sphere)
    plot_vector!(plot, bloch_sphere, coordinates)
    return plot
end

function plot_unit_sphere_surface(bloch_sphere, qubit_id)
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
        showscale=false,
        contours=attr(x=attr(highlight=false),
        y=attr(highlight=false),
        z=attr(highlight=false)))
    layout = Layout(width=bloch_sphere.window_width,
        height=bloch_sphere.window_height,
        autosize=false,
        hovermode=bloch_sphere.show_hover_info,
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
                text="Qubit $qubit_id",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size))]))
        return PlotlyJS.Plot(sphere_surface, layout)
end

function plot_vertical_circular_wires!(plot, bloch_sphere)
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
end

function plot_horizontal_circular_wires!(plot, bloch_sphere)
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
end

function plot_axes_lines!(plot, bloch_sphere)
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
end

function plot_vector!(plot, bloch_sphere, coordinates)
    line_end_coordinates = (1-bloch_sphere.relative_arrow_size)*coordinates
    line_trace = PlotlyJS.scatter3d(x=[0, line_end_coordinates[1]],
        y=[0, line_end_coordinates[2]],
        z=[0, line_end_coordinates[3]],
        mode="lines",
        line=attr(color=bloch_sphere.vector_color,
            width=bloch_sphere.vector_width),
            showlegend=false)
    cone_trace = PlotlyJS.cone(x=[coordinates[1]],
        y=[coordinates[2]],
        z=[coordinates[3]],
        u=[coordinates[1]],
        v=[coordinates[2]],
        w=[coordinates[3]],
        sizeref=bloch_sphere.relative_arrow_size,
        anchor="tip",
        colorscale = [[0, bloch_sphere.vector_color], [1, bloch_sphere.vector_color]],
        showscale = false)
    push!(plot.data, line_trace, cone_trace)
end
