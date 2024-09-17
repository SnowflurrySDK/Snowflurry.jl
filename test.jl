using Snowflurry

function testConn(nrows::Int, ncols::Int)
    println("nrows       : $nrows")
    println("ncols       : $ncols")

    @assert nrows >= 2 "nrows must be at least 2"
    @assert ncols >= 2 "ncols must be at least 2"

    qubit_count = nrows * ncols
    placing_queue = [nrows for _ = 1:ncols]
    qubits_per_row = Vector{Int}()

    horizontal_cursor = 0
    while !all(map(x -> x == 0, placing_queue))

        horizontal_cursor += 1
        row_count = 0

        flag = true

        println("\nouterLoop cursor       : $horizontal_cursor")
        println("outerLoop placing_queue: $placing_queue")

        for pos = 1:minimum([horizontal_cursor, ncols])
            if flag
                increment = minimum([1, placing_queue[pos]])
                flag = false
            else
                increment = minimum([2, placing_queue[pos]])
            end
            row_count += increment
            placing_queue[pos] -= increment
            println("innerLoop row_count    : $row_count")
            println("innerLoop increment    : $increment")
            println("innerLoop placing_queue: $placing_queue")
        end

        push!(qubits_per_row, row_count)
    end

    @assert +(qubits_per_row...) == qubit_count "Failed to build lattice"

    println(qubits_per_row)
end

using Snowflurry

function testConn2(nrows::Int, ncols::Int)
    println("nrows       : $nrows")
    println("ncols       : $ncols")

    @assert nrows >= 2 "nrows must be at least 2"
    @assert ncols >= 2 "ncols must be at least 2"

    qubit_count = nrows * ncols
    placing_queue = [nrows for _ = 1:ncols]
    qubits_per_row = Vector{Int}()

    current_row = 0
    current_max_col = -1

    while !all(map(x -> x == 0, placing_queue))

        current_row += 1
        current_max_col += 2
        row_count = 0

        for pos = 1:minimum([current_max_col, ncols])
            if placing_queue[pos] > 0
                row_count += 1
                placing_queue[pos] -= 1
            end
        end

        push!(qubits_per_row, row_count)
    end

    @assert +(qubits_per_row...) == qubit_count "Failed to build lattice"

    println(qubits_per_row)
end
