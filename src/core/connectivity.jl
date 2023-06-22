
abstract type AbstractConnectivity end

struct LineConnectivity <:AbstractConnectivity 
    dimension::Int
end

struct LatticeConnectivity <:AbstractConnectivity 
    qubits_per_row::Vector{Int}
    dimensions::Tuple{Int,Int}

    function LatticeConnectivity(nrows::Int, ncols::Int)

        @assert nrows >= 2 "nrows must be at least 2"
        @assert ncols >= 2 "ncols must be at least 2"

        qubit_count = nrows*ncols

        placing_queue = [ nrows for _ in 1:ncols]

        qubits_per_row = Vector{Int}()

        cursor=0
        while !all(map(x->x==0,placing_queue))
            cursor+=1
            row_count=0
            for pos in 1:minimum([cursor,ncols])
                increment=minimum([2,placing_queue[pos]])
                row_count+=increment
                placing_queue[pos]-=increment
            end

            push!(qubits_per_row,row_count)
        end

        @assert +(qubits_per_row...) == qubit_count "Failed to build lattice"

        new(qubits_per_row, (nrows, ncols))
    end

    function LatticeConnectivity(qubits_per_row::Vector{Int})
        nrows = maximum(qubits_per_row)
        ncols = ceil(+(qubits_per_row...)/nrows)

        new(qubits_per_row, (nrows, ncols))
    end
end

function Base.show(io::IO, connectivity::LatticeConnectivity) 
    println(io,"$(typeof(connectivity)){$(connectivity.dimensions[1]),$(connectivity.dimensions[2])}")
    print_connectivity(connectivity, Vector{Int}(), io)
end

function Base.show(io::IO, connectivity::LineConnectivity) 
    println(io,"$(typeof(connectivity)){$(connectivity.dimension)}")
    print_connectivity(connectivity, io)
end

get_connectivity_label(connectivity::AbstractConnectivity) =
    throw(NotImplementedError(:get_connectivity_label,connectivity))

const line_connectivity_label = "linear"
const lattice_connectivity_label = "2D-lattice"

get_connectivity_label(::LineConnectivity) = line_connectivity_label
get_connectivity_label(::LatticeConnectivity) = lattice_connectivity_label

get_num_qubits(conn::LineConnectivity) = *(conn.dimension...)
get_num_qubits(conn::LatticeConnectivity) = +(conn.qubits_per_row...)

function print_connectivity(connectivity::LineConnectivity,::Vector{Int}, io::IO = stdout)
    dim = connectivity.dimension

    diagram = [string(n) * "──" for n in 1:dim-1]
    push!(diagram,string(dim))

    output_str=*(diagram...)

    println(io,output_str)
end

connect_symbol="──"
len_connect_sym=length(connect_symbol)

function create_str_template(ncols::Int, left_padding::Vector{String})
    # create string template for ncols: 
    # e.g.: ""%s──%s──%s"" for 3 columns
    line_segments = ["%s"*connect_symbol for _ in 1:ncols-1]
    push!(line_segments, "%s")
    return *(left_padding...,line_segments...)
end

function format_qubit_line(ncols::Int, starting_no::Int, symbol_width::Int, left_offset::Int=0)::String

    @assert ncols>=0 ("ncols must be non-negative")
    @assert starting_no>=0 ("starting_no must be non-negative")
    @assert symbol_width>=0 ("symbol_width must be non-negative")
    @assert left_offset>=0 ("left_offset must be non-negative")

    left_padding=[" "^(2*len_connect_sym+symbol_width) for _ in 1:left_offset]
    
    str_template=create_str_template(ncols, left_padding)

    # create float specifier of correct precision: 
    # e.g.: "%2.f ──%2.f ──%2.f " for 3 columns, precision=2
    precisionStr = string(" %", symbol_width, ".f ")
    precisionArray = [precisionStr for _ in 1:ncols]
    str_template_float = Snowflake.formatter(str_template, precisionArray...)

    qubit_numbers_in_row = [v+starting_no-1 for v in  1:ncols]
    return Snowflake.formatter(str_template_float, qubit_numbers_in_row...)
end

function format_vertical_connections(ncols::Int, symbol_width::Int, left_offset::Int = 0)::String

    @assert ncols >= 0 ("ncols must be non-negative")
    @assert symbol_width >= 0 ("symbol_width must be non-negative")
    @assert left_offset >= 0 ("left_offset must be non-negative")
    
    if ncols == 0
        return ""
    end

    left_padding_global=[" "^(2*len_connect_sym + symbol_width) for _ in 1:left_offset]

    str_template=create_str_template(ncols, left_padding_global)

    # vertical lines
    right_padding   = string([" " for _ in 1:div(symbol_width+1, 2)]...)
    left_padding    = string([" " for _ in 1:div(symbol_width+2, 2)]...)

    padded_vertical_symbol = left_padding * "|" * right_padding

    vertical_lines = Snowflake.formatter(
        replace(str_template, "──" => "  "),
        [padded_vertical_symbol for _ in 1:ncols]...
    )

    return vertical_lines
end

function get_lattice_offsets(qubits_per_row::Vector{Int})::Tuple{Vector{Int}, Vector{Int}, Vector{Int}}
    offsets                 = zeros(Int, length(qubits_per_row)+1)
    offsets_vertical_lines  = zeros(Int, length(qubits_per_row)+1)
    num_vertical_lines      = zeros(Int, length(qubits_per_row)+1)
    
    for (irow,(count, next_count)) in enumerate(zip(qubits_per_row, vcat(qubits_per_row[2:end], [0])))
        
        if next_count > count
            offsets[1:irow] = [v+next_count-count-1 for v in offsets[1:irow]]
            num_vertical_lines[irow] = count

        elseif next_count == count
            offsets[irow+1:end] = [v+1 for v in offsets[irow+1:end]]
            offsets_vertical_lines[irow] += 1
            num_vertical_lines[irow] = next_count-1

        elseif next_count < count
            offsets[irow+1:end] = [v+1 for v in offsets[irow+1:end]]
            offsets_vertical_lines[irow] += 1
            num_vertical_lines[irow] = next_count
        end        
    end

    return (
        offsets,
        offsets_vertical_lines,
        num_vertical_lines
    )
end

function print_connectivity(connectivity::LatticeConnectivity, path::Vector{Int} = Vector{Int}(), io::IO = stdout)
    qubits_per_row = connectivity.qubits_per_row
    
    (
        offsets,
        offsets_vertical_lines,
        num_vertical_lines
    )=get_lattice_offsets(qubits_per_row)

    max_symbol_length = length(string(get_num_qubits(connectivity)))
    qubit_index = 1

    for (irow,qubit_count) in enumerate(qubits_per_row)
        line_printout = format_qubit_line(
            qubit_count,
            qubit_index,
            max_symbol_length,
            offsets[irow]
        )

        if !isempty(path)
            qubits_in_row=collect(qubit_index:qubit_index+qubit_count)
                   
            for qubit in qubits_in_row
                qubit_s=string(qubit)
                if qubit in path && occursin(qubit_s, line_printout)
                    line_printout=replace(line_printout," "*qubit_s*" "=>"("*qubit_s*")")
                end
            end
        end

        println(io, line_printout)
        
        
        vertical_lines = format_vertical_connections(
            num_vertical_lines[irow],
            max_symbol_length,
            offsets[irow] + offsets_vertical_lines[irow]
        )
        
        println(io, vertical_lines)

        qubit_index += qubit_count
    end
end

print_connectivity(connectivity::AbstractConnectivity, args...) =
    throw(NotImplementedError(:print_connectivity, connectivity))


function get_adjacency_list(connectivity::LatticeConnectivity)::Dict{Int,Vector{Int}}

    qubits_per_row = connectivity.qubits_per_row

    (offsets,_,_) = get_lattice_offsets(qubits_per_row)

    ncols = 0
    for (qubit_count, offset) in zip(qubits_per_row, offsets)
        ncols = maximum([ncols, qubit_count+offset])
    end

    nrows = length(qubits_per_row)

    qubit_placement = zeros(Int, nrows, ncols)

    qubit_count = get_num_qubits(connectivity)
    
    adjacency_list = Dict{Int, Vector{Int}}()

    placed_qubits = 0

    for (irow, qubit_count) in enumerate(qubits_per_row)
        offset = offsets[irow]
        qubit_placement[irow, 1+offset:qubit_count+offset] = 
            [v+placed_qubits for v in (1:qubit_count)]

        placed_qubits += qubit_count
    end

    for (target,ind) in zip(qubit_placement,CartesianIndices(qubit_placement))
        if target !=0
            neighbors=Vector{Int}()

            trow = ind[1]
            tcol = ind[2]

            if trow - 1 > 0 && qubit_placement[trow - 1, tcol] !=0
                push!(neighbors, qubit_placement[trow - 1, tcol])
            end

            if trow + 1 <= nrows && qubit_placement[trow + 1, tcol] !=0
                push!(neighbors, qubit_placement[trow + 1, tcol])
            end

            if tcol - 1 > 0 && qubit_placement[trow, tcol - 1] !=0
                push!(neighbors, qubit_placement[trow, tcol - 1])
            end

            if tcol + 1 <= ncols && qubit_placement[trow, tcol + 1] !=0
                push!(neighbors, qubit_placement[trow, tcol + 1])
            end

            adjacency_list[target] = neighbors
        end
    end

    return adjacency_list
end
    
#breadth-first search on 2D Lattice
function path_search(origin::Int, target::Int, connectivity::LatticeConnectivity)
    adjacency_list = get_adjacency_list(connectivity)
 
    null_int=-1 # represents null previous node

    search_queue = Vector{Tuple{Int,Int}}()
    push!(search_queue, (origin, null_int))
    searched = Dict{Int, Int}()

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
                neighbors_vec=[(neighbor, qubit_no) for neighbor in adjacency_list[qubit_no]]
                push!(search_queue, neighbors_vec...)
            end
        end
    end
end

function path_search(origin::Int, target::Int, connectivity::LineConnectivity) 
    if origin < target 
        return reverse(collect(origin:target))
    else
        return collect(target:origin)
    end
end