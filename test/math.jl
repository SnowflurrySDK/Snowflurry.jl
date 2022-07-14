using Snowflake
using Test

@testset "gallois_fields" begin
    gf0 = GF2(0)
    gf1 = GF2(1)
    @test abs(gf1) == GF2(1)

    @test (gf0 < gf1) == true
    @test (gf1 < gf0) == false

    @test conj(gf1) == GF2(1)
end