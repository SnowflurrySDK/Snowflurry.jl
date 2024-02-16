using Snowflurry
using HTTP

expected_host = "http://example.anyonsys.com"
expected_user = "test_user"
expected_access_token = "not_a_real_access_token"
expected_project_id = "project_id"
expected_machine_hostname = "machine.anyonsys.com"
expected_realm = "test-realm"

make_common_substring(machine_hostname) =
    "{\"shotCount\":100,\"name\":\"default\",\"billingaccountID\":\"project_id\",\"type\":\"circuit\",\"machineHost\":\"$machine_hostname\",\"circuit\":{\"operations\":"

common_substring_yukon = make_common_substring(Snowflurry.AnyonYukonQPUHostname)
common_substring_yamaska = make_common_substring(Snowflurry.AnyonYamaskaQPUHostname)

make_expected_json(machine_hostname) =
    make_common_substring(machine_hostname) *
    "[" *
    "{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]}," *
    "{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}," *
    "{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}" *
    "]}}"

expected_json_generic = make_expected_json("machine.anyonsys.com")
expected_json_yukon = make_expected_json(Snowflurry.AnyonYukonQPUHostname)

expected_json_last_qubit_Yukon =
    common_substring_yukon *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

expected_json_last_qubit_Yamaska =
    common_substring_yamaska *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[11]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[11]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[11]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

expected_json_transpiled =
    common_substring_yukon *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]},{\"bits\":[2],\"type\":\"readout\",\"qubits\":[2]}]}}"

expected_json_Toffoli_Yukon =
    common_substring_yukon *
    "[{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{\"lambda\":3.9269908169872414},\"type\":\"p\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{\"lambda\":3.9269908169872414},\"type\":\"p\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{\"lambda\":-3.9269908169872414},\"type\":\"p\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[0]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

expected_json_Toffoli_Yamaska =
    common_substring_yamaska *
    "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,5]},{\"parameters\":{\"lambda\":-2.356194490192345},\"type\":\"p\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[9]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[9,5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[5,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[0]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,1]},{\"parameters\":{},\"type\":\"z\",\"qubits\":[1]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

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
    This post checker ignores encoded body, as doctests use different machine_hostnames and it has to work in all casess
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

function make_request_checker(input_realm::String = "")::Function
    function request_checker(
        url::String,
        user::String,
        input_access_token::String,
        realm::String,
    )
        myregex = Regex("(.*)(/$(Snowflurry.path_jobs)/)([^/]*)\$")
        match_obj = match(myregex, url)

        @assert input_access_token == expected_access_token (
            "received: \n$input_access_token, expected: \n$expected_access_token"
        )
        @assert realm == input_realm ("received: \n$realm, expected: \n$input_realm")
        @assert user == expected_user ("received: \n$user, expected: \n$expected_user")

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
