using Snowflake

function test_inverse(gate::Gate)
    inverse_gate=get_inverse(gate)
    target_count=length(gate.target)

    return( get_operator(gate)*get_operator(inverse_gate) ≈ eye(target_count) )
end

function test_inverse(gate::Snowflake.AbstractGate)
    inverse_gate=get_inverse(gate)
    target_count=length(Snowflake.get_connected_qubits(gate))

    return( get_operator(gate)*get_operator(inverse_gate) ≈ eye(target_count) )
end

function make_array(
    dim::Integer,
    T::Type{<:Number}=Float64,
    values::Vector{<:Number}=[1.,2.,3.,4.]
    )

    if dim ==1
        return array_test=convert(Vector{T},values)
    elseif dim==2
        return array_test=convert(Matrix{T},reshape(values,2,2))
    else
        DomainError("cannot construct with array dimension $dim")
    end
end


function test_operator_implementation(
    op_type::Type{<:Snowflake.AbstractOperator};
    dim::Integer=2,
    label="",
    values::Vector{<:Number}=[1.,2.,3.,4.])

    input_array_int     =make_array(dim, Int64 , values)
    input_array_float   =make_array(dim, Float64, values)
    input_array_complex =make_array(dim, ComplexF64, values)
    complex_offset      =make_array(dim, ComplexF64, [0.0+im for _ in values])

    result_array        =make_array(dim, ComplexF64, values)
    
    test_label=string(label," constructors")
    @testset "$test_label"  begin

        if op_type==AntiDiagonalOperator
            first_row=1
            first_col=div(length(values),dim)
            last_row=div(length(values),dim)
            last_col=1
        else
            first_row=1
            first_col=1
            last_row=div(length(values),dim)
            last_col=div(length(values),dim)
        end

        # Constructor from Integer-valued Array
        op=op_type(input_array_int)

       
        @test op[first_row,first_col]==result_array[1]
        @test op[last_row,last_col]==result_array[end]

        # Constructor from Integer-valued Array, specifying ComplexF32
        op=op_type(input_array_int,ComplexF32)

        @test op[first_row,first_col]===ComplexF32(1.)

        # Constructor from Real-valued Array
        op=op_type(input_array_float)
        @test op[first_row,first_col]==result_array[1]
        @test op[last_row,last_col]==result_array[end]

        # Constructor from Complex-valued Array
        op=op_type(input_array_complex)
        @test op[first_row,first_col]==result_array[1]
        @test op[last_row,last_col]==result_array[end]

        op=op_type(input_array_complex+complex_offset)

        # Constructor from adjoint(op_type{T})
        if dim==1
            dense_mat=get_matrix(op)
            result=adjoint(dense_mat)
        else
            result=adjoint(input_array_complex+complex_offset)
        end
        @test get_matrix(adjoint(op))==result

        # Cast to Operator
        @test Operator(op) ≈ op

    end

    test_label=string(label," math operations")
    @testset "$test_label"  begin

        op=op_type(input_array_complex+complex_offset)

        # Base.:+ and Base.:- 
        sum_op=op+op

        op_2=op_type(2*(input_array_complex+complex_offset))
        
        @test sum_op≈ op_2
        @test sum_op≈ Operator(op)+op
        @test sum_op≈ op+Operator(op)
                
        diff_op=sum_op-op
        @test diff_op ≈ op
        
        diff_op=op_2-op
        @test Operator(op)≈ diff_op


        @test get_matrix(2*op) == get_matrix(op + op)    
        @test 2*op ≈ op + Operator(op)
        @test 2*op ≈ Operator(op) + op

        @test get_matrix(op) == get_matrix(2*op - op)
        @test Operator(op) ≈ 2*op - Operator(op)
        @test Operator(op) ≈ 2*Operator(op) - op
        
        # Commutation relations
        
        result=op*op-op*op

        @test commute(op,op)  ≈ result
        @test commute(op,Operator(op))  ≈ result
        @test commute(Operator(op),(op))≈ result

        result= op*op+op*op

        @test anticommute(op,op)  ≈ result
        @test anticommute(op,Operator(op))  ≈ result
        @test anticommute(Operator(op),(op))≈ result
    end
end