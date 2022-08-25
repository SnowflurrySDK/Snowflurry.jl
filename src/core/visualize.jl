using Interpolations
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

"""
    BlochSphere

Contains fields which affect how a Bloch sphere is generated.
    
# Examples
```jldoctest
julia> ket = Ket(1/sqrt(2)*[1, 1]);

julia> print(ket)
2-element Ket:
0.7071067811865475 + 0.0im
0.7071067811865475 + 0.0im

julia> bloch_sphere = BlochSphere(vector_color="green");

```
```
julia> plot = plot_bloch_sphere(ket, bloch_sphere=bloch_sphere)

```
![Bloch sphere for ket](assets/visualize/plot_green_bloch_sphere.png)
"""
@with_kw struct BlochSphere
    num_points_per_line = 50
    sphere_color = "#FFEEDD"
    sphere_blending_alpha = 0.4
    frame_color = "black"
    frame_blending_alpha = 0.4
    window_height = 800
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
    relative_arrow_size = 0.25
    show_hover_info = false
    show_qubit_id = true
    camera_position = [1.25, 1.25, 0.4]
end

"""
    plot_bloch_sphere(circuit::QuantumCircuit;
        qubit_id::Int = 1,
        bloch_sphere::BlochSphere = BlochSphere())

Plots the Bloch sphere of qubit `qubit_id` for the `circuit`.
    
If the `circuit` contains multiple qubits, the Bloch sphere is constructed from the 1-qubit
reduced density matrix of qubit `qubit_id`. The appearance of the Bloch sphere can be
modified by passing a [`BlochSphere`](@ref) struct.
    
# Examples
```jldoctest
julia> circuit = QuantumCircuit(qubit_count=2, bit_count=0)
Quantum Circuit Object:
   id: c9ebdf08-f0ba-11ec-0c5e-8ff2bf2f3825 
   qubit_count: 2 
   bit_count: 0 
q[1]:
     
q[2]:


julia> push_gate!(circuit, [hadamard(1), sigma_x(2)])
Quantum Circuit Object:
   id: c9ebdf08-f0ba-11ec-0c5e-8ff2bf2f3825 
   qubit_count: 2 
   bit_count: 0 
q[1]:--H--
          
q[2]:--X--


```
```
julia> plot = plot_bloch_sphere(circuit, qubit_id=2)

```
![Bloch sphere for circuit](assets/visualize/plot_bloch_sphere_for_circuit.png)

The Bloch sphere can be saved to a file by calling:
```
julia> PlotlyJS.savefig(plot, "bloch_sphere.png", width=size(plot)[1],
                        height=size(plot)[2])

```
"""
function plot_bloch_sphere(circuit::QuantumCircuit;
    qubit_id::Int = 1,
    bloch_sphere::BlochSphere = BlochSphere())
    
    ket = simulate(circuit)
    return plot_bloch_sphere(ket2dm(ket), qubit_id=qubit_id, bloch_sphere=bloch_sphere)
end

"""
    plot_bloch_sphere(ket::Ket;
        qubit_id::Int = 1,
        bloch_sphere::BlochSphere = BlochSphere())

Plots the Bloch sphere of qubit `qubit_id` for the state represented by `ket`.
    
If `ket` is associated with multiple qubits, the Bloch sphere is constructed from the
1-qubit reduced density matrix of qubit `qubit_id`. The appearance of the Bloch sphere can
be modified by passing a [`BlochSphere`](@ref) struct.
    
# Examples
```jldoctest
julia> ket = Ket(1/sqrt(2)*[1, 1]);

julia> print(ket)
2-element Ket:
0.7071067811865475 + 0.0im
0.7071067811865475 + 0.0im

```
```
julia> plot = plot_bloch_sphere(ket)

```
![Bloch sphere for ket](assets/visualize/plot_bloch_sphere_for_ket.png)

The Bloch sphere can be saved to a file by calling:
```
julia> PlotlyJS.savefig(plot, "bloch_sphere.png", width=size(plot)[1],
                        height=size(plot)[2])

```
"""
function plot_bloch_sphere(ket::Ket;
    qubit_id::Int = 1,
    bloch_sphere::BlochSphere = BlochSphere())
    
    return plot_bloch_sphere(ket2dm(ket), qubit_id=qubit_id, bloch_sphere=bloch_sphere)
end

"""
    plot_bloch_sphere(density_matrix::Operator;
        qubit_id::Int = 1,
        bloch_sphere::BlochSphere = BlochSphere())

Plots the Bloch sphere of qubit `qubit_id` given the `density_matrix`.
    
If the `density_matrix` is associated with multiple qubits, the Bloch sphere is constructed
from the 1-qubit reduced density matrix of qubit `qubit_id`. The appearance of the Bloch
sphere can be modified by passing a [`BlochSphere`](@ref) struct.
    
# Examples
```jldoctest
julia> ρ = Operator([1.0 0.0;
                     0.0 0.0])
(2, 2)-element Snowflake.Operator:
Underlying data Matrix{Complex}:
1.0 + 0.0im    0.0 + 0.0im
0.0 + 0.0im    0.0 + 0.0im

```
```
julia> plot = plot_bloch_sphere(ρ)

```
![Bloch sphere for operator](assets/visualize/plot_bloch_sphere_for_operator.png)

The Bloch sphere can be saved to a file by calling:
```
julia> PlotlyJS.savefig(plot, "bloch_sphere.png", width=size(plot)[1],
                        height=size(plot)[2])

```
"""
function plot_bloch_sphere(density_matrix::Operator;
        qubit_id::Int = 1,
        bloch_sphere::BlochSphere = BlochSphere())

    num_qubits = get_num_qubits(density_matrix)
    system = MultiBodySystem(num_qubits, 2)
    plot = plot_unit_sphere(bloch_sphere, qubit_id)
    vector = get_bloch_sphere_vector(density_matrix, system, qubit_id)
    plot_bloch_sphere_vector!(plot, bloch_sphere, vector)
    return plot
end

function get_bloch_sphere_vector(density_matrix::Operator, system::MultiBodySystem,
        qubit_id)
    pauli_x = get_embed_operator(sigma_x(), qubit_id, system)
    x = Float64(tr(density_matrix*pauli_x))
    pauli_y = get_embed_operator(sigma_y(), qubit_id, system)
    y = Float64(tr(density_matrix*pauli_y))
    pauli_z = get_embed_operator(sigma_z(), qubit_id, system)
    z = Float64(tr(density_matrix*pauli_z))
    return [x, y, z]
end

function plot_unit_sphere(bloch_sphere, qubit_id)
    plot = plot_unit_sphere_surface(bloch_sphere, qubit_id)
    plot_vertical_circular_wires!(plot, bloch_sphere)
    plot_horizontal_circular_wires!(plot, bloch_sphere)
    plot_axes_lines!(plot, bloch_sphere)
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
        margin=attr(l=0,r=0,t=0,b=0),
        autosize=false,
        hovermode=bloch_sphere.show_hover_info,
        scene=attr(xaxis=attr(range=[-1.0, 1.1],
                showbackground=false,
                showaxeslabels=false,
                showline=false,
                showspikes=false,
                showticklabels=false,
                title=attr(text="")),
            yaxis=attr(range=[-1.0, 1.1],
                showbackground=false,
                showaxeslabels=false,
                showline=false,
                showspikes=false,
                showticklabels=false,
                title=attr(text="")),
            zaxis=attr(range=[-1.2, 1.5],
                showbackground=false,
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
            attr(x=0, y=0, z=1.2,
                text="|0⟩",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size)),
            attr(x=0, y=0, z=-1.2,
                text="|1⟩",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size)),
            attr(x=0, y=0, z=1.5,
                text=bloch_sphere.show_qubit_id ? "Qubit $qubit_id" : "",
                showarrow=false,
                font=attr(size=bloch_sphere.annotations_size))],
        camera=attr(eye=attr(x=bloch_sphere.camera_position[1],
                y=bloch_sphere.camera_position[2],
                z=bloch_sphere.camera_position[3]))))
        return PlotlyJS.plot(sphere_surface, layout)
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
        add_trace!(plot, trace)
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
        add_trace!(plot, trace)
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
    add_trace!(plot, x_trace)
    add_trace!(plot, y_trace)
    add_trace!(plot, z_trace)
end

function plot_bloch_sphere_vector!(plot, bloch_sphere, coordinates)
    (line_trace, cone_trace) = get_bloch_sphere_vector_traces(bloch_sphere, coordinates)
    add_trace!(plot, line_trace)
    add_trace!(plot, cone_trace)
end

function get_bloch_sphere_vector_traces(bloch_sphere, coordinates)
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
    return(line_trace, cone_trace)
end

"""
    AnimatedBlochSphere

Contains fields which affect how a Bloch sphere animation is generated.
    
# Examples
By default, additional Bloch sphere vectors are generated between each state using
interpolation. The number of additional vectors can be changed by passing a value for the
keyword `num_interpolated_points`.
```
julia> ket_list = [Ket([1, 0]), Ket(1/sqrt(2)*[1, 1])];

julia> animated_sphere = AnimatedBlochSphere(num_interpolated_points=0,
        history_line_color="transparent", frame_duration=1000);

julia> plot = plot_bloch_sphere_animation(ket_list, animated_bloch_sphere=animated_sphere)

```

"""
@with_kw struct AnimatedBlochSphere
    bloch_sphere = BlochSphere()
    frame_duration = 30
    num_interpolated_points = 20
    history_line_color = "purple"
    history_line_width = 8.0
    history_line_opacity = 0.3
end

"""
    plot_bloch_sphere_animation(ket_list::Vector{Ket};
        qubit_id::Int = 1,
        animated_bloch_sphere::AnimatedBlochSphere = AnimatedBlochSphere())

Plots a Bloch sphere animation of qubit `qubit_id` for the states listed in `ket_list`.
    
If `ket_list` is associated with multiple qubits, the Bloch sphere animation is constructed
from the 1-qubit reduced density matrices of qubit `qubit_id`. Animation settings and the
appearance of the Bloch sphere can be modified by passing an [`AnimatedBlochSphere`](@ref)
struct.
    
# Examples
```
julia> ket_list = [Ket([1, 0]), Ket(1/sqrt(2)*[1, 1])];

julia> plot = plot_bloch_sphere_animation(ket_list)

```

The Bloch sphere animation can be saved to an html file by calling:
```
julia> PlotlyJS.savefig(plot, "bloch_sphere_animation.html")

```
"""
function plot_bloch_sphere_animation(ket_list::Vector{Ket};
    qubit_id::Int = 1,
    animated_bloch_sphere::AnimatedBlochSphere = AnimatedBlochSphere())

    return plot_bloch_sphere_animation(ket2dm.(ket_list), qubit_id=qubit_id,
        animated_bloch_sphere=animated_bloch_sphere)
end

"""
    plot_bloch_sphere_animation(density_matrix_list::Vector{Operator};
        qubit_id::Int = 1,
        animated_bloch_sphere::AnimatedBlochSphere = AnimatedBlochSphere())

Plots a Bloch sphere animation of qubit `qubit_id` for the states listed in
`density_matrix_list`.
    
If `density_matrix_list` is associated with multiple qubits, the Bloch sphere animation is
constructed from the 1-qubit reduced density matrices of qubit `qubit_id`. Animation
settings and the appearance of the Bloch sphere can be modified by passing an
[`AnimatedBlochSphere`](@ref) struct.
    
# Examples
```
julia> ψ_0 = Operator([0.5 0.5; 0.5 0.5]);

julia> ψ_1 = Operator([0.5 -0.5im; 0.5im 0.5]);

julia> plot = plot_bloch_sphere_animation([ψ_0, ψ_1])

```

The Bloch sphere animation can be saved to an html file by calling:
```
julia> PlotlyJS.savefig(plot, "bloch_sphere_animation.html")

```
"""
function plot_bloch_sphere_animation(density_matrix_list::Vector{Operator};
    qubit_id::Int = 1,
    animated_bloch_sphere::AnimatedBlochSphere = AnimatedBlochSphere())
    
    plot = plot_bloch_sphere(density_matrix_list[1], qubit_id=qubit_id,
        bloch_sphere=animated_bloch_sphere.bloch_sphere)
    empty_history_line = get_bloch_sphere_history_line(([nothing], [nothing], [nothing]), 1,
        animated_bloch_sphere)
    add_trace!(plot, empty_history_line)
    traces = deepcopy(plot.plot.data)
    layout = deepcopy(plot.plot.layout)
    frames = get_bloch_sphere_frames(traces, density_matrix_list, qubit_id,
        animated_bloch_sphere)
    add_animation_controls!(layout, frames, animated_bloch_sphere)
    animated_plot = PlotlyJS.Plot(traces, layout, frames)
    return animated_plot
end

function get_bloch_sphere_frames(traces, density_matrix_list, qubit_id,
        animated_bloch_sphere)
    (x, y, z) = get_interpolated_bloch_sphere_coordinates(
        density_matrix_list, qubit_id, animated_bloch_sphere)
    num_frames = length(x)
    num_traces = length(traces)
    frames = Vector{PlotlyFrame}(undef, num_frames)
    for i in 1:num_frames
        vector = [x[i], y[i], z[i]]
        (line_trace, cone_trace) =
            get_bloch_sphere_vector_traces(animated_bloch_sphere.bloch_sphere, vector)
        history_trace = get_bloch_sphere_history_line((x, y, z), i, animated_bloch_sphere)
        single_frame = PlotlyJS.frame(data=[line_trace, cone_trace, history_trace],
            name="frame_$i",
            traces=[num_traces-3, num_traces-2, num_traces-1])
        frames[i] = single_frame
    end
    return frames
end

function get_bloch_sphere_history_line(coordinates, frame_id, animated_bloch_sphere)
    x = coordinates[1][1:frame_id]
    y = coordinates[2][1:frame_id]
    z = coordinates[3][1:frame_id]
    line_trace = PlotlyJS.scatter3d(x=x, y=y, z=z,
        mode="lines",
        line=attr(color=animated_bloch_sphere.history_line_color,
            width=animated_bloch_sphere.history_line_width),
            opacity=animated_bloch_sphere.history_line_opacity,
            showlegend=false)
    return line_trace
end

function get_interpolated_bloch_sphere_coordinates(density_matrix_list, qubit_id,
    animated_bloch_sphere)

    (r, inclination, azimuth) =
        get_spherical_coordinates_list(density_matrix_list, qubit_id)

    input_parameters = 0:1
    num_interpolation_parameters = animated_bloch_sphere.num_interpolated_points+2
    interpolation_parameters = range(0, 1, length=num_interpolation_parameters)
    scaled_r = []
    scaled_inclination = []
    scaled_azimuth = []
    for i in 1:length(r)-1
        parameterized_r = r[i] .+ input_parameters.*(r[i+1]-r[i])
        parameterized_inclination =
            inclination[i] .+ input_parameters.*(inclination[i+1]-inclination[i])
        parameterized_azimuth = azimuth[i] .+ input_parameters.*(azimuth[i+1]-azimuth[i])
        parameterized_coordinates = hcat(parameterized_r, parameterized_inclination,
            parameterized_azimuth)

        grid_type = OnGrid()
        boundary_condition = Natural(grid_type)
        degree = Cubic(boundary_condition)
        mode = BSpline(degree)
        interpolation = interpolate(parameterized_coordinates, (mode, NoInterp()))
        scaling = Interpolations.scale(interpolation, input_parameters, 1:3)
        
        new_scaled_r = [scaling(parameter,1) for parameter in interpolation_parameters]
        new_scaled_inclination =
            [scaling(parameter,2) for parameter in interpolation_parameters]
        new_scaled_azimuth =
            [scaling(parameter,3) for parameter in interpolation_parameters]

        append!(scaled_r, deleteat!(new_scaled_r, num_interpolation_parameters))
        append!(scaled_inclination,
            deleteat!(new_scaled_inclination, num_interpolation_parameters))
        append!(scaled_azimuth, deleteat!(new_scaled_azimuth, num_interpolation_parameters))
    end
    push!(scaled_r, last(r))
    push!(scaled_inclination, last(inclination))
    push!(scaled_azimuth, last(azimuth))

    interpolated_x = scaled_r.*sin.(scaled_inclination).*cos.(scaled_azimuth)
    interpolated_y = scaled_r.*sin.(scaled_inclination).*sin.(scaled_azimuth)
    interpolated_z = scaled_r.*cos.(scaled_inclination)
    
    return (interpolated_x, interpolated_y, interpolated_z)
end

function get_spherical_coordinates_list(density_matrix_list, qubit_id)
    x = Vector(undef, length(density_matrix_list))
    y = Vector(undef, length(density_matrix_list))
    z = Vector(undef, length(density_matrix_list))
    num_qubits = get_num_qubits(density_matrix_list[1])
    system = MultiBodySystem(num_qubits, 2)
    for (i, density_matrix) in enumerate(density_matrix_list)
        (x[i], y[i], z[i]) = get_bloch_sphere_vector(density_matrix, system, qubit_id)
    end
    r = sqrt.(x.^2+y.^2+z.^2)
    inclination = acos.(z./r)
    azimuth = atan.(y, x)

    for i in 1:length(azimuth)-1
        if (azimuth[i+1]-azimuth[i]) < -π
            azimuth[i+1] += 2*π
        elseif (azimuth[i+1]-azimuth[i]) > π
            azimuth[i+1] -= 2*π
        end
    end

    return (r, inclination, azimuth)
end

function add_animation_controls!(layout, frames, animated_bloch_sphere)
    steps = []
    for i in 1:length(frames)
        single_step = attr(method="animate",
            args=[["frame_$i"],
                attr(mode="immediate",
                    frame=attr(duration=animated_bloch_sphere.frame_duration,
                        redraw=true),
                    transition=attr(duration=0))],
                    label="")
        push!(steps, single_step)
    end
    sliders = [attr(steps=steps,
        transition=attr(duration=0),
        x=0,
        y=0,
        pad=attr(l=130, t=55),
        tickcolor="transparent")]
    buttons = [attr(x=0,
            y=0,
            yanchor="top",
            xanchor="left",
            showactive=false,
            direction="left",
            type="buttons",
            pad=attr(t=55, r=10),
            buttons=[attr(method="animate",
                args=[nothing,
                    attr(mode="immediate",
                        fromcurrent=true,
                        transition=attr(duration=0),
                        frame=attr(duration=animated_bloch_sphere.frame_duration,
                            redraw=true))],
                label="Play"),
            attr(method="animate",
                args=[[nothing],
                    attr(mode="immediate",
                        transition=attr(duration=0),
                        frame=attr(duration=0,
                            redraw=true))],
                    label="Pause")])]
    relayout!(layout, sliders=sliders, updatemenus=buttons)
end
