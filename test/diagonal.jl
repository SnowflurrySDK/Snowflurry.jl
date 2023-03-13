using Snowflake
using Test

@testset "diagonal_gate" begin

    qubit_count=3
    target=1
    
    ϕ=π  
    ψ = Ket([v for v in 1:2^qubit_count])

    diagGate=Snowflake.phase_gate(target,ϕ)
    apply_gate!(ψ, diagGate)
    
    ψ_z = Ket([v for v in 1:2^qubit_count])

    ZGate=sigma_z(target)
    apply_gate!(ψ_z, ZGate)

    @test ψ≈ψ_z
end


