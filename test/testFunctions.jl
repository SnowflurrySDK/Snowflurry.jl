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


function test_operator_implementation(op_type::Type{<:Snowflake.AbstractOperator};dim::Integer=2,label="")

    input_array_int     =make_array(dim, Int64)
    input_array_float   =make_array(dim, Float64)
    input_array_complex =make_array(dim, ComplexF64)
    complex_offset      =make_array(1,ComplexF64,[0.0+im for _ in 1:4])

    result_array        =make_array(dim, ComplexF64)
    
    test_label=string(label," constructors")
    @testset "$test_label"  begin


        # Constructor from Integer-valued Array
        op=op_type(input_array_int)

        @test op.data==result_array

        # Constructor from Integer-valued Array, specifying ComplexF32
        op=op_type(input_array_int,ComplexF32)

        @test op.data==make_array(dim, ComplexF32)
        @test op.data[1]===ComplexF32(1.)

        # Constructor from Real-valued Array
        op=op_type(input_array_float)
        @test op.data==result_array

        # Constructor from Complex-valued Array
        op=op_type(input_array_complex)
        @test op.data==result_array   

        op=op_type(input_array_complex+complex_offset)

        # Constructor from adjoint(op_type{T})
        @test adjoint(op).data==input_array_complex-complex_offset

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


        @test (2*op).data == (op + op).data    
        @test 2*op ≈ op + Operator(op)
        @test 2*op ≈ Operator(op) + op

        @test op.data == (2*op - op).data
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