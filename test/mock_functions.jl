using Snowflurry
using HTTP

expected_host = "http://example.anyonsys.com"
expected_user = "test_user"
expected_access_token = "not_a_real_access_token"
expected_project_id = "project_id"
expected_machine_name = "machine"
expected_realm = "test-realm"
expected_empty_queries = Dict{String,String}()

no_throttle = () -> Snowflurry.default_status_request_throttle(0)

make_common_substring(machine_name) =
    "{\"shotCount\":100,\"name\":\"default\",\"machineName\":\"$machine_name\",\"projectID\":\"project_id\",\"type\":\"circuit\",\"circuit\":{\"operations\":"

common_substring_yukon = make_common_substring(Snowflurry.AnyonYukonMachineName)
common_substring_yamaska = make_common_substring(Snowflurry.AnyonYamaskaMachineName)

make_expected_json(machine_name) =
    make_common_substring(machine_name) *
    "[" *
    "{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]}," *
    "{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}," *
    "{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}" *
    "],\"bitCount\":3,\"qubitCount\":3}}"

expected_json_generic = make_expected_json("machine")
expected_json_yukon = make_expected_json(Snowflurry.AnyonYukonMachineName)
expected_json_yamaska = make_expected_json(Snowflurry.AnyonYamaskaMachineName)

expected_json_non_default_bit_count =
    common_substring_yukon *
    "[" *
    "{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]}," *
    "{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}," *
    "{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}" *
    "],\"bitCount\":7,\"qubitCount\":3}}"

expected_json_last_qubit_Yukon =
    common_substring_yukon *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]" *
    ",\"bitCount\":6,\"qubitCount\":6}}"

expected_json_last_qubit_Yamaska =
    common_substring_yamaska *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[11]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[11]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[11]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]" *
    ",\"bitCount\":12,\"qubitCount\":12}}"

expected_json_transpiled =
    common_substring_yukon *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]},{\"bits\":[2],\"type\":\"readout\",\"qubits\":[2]}]" *
    ",\"bitCount\":3,\"qubitCount\":3}}"

expected_json_Toffoli_Yukon =
    common_substring_yukon *
    "[{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{\"lambda\":3.9269908169872414},\"type\":\"p\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{\"lambda\":3.9269908169872414},\"type\":\"p\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{\"lambda\":-3.9269908169872414},\"type\":\"p\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[0]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]" *
    ",\"bitCount\":5,\"qubitCount\":5}}"

expected_json_Toffoli_Yamaska =
    common_substring_yamaska *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,5]},{\"parameters\":{\"lambda\":-2.356194490192345},\"type\":\"p\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[0]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z\",\"qubits\":[1]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]" *
    ",\"bitCount\":11,\"qubitCount\":11}}"

expected_json_readout =
    common_substring_yukon *
    "[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"bits\":[2],\"type\":\"readout\",\"qubits\":[2]}]}}"

function make_post_checker(input_json::String, input_realm::String = "")::Function
    function post_checker(
        url::String,
        user::String,
        input_access_token::String,
        body::String,
        realm::String,
    )

        expected_url = expected_host * "/" * Snowflurry.path_jobs

        @assert url == expected_url ("received: \n$url, \nexpected: \n$expected_url")
        @assert input_access_token == expected_access_token (
            "received: \n$input_access_token, expected: \n$expected_access_token"
        )
        @assert body == input_json ("received: \n$body, expected: \n$input_json")

        @assert realm == input_realm ("received: \n$realm, expected: \n$input_realm")
        @assert user == expected_user ("received: \n$user, expected: \n$expected_user")

        return stubCircuitSubmittedResponse()
    end
end

"""
    This post checker ignores encoded body, as doctests use different machine_names and it has to work in all casess
"""
function make_post_checker_doctests(input_realm::String = "")::Function
    function post_checker(
        url::String,
        user::String,
        input_access_token::String,
        body::String,
        realm::String,
    )

        expected_url = expected_host * "/" * Snowflurry.path_jobs

        @assert url == expected_url ("received: \n$url, \nexpected: \n$expected_url")
        @assert input_access_token == expected_access_token (
            "received: \n$input_access_token, expected: \n$expected_access_token"
        )

        @assert realm == input_realm ("received: \n$realm, expected: \n$input_realm")
        @assert user == expected_user ("received: \n$user, expected: \n$expected_user")

        return stubCircuitSubmittedResponse()
    end
end

expected_get_status_response_body = "{\"status\":{\"type\":\"$(Snowflurry.succeeded_status)\"},\"result\":{\"histogram\":{\"001\":100}}}"

function make_request_checker(
    input_realm::String = "",
    input_queries::Dict{String,String} = (),
)::Function
    function request_checker(
        url::String,
        user::String,
        input_access_token::String,
        realm::String,
        queries::Dict{String,String} = (),
    )
        myregex = Regex("(.*)(/$(Snowflurry.path_jobs)/)([^/]*)\$")
        match_obj = match(myregex, url)

        @assert input_access_token == expected_access_token (
            "received: \n$input_access_token, expected: \n$expected_access_token"
        )
        @assert realm == input_realm ("received: \n$realm, expected: \n$input_realm")
        @assert user == expected_user ("received: \n$user, expected: \n$expected_user")

        @assert input_queries == queries (
            "received: \n$queries, expected: \n$input_queries"
        )

        if !isnothing(match_obj)
            # caller is :get_status
            return HTTP.Response(200, [], body = expected_get_status_response_body)
        end
        throw(NotImplementedError(:get_request, url))
    end
end

function stubStatusResponse(status::String)::HTTP.Response
    if status == Snowflurry.succeeded_status
        HTTP.Response(
            200,
            [],
            body = "{\"status\":{\"type\":\"$status\"}, \"result\":{\"histogram\":{\"001\":100}}}",
        )
    else
        HTTP.Response(
            200,
            [],
            body = "{\"status\":{\"type\":\"$status\"}, \"result\":{\"histogram\":{}}}",
        )
    end
end

stubFailedStatusResponse() = HTTP.Response(
    200,
    [],
    body = "{\"status\":{\"type\":\"$(Snowflurry.failed_status)\",\"message\":\"mocked\"}}",
)
stubResult() = HTTP.Response(200, [], body = "{\"histogram\":{\"001\":100}}")
stubFailureResult() =
    HTTP.Response(200, [], body = "{\"status\":{\"type\":\"$(Snowflurry.failed_status)\"}}")
stubCancelledResultResponse() = HTTP.Response(
    200,
    [],
    body = "{\"status\":{\"type\":\"$(Snowflurry.cancelled_status)\"}}",
)
stubCircuitSubmittedResponse() = HTTP.Response(
    200,
    [],
    body = "{\"id\":\"8050e1ed-5e4c-4089-ab53-cccda1658cd0\", \"histogram\":{\"001\":100}}",
)

yukonMetadata = "[{\"id\":\"64c5ec18-03a8-480e-a4dc-9377c109e659\",\"name\":\"yukon\",\"hostServer\":\"yukon.anyonsys.com\",\"type\":\"quantum-computer\",\"owner\":\"DRDC\",\"status\":\"online\",\"qubitCount\":6,\"bitCount\":6,\"connectivity\":\"linear\"}]"

yamaskaMetadata = "[{\"id\":\"6b770575-c40f-4d81-a9de-b1969a028ca5\",\"name\":\"yamaska\",\"hostServer\":\"yamaska.anyonsys.com\",\"type\":\"quantum-computer\",\"owner\":\"Calcul Québec\",\"status\":\"online\",\"qubitCount\":12,\"bitCount\":12,\"connectivity\":\"lattice\"}]"


yukonMetadataWithDisconnectedQubits = "[{\"id\":\"64c5ec18-03a8-480e-a4dc-9377c109e659\",\"name\":\"yukon\",\"hostServer\":\"yukon.anyonsys.com\",\"type\":\"quantum-computer\",\"owner\":\"DRDC\",\"status\":\"online\",\"qubitCount\":6,\"bitCount\":6,\"connectivity\":\"linear\",\"disconnectedQubits\":[3,4,5,6]}]"

yamaskaMetadataWithDisconnectedQubits = "[{\"id\":\"6b770575-c40f-4d81-a9de-b1969a028ca5\",\"name\":\"yamaska\",\"hostServer\":\"yamaska.anyonsys.com\",\"type\":\"quantum-computer\",\"owner\":\"Calcul Québec\",\"status\":\"online\",\"qubitCount\":12,\"bitCount\":12,\"connectivity\":\"lattice\",\"disconnectedQubits\":[7,8,9,10,11,12]}]"

stubMetadataResponse(body::String) = HTTP.Response(200, [], body = body)

# Returns a function that will yield the given responses in order as it's
# repeatedly called.
function stub_response_sequence(response_sequence::Vector{HTTP.Response})
    idx = 0

    # Allow but ignore whatever parameters callers want because we're returning
    # the next response regardless of what's passed.
    return function (args...; kwargs...)
        if idx >= length(response_sequence)
            throw(ErrorException("too many requests; response sequence exhausted"))
        end
        idx += 1
        return response_sequence[idx]
    end
end


# Returns a function that will call the given request_checkers in order as it's
# repeatedly called.
function stub_request_checker_sequence(request_checkers::Vector{Function})
    idx = 0

    # Allow but ignore whatever parameters callers want because we're returning
    # the next response regardless of what's passed.
    return function (args...; kwargs...)
        if idx >= length(request_checkers)
            throw(ErrorException("too many requests; response sequence exhausted"))
        end
        idx += 1
        return request_checkers[idx](args...; kwargs...)
    end
end
