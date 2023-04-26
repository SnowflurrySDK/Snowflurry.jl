using Snowflake
using Test

@testset "SparseOperator" begin
    σ_z=SparseOperator([1.0 0.0;0.0 -1.0])
    σ_y=SparseOperator([0.0 -im;im 0.0])
end