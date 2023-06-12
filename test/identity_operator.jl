using Snowflake
using Test
using StaticArrays

label="IdentityOperator"

test_label=string(label," constructors")
@testset "$test_label"  begin

    matrix_size=2

    first_row=1
    first_col=1
    last_row=matrix_size
    last_col=matrix_size

    # default constructor 
    op=IdentityOperator()
    println(op)

    @test tr(op)==LinearAlgebra.tr(get_matrix(op))

    @test (matrix_size,matrix_size)==size(op)

    @test op[first_row,first_col]==ComplexF64(1.0)
    @test op[last_row,last_col]==ComplexF64(1.0)

    # Constructor specifying ComplexF32
    op=IdentityOperator(ComplexF32)

    @test op[first_row,first_col]===ComplexF32(1.)

    @test get_matrix(adjoint(op))==get_matrix(op)

    # Cast to DenseOperator
    @test DenseOperator(op) ≈ op

end

test_label=string(label," math operations")
@testset "$test_label"  begin

    op=IdentityOperator()

    # scalar multiplication, enforcing Julia promotion conventions
    a=10.0 #Float
    op_scaled=a*op
    op_scaled2=op*a

    @test a*op[1,1]≈op_scaled[1,1]
    @test a*op[1,1]≈op_scaled2[1,1]
    @test typeof(op[1,1])==ComplexF64

    # operator constructed with non-default type
    op=IdentityOperator(ComplexF32)

    a=10.0 #Float64
    op_scaled=a*op
    op_scaled2=op*a

    @test a*op[1,1]≈op_scaled[1,1]
    @test a*op[1,1]≈op_scaled2[1,1]
    @test typeof(op_scaled[1,1])==typeof(promote(a,op[1,1])[1])
    @test typeof(op_scaled2[1,1])==typeof(promote(a,op[1,1])[1])

    a=ComplexF64(10.0)
    op_scaled=a*op
    op_scaled2=op*a

    @test a*op[1,1]≈op_scaled[1,1]
    @test a*op[1,1]≈op_scaled2[1,1]
    @test typeof(op_scaled[1,1])==typeof(promote(a,op[1,1])[1])
    @test typeof(op_scaled2[1,1])==typeof(promote(a,op[1,1])[1])

    op=IdentityOperator()

    # Base.:+ and Base.:- 
    sum_op=op+op

    op_2=2*IdentityOperator()
    
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
    ψ_0=Ket(collect(1:2))
    ψ_1=Ket(collect(1:2))   

    op=IdentityOperator()

    Snowflake.apply_operator!(ψ_1,op,[v for v in 1:get_num_qubits(op)])

    @test op*ψ_0 ≈ ψ_1

end
