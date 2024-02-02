
abstract type AbstractConnectivity end


"""
    LineConnectivity <:AbstractConnectivity

A data structure to represent linear qubit connectivity in an Anyon System's QPU.  
This connectivity type is encountered in `QPUs` such as the [`AnyonYukonQPU`](@ref)

# Fields
- `dimension                  ::Int` -- Qubit count in this connectivity.


# Example
```jldoctest
julia> connectivity = LineConnectivity(6)
LineConnectivity{6}
1──2──3──4──5──6

```
"""
struct LineConnectivity <: AbstractConnectivity
    dimension::Int
end

"""
    LatticeConnectivity <:AbstractConnectivity

A data structure to represent 2D-lattice qubit connectivity in an Anyon System's QPU.  
This connectivity type is encountered in `QPUs` such as the [`AnyonYamaskaQPU`](@ref)

# Fields
- `qubits_per_row    ::Vector{Int}` -- number of qubits in each line, when constructing the printout.
- `dimensions        ::Vector{Int}` -- number of rows and columns (turned 45° in the printout).


# Example
The following lattice has 4 rows, made of qubits 
`[2, 6, 10]`, `[1, 5, 9]`, `[4, 8, 12]` and `[3, 7, 11]`, with each of those rows having 3 columns.

The corresponding `qubits_per_row` field is `[2, 4, 4, 2]`, the number of qubits in each line
in the printed representation.  

```jldoctest
julia> connectivity = LatticeConnectivity(3, 4)
LatticeConnectivity{3,4}
  5 ──  1
  |     |
  9 ──  6 ──  2
        |     |
       10 ──  7 ──  3
              |     |
             11 ──  8 ──  4
                    |
                   12 

```

Lattices of arbitrary dimensions can be built:
```jldoctest
julia> connectivity = LatticeConnectivity(6, 4)
LatticeConnectivity{6,4}
              5 ──  1
              |     |
       13 ──  9 ──  6 ──  2
        |     |     |     |
 21 ── 17 ── 14 ── 10 ──  7 ──  3
        |     |     |     |     |
       22 ── 18 ── 15 ── 11 ──  8 ──  4
              |     |     |     |
             23 ── 19 ── 16 ── 12
                    |     |
                   24 ── 20 

```
"""
struct LatticeConnectivity <: AbstractConnectivity
    qubits_per_row::Vector{Int}
    dimensions::Tuple{Int,Int}

    function LatticeConnectivity(nrows::Int, ncols::Int)

        @assert nrows >= 2 "nrows must be at least 2"
        @assert ncols >= 2 "ncols must be at least 2"

        qubit_count = nrows * ncols
        placing_queue = [nrows for _ = 1:ncols]
        qubits_per_row = Vector{Int}()

        cursor = 0
        while !all(map(x -> x == 0, placing_queue))
            cursor += 1
            row_count = 0
            for pos = 1:minimum([cursor, ncols])
                increment = minimum([2, placing_queue[pos]])
                row_count += increment
                placing_queue[pos] -= increment
            end

            push!(qubits_per_row, row_count)
        end

        @assert +(qubits_per_row...) == qubit_count "Failed to build lattice"

        new(qubits_per_row, (nrows, ncols))
    end

    function LatticeConnectivity(qubits_per_row::Vector{Int})
        nrows = maximum(qubits_per_row)
        ncols = ceil(+(qubits_per_row...) / nrows)

        new(qubits_per_row, (nrows, ncols))
    end
end

function Base.show(io::IO, connectivity::LatticeConnectivity)
    println(
        io,
        "$(typeof(connectivity)){$(connectivity.dimensions[1]),$(connectivity.dimensions[2])}",
    )
    print_connectivity(connectivity, Vector{Int}(), io)
end

function Base.show(io::IO, connectivity::LineConnectivity)
    println(io, "$(typeof(connectivity)){$(connectivity.dimension)}")
    print_connectivity(connectivity, Vector{Int}(), io)
end

get_connectivity_label(connectivity::AbstractConnectivity) =
    throw(NotImplementedError(:get_connectivity_label, connectivity))

"""
    AllToAllConnectivity <:AbstractConnectivity

A data structure to represent all-to-all qubit connectivity in an Anyon System's QPU.  
This connectivity type is encountered in simulated `QPUs`, such as the [`VirtualQPU`](@ref)

# Example
```jldoctest
julia> connectivity = AllToAllConnectivity()
AllToAllConnectivity()

```
"""
struct AllToAllConnectivity <: AbstractConnectivity end

const line_connectivity_label = "linear"
const lattice_connectivity_label = "2D-lattice"
const all2all_connectivity_label = "all-to-all"

get_connectivity_label(::LineConnectivity) = line_connectivity_label
get_connectivity_label(::LatticeConnectivity) = lattice_connectivity_label

get_num_qubits(conn::LineConnectivity) = *(conn.dimension...)
get_num_qubits(conn::LatticeConnectivity) = +(conn.qubits_per_row...)

print_connectivity(connectivity::AbstractConnectivity, args...) =
    throw(NotImplementedError(:print_connectivity, connectivity))

print_connectivity(connectivity::AllToAllConnectivity, ::Vector{Int}, io::IO = stdout) =
    println(io, connectivity)

function print_connectivity(connectivity::LineConnectivity, ::Vector{Int}, io::IO = stdout)
    dim = connectivity.dimension

    diagram = [string(n) * "──" for n = 1:dim-1]
    push!(diagram, string(dim))

    output_str = *(diagram...)

    println(io, output_str)
end

function assign_qubit_numbering(
    qubits_per_row::Vector{Int},
    qubit_count_per_readout_line::Int,
)::Vector{Vector{Int}}
    qubit_count = sum(qubits_per_row)

    #input should not be altered
    placing_queue = copy(qubits_per_row)

    row_count = length(qubits_per_row)

    qubit_numbering = Vector{Vector{Int}}([[] for _ = 1:length(qubits_per_row)])

    row_cursor = 0
    current_qubit_num = 0
    completed_rows = 0
    while !all(map(x -> x == 0, placing_queue))

        if row_cursor == row_count
            row_cursor = completed_rows
        end

        row_cursor += 1

        # placement on the following readout line can only start after the current one is completed
        if row_cursor - ((current_qubit_num) % qubit_count_per_readout_line) >
           qubit_count_per_readout_line &&
           length(qubit_numbering[row_cursor]) <
           (current_qubit_num + 1) % qubit_count_per_readout_line

            row_cursor = completed_rows + 1
        end

        current_qubit_num += 1
        push!(qubit_numbering[row_cursor], current_qubit_num)
        placing_queue[row_cursor] -= 1

        if placing_queue[row_cursor] == 0
            completed_rows += 1
        end

        @assert current_qubit_num ≤ qubit_count "failed to map qubit numbering"
    end

    return [reverse(row) for row in qubit_numbering]
end

function print_connectivity(
    connectivity::LatticeConnectivity,
    path::Vector{Int} = Vector{Int}(), # path of qubits to highlight in printout
    io::IO = stdout,
)
    qubits_per_row = connectivity.qubits_per_row

    (offsets, offsets_vertical_lines, num_vertical_lines) =
        get_lattice_offsets(connectivity)

    max_symbol_length = length(string(get_num_qubits(connectivity)))

    qubit_number_per_row = assign_qubit_numbering(qubits_per_row, connectivity.dimensions[2])

    for (irow, qubit_count) in enumerate(qubits_per_row)
        line_printout = format_qubit_line(
            qubit_count,
            qubit_number_per_row[irow],
            max_symbol_length,
            offsets[irow],
        )

        if !isempty(path)
            qubits_in_row = qubit_number_per_row[irow]

            for qubit in qubits_in_row
                qubit_s = string(qubit)
                if qubit in path && occursin(qubit_s, line_printout)
                    line_printout =
                        replace(line_printout, " " * qubit_s * " " => "(" * qubit_s * ")")
                end
            end
        end

        println(io, line_printout)

        vertical_lines = format_vertical_connections(
            num_vertical_lines[irow],
            max_symbol_length,
            offsets[irow] + offsets_vertical_lines[irow],
        )

        println(io, vertical_lines)

    end
end

connect_symbol = "──"
len_connect_sym = length(connect_symbol)

function create_str_template(ncols::Int, left_padding::Vector{String})
    # create string template for ncols: 
    # e.g.: ""%s──%s──%s"" for 3 columns
    line_segments = ["%s" * connect_symbol for _ = 1:ncols-1]
    push!(line_segments, "%s")
    return *(left_padding..., line_segments...)
end

function format_qubit_line(
    ncols::Int,
    qubit_numbers_in_row::Vector{Int},
    symbol_width::Int,
    left_offset::Int = 0,
)::String

    @assert ncols >= 0 ("ncols must be non-negative")
    @assert all(map(x -> x >= 0, qubit_numbers_in_row)) (
        "qubit_numbers_in_row must be non-negative"
    )
    @assert length(qubit_numbers_in_row) == ncols (
        "column count must match length(qubit_numbers_in_row)"
    )
    @assert symbol_width >= 0 ("symbol_width must be non-negative")
    @assert left_offset >= 0 ("left_offset must be non-negative")

    left_padding =
        [" "^(2 * Snowflurry.len_connect_sym + symbol_width) for _ = 1:left_offset]

    str_template = Snowflurry.create_str_template(ncols, left_padding)

    # create float specifier of correct precision: 
    # e.g.: "%2.f ──%2.f ──%2.f " for 3 columns, precision=2
    precisionStr = string(" %", symbol_width, ".f ")
    precisionArray = [precisionStr for _ = 1:ncols]
    str_template_float = Snowflurry.formatter(str_template, precisionArray...)

    return Snowflurry.formatter(str_template_float, qubit_numbers_in_row...)
end

function format_vertical_connections(
    ncols::Int,
    symbol_width::Int,
    left_offset::Int = 0,
)::String

    @assert ncols >= 0 ("ncols must be non-negative")
    @assert symbol_width >= 0 ("symbol_width must be non-negative")
    @assert left_offset >= 0 ("left_offset must be non-negative")

    if ncols == 0
        return ""
    end

    left_padding_global = [" "^(2 * len_connect_sym + symbol_width) for _ = 1:left_offset]

    str_template = create_str_template(ncols, left_padding_global)

    # vertical lines
    right_padding = string([" " for _ = 1:div(symbol_width + 1, 2)]...)
    left_padding = string([" " for _ = 1:div(symbol_width + 2, 2)]...)

    padded_vertical_symbol = left_padding * "|" * right_padding

    vertical_lines = Snowflurry.formatter(
        replace(str_template, "──" => "  "),
        [padded_vertical_symbol for _ = 1:ncols]...,
    )

    return vertical_lines
end

function get_lattice_offsets(
    connectivity::LatticeConnectivity,
)::Tuple{Vector{Int},Vector{Int},Vector{Int}}
    qubits_per_row = connectivity.qubits_per_row

    offsets = zeros(Int, length(qubits_per_row) + 1)
    offsets_vertical_lines = zeros(Int, length(qubits_per_row) + 1)
    num_vertical_lines = zeros(Int, length(qubits_per_row) + 1)

    for (irow, (count, next_count)) in
        enumerate(zip(qubits_per_row, vcat(qubits_per_row[2:end], [0])))

        if next_count > count
            offsets[1:irow] = [v + next_count - count - 1 for v in offsets[1:irow]]
            num_vertical_lines[irow] = count

        elseif next_count == count
            offsets[irow+1:end] = [v + 1 for v in offsets[irow+1:end]]
            offsets_vertical_lines[irow] += 1
            num_vertical_lines[irow] = next_count - 1

        elseif next_count < count
            offsets[irow+1:end] = [v + 1 for v in offsets[irow+1:end]]
            offsets_vertical_lines[irow] += 1
            num_vertical_lines[irow] = next_count
        end
    end

    return (offsets, offsets_vertical_lines, num_vertical_lines)
end

function get_adjacency_list(connectivity::LatticeConnectivity)::Dict{Int,Vector{Int}}

    (offsets, _, _) = get_lattice_offsets(connectivity)

    qubits_per_row = connectivity.qubits_per_row

    ncols = 0
    for (qubit_count, offset) in zip(qubits_per_row, offsets)
        ncols = maximum([ncols, qubit_count + offset])
    end

    nrows = length(qubits_per_row)

    qubit_placement = zeros(Int, nrows, ncols)

    qubit_count = get_num_qubits(connectivity)

    adjacency_list = Dict{Int,Vector{Int}}()

    qubit_numbering = assign_qubit_numbering(qubits_per_row, connectivity.dimensions[2])
    
    for (irow, qubit_count) in enumerate(qubits_per_row)
        offset = offsets[irow]
        qubit_placement[irow, 1+offset:qubit_count+offset] = qubit_numbering[irow]
    end

    for (target, ind) in zip(qubit_placement, CartesianIndices(qubit_placement))
        if target != 0
            neighbors = Vector{Int}()

            trow = ind[1]
            tcol = ind[2]

            if trow - 1 > 0 && qubit_placement[trow-1, tcol] != 0
                push!(neighbors, qubit_placement[trow-1, tcol])
            end

            if trow + 1 <= nrows && qubit_placement[trow+1, tcol] != 0
                push!(neighbors, qubit_placement[trow+1, tcol])
            end

            if tcol - 1 > 0 && qubit_placement[trow, tcol-1] != 0
                push!(neighbors, qubit_placement[trow, tcol-1])
            end

            if tcol + 1 <= ncols && qubit_placement[trow, tcol+1] != 0
                push!(neighbors, qubit_placement[trow, tcol+1])
            end

            adjacency_list[target] = neighbors
        end
    end

    return adjacency_list
end

"""
    get_adjacency_list(connectivity::AbstractConnectivity)::Dict{Int,Vector{Int}}

Given an object of type `AbstractConnectivity`, `get_adjacency_list` returns a Dict where `key => value` pairs
are each qubit number => an Vector of the qubits that are adjacent (neighbors) to it on this particular connectivity.

# Example
```jldoctest
julia> connectivity = LineConnectivity(6)
LineConnectivity{6}
1──2──3──4──5──6


julia> get_adjacency_list(connectivity)
Dict{Int64, Vector{Int64}} with 6 entries:
  5 => [4, 6]
  4 => [3, 5]
  6 => [5]
  2 => [1, 3]
  3 => [2, 4]
  1 => [2]

julia> connectivity = LatticeConnectivity(3, 4)
LatticeConnectivity{3,4}
  5 ──  1
  |     |
  9 ──  6 ──  2
        |     |
       10 ──  7 ──  3
              |     |
             11 ──  8 ──  4
                    |
                   12 
  
julia> get_adjacency_list(connectivity)
Dict{Int64, Vector{Int64}} with 12 entries:
  5  => [9, 1]
  12 => [8]
  8  => [3, 12, 11, 4]
  1  => [6, 5]
  6  => [1, 10, 9, 2]
  11 => [7, 8]
  9  => [5, 6]
  3  => [8, 7]
  7  => [2, 11, 10, 3]
  4  => [8]
  2  => [7, 6]
  10 => [6, 7]

```

!!! note
    `get_adjacency_list` cannot be performed for `AllToAllConnectivity`, as in such a connectivity, all qubits are adjacent, 
    with no upper bound on the number of qubits. A finite list of adjacent qubits thus cannot be constructed. 

"""
function get_adjacency_list(connectivity::LineConnectivity)::Dict{Int,Vector{Int}}
    adjacency_list = Dict{Int,Vector{Int}}()

    adjacency_list[1] = [2]

    for qubit_index = 2:connectivity.dimension-1
        adjacency_list[qubit_index] = [qubit_index - 1, qubit_index + 1]
    end

    adjacency_list[connectivity.dimension] = [connectivity.dimension - 1]

    return adjacency_list
end

function get_adjacency_list(connectivity::AllToAllConnectivity)
    throw(
        DomainError(
            "All qubits are adjacent in AllToAllConnectivity, without upper" *
            " limit on qubit count. A finite list of adjacent qubits thus cannot be constructed.",
        ),
    )
end

get_adjacency_list(connectivity::AbstractConnectivity)::Dict{Int,Vector{Int}} =
    throw(NotImplementedError(:get_adjacency_list, connectivity))

"""
    path_search(origin::Int, target::Int, connectivity::AbstractConnectivity)

Find the shortest path between origin and target qubits in terms of 
Manhattan distance, using the Breadth-First Search algorithm, on any 
`connectivity::AbstractConnectivity`.

# Example
```jldoctest
julia> connectivity = LineConnectivity(6)
LineConnectivity{6}
1──2──3──4──5──6


julia> path = path_search(2, 5, connectivity)
4-element Vector{Int64}:
 5
 4
 3
 2

```

On LatticeConnectivity, the print_connectivity() method is used to visualize the path.
The qubits along the path between origin and target are marker with `( )`

```jldoctest; output=false
julia> connectivity = LatticeConnectivity(6, 4)
LatticeConnectivity{6,4}
              5 ──  1
              |     |
       13 ──  9 ──  6 ──  2
        |     |     |     |
 21 ── 17 ── 14 ── 10 ──  7 ──  3
        |     |     |     |     |
       22 ── 18 ── 15 ── 11 ──  8 ──  4
              |     |     |     |
             23 ── 19 ── 16 ── 12
                    |     |
                   24 ── 20 


julia> path = path_search(3, 24, connectivity)
6-element Vector{Int64}:
 24
 20
 16
 12
  8
  3

```
"""
function path_search(origin::Int, target::Int, connectivity::LatticeConnectivity, excluded::Vector{Int}=Vector{Int}([]))

    @assert origin > 0 "origin must be non-negative"
    @assert target > 0 "target must be non-negative"

    qubit_count = *(connectivity.dimensions...)

    @assert origin <= qubit_count "origin $origin exceeds qubit_count $qubit_count"
    @assert target <= qubit_count "target $target exceeds qubit_count $qubit_count"

    adjacency_list = get_adjacency_list(connectivity)

    null_int = -1 # represents null previous node

    search_queue = Vector{Tuple{Int,Int}}()
    push!(search_queue, (origin, null_int))
    searched = Dict{Int,Int}()

    while !isempty(search_queue)
        (qubit_no, prev) = popfirst!(search_queue)

        if !haskey(searched, qubit_no)
            searched[qubit_no] = prev

            if qubit_no == target
                result = Vector{Int}()
                while qubit_no != null_int
                    push!(result, qubit_no)
                    # backtrack one step
                    qubit_no = searched[qubit_no]
                end
                return result
            else
                neighbors_vec =
                    [(neighbor, qubit_no) for neighbor in adjacency_list[qubit_no] if !(neighbor in excluded)]
                push!(search_queue, neighbors_vec...)
            end
        end
    end
end

function path_search(origin::Int, target::Int, connectivity::LineConnectivity, excluded::Vector{Int}=Vector{Int}([]))

    @assert origin > 0 "origin must be non-negative"
    @assert target > 0 "target must be non-negative"
    @assert target > 0 "target must be non-negative"

    qubit_count = connectivity.dimension

    @assert origin <= qubit_count "origin $origin exceeds qubit_count $qubit_count"
    @assert target <= qubit_count "target $target exceeds qubit_count $qubit_count"

    if origin < target
        path = reverse(collect(origin:target))
    else
        path = collect(target:origin)
    end

    for e in excluded
        @assert !(e in path) "failed to find path given excluded positions"
    end

    return path
end

path_search(::Int, ::Int, connectivity::AbstractConnectivity) =
    throw(NotImplementedError(:path_search, connectivity))
