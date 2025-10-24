using Snowflurry

circuit = QuantumCircuit(qubit_count = 3, name = "control_x")

# push!(circuit, hadamard(1))
push!(circuit, control_x(1, 2))
push!(circuit, readout(1,1))

# user = ENV["THUNDERHEAD_USER"]
# token = ENV["THUNDERHEAD_API_TOKEN"]
# host = ENV["THUNDERHEAD_HOST"]
# project_id = ENV["THUNDERHEAD_PROJECT_ID"]
# realm = ENV["THUNDERHEAD_REALM"]

# qpu = AnyonYukonQPU(
#     host = "host",
#     user = "user",
#     access_token = "token",
#     project_id = "project_id",
#     realm = "realm",
# )

# transpiler = Snowflurry.get_anyon_transpiler(atol = 1e-8, connectivity = Snowflurry.AnyonYukonConnectivity)

atol = 1e-8

transpiler = SequentialTranspiler([
    CastCXToCZGateTranspiler(),
    CompressSingleQubitGatesTranspiler(),
    # SimplifyTrivialGatesTranspiler(atol),
    CastUniversalToRzRxRzTranspiler(),
    SimplifyRxGatesTranspiler(atol),
    CastRxToRzAndHalfRotationXTranspiler(),
    # CompressRzGatesTranspiler(),
    # SimplifyRzGatesTranspiler(),
])


# connectivity = Snowflurry.AnyonYukonConnectivity

# transpiler = SequentialTranspiler([
#     CircuitContainsAReadoutTranspiler(),
#     ReadoutsDoNotConflictTranspiler(),
#     UnsupportedGatesTranspiler(),
#     DecomposeSingleTargetSingleControlGatesTranspiler(),
#     CastToffoliToCXGateTranspiler(),
#     CastCXToCZGateTranspiler(),
#     CastISwapToCZGateTranspiler(),
#     CastRootZZToZ90AndCZGateTranspiler(),
#     SwapQubitsForAdjacencyTranspiler(connectivity),
#     CastSwapToCZGateTranspiler(),
#     CompressSingleQubitGatesTranspiler(),
#     SimplifyTrivialGatesTranspiler(atol),
#     CastUniversalToRzRxRzTranspiler(),
#     SimplifyRxGatesTranspiler(atol),
#     CastRxToRzAndHalfRotationXTranspiler(),
#     CompressRzGatesTranspiler(),
#     SimplifyRzGatesTranspiler(atol),
#     ReadoutsAreFinalInstructionsTranspiler(),
#     RejectNonNativeInstructionsTranspiler(connectivity),
#     RejectGatesOnExcludedPositionsTranspiler(connectivity),
#     RejectGatesOnExcludedConnectionsTranspiler(connectivity),
# ])

transpiled_circuit = transpile(transpiler, circuit)

println(transpiled_circuit)
println("gate count: $(length(get_circuit_instructions(transpiled_circuit)))")