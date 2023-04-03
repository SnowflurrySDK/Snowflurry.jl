using Snowflake
using LinearAlgebra

function test_inverse(gate::Snowflake.AbstractGate)
    inverse_gate=inv(gate)
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

        matrix_size=div(length(values),dim)

        if op_type==AntiDiagonalOperator
            first_row=1
            first_col=matrix_size
            last_row =matrix_size
            last_col=1
        else
            first_row=1
            first_col=1
            last_row=matrix_size
            last_col=matrix_size
        end

        # Constructor from Integer-valued Array
        op=op_type(input_array_int)

        @test Snowflake.tr(op)==LinearAlgebra.tr(get_matrix(op))

        @test (matrix_size,matrix_size)==size(op)

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

        # Cast to DenseOperator
        @test DenseOperator(op) ≈ op

    end

    test_label=string(label," math operations")
    @testset "$test_label"  begin

        op=op_type(input_array_complex+complex_offset)

        # Base.:+ and Base.:- 
        sum_op=op+op

        op_2=op_type(2*(input_array_complex+complex_offset))
        
        @test sum_op≈ op_2
        @test sum_op≈ DenseOperator(op)+op
        @test sum_op≈ op+DenseOperator(op)
                
        diff_op=sum_op-op
        @test diff_op ≈ op
        
        diff_op=op_2-op
        @test DenseOperator(op)≈ diff_op


        @test get_matrix(2*op) == get_matrix(op + op)    
        @test 2*op ≈ op + DenseOperator(op)
        @test 2*op ≈ DenseOperator(op) + op

        @test get_matrix(op) == get_matrix(2*op - op)
        @test DenseOperator(op) ≈ 2*op - DenseOperator(op)
        @test DenseOperator(op) ≈ 2*DenseOperator(op) - op
        
        # Commutation relations
        
        result=op*op-op*op

        @test commute(op,op)  ≈ result
        @test commute(op,DenseOperator(op))  ≈ result
        @test commute(DenseOperator(op),(op))≈ result

        result= op*op+op*op

        @test anticommute(op,op)  ≈ result
        @test anticommute(op,DenseOperator(op))  ≈ result
        @test anticommute(DenseOperator(op),(op))≈ result
    end

    test_label=string(label," apply_operator")
    @testset "$test_label"  begin
        if dim==1
            ψ_0=Ket(make_array(dim, ComplexF64, values))
            ψ_1=Ket(make_array(dim, ComplexF64, values))           
        else
            ψ_0=Ket(make_array(1, ComplexF64, values[1:2]))
            ψ_1=Ket(make_array(1, ComplexF64, values[1:2]))  
        end

        op=op_type(make_array(dim, ComplexF64, values))
    
        Snowflake.apply_operator!(ψ_1,op,[v for v in 1:get_num_qubits(op)])

        @test op*ψ_0 ≈ ψ_1

    end
end