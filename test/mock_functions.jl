using Snowflurry
using HTTP

host = "http://example.anyonsys.com"
user = "test_user"
expected_access_token = "not_a_real_access_token"

common_substring = "{\"shotCount\":100,\"name\":\"default\",\"machine_id\":\"http://example.anyonsys.com\",\"type\":\"circuit\",\"circuit\":{\"operations\":"

expected_json = common_substring * "[" *
    "{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]}," *
    "{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]}]}}"

expected_json_with_project_id = "{\"shotCount\":100,\"name\":\"default\",\"machine_id\":\"http://example.anyonsys.com\",\"billingaccountID\":\"test_project_id\",\"type\":\"circuit\",\"circuit\":{\"operations\":[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]}]}}"

expected_json_last_qubit_Yukon = common_substring * "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[5]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[5]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

expected_json_last_qubit_Yamaska = common_substring * "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[11]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[11]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[11]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

expected_json_transpiled = common_substring * "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,0]},{\"bits\":[2],\"type\":\"readout\",\"qubits\":[2]}]}}"

expected_json_Toffoli_Yukon = common_substring * "[{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{\"lambda\":3.9269908169872414},\"type\":\"rz\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{\"lambda\":3.9269908169872414},\"type\":\"rz\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,2]},{\"parameters\":{\"lambda\":-3.9269908169872414},\"type\":\"rz\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[0]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

expected_json_Toffoli_Yamaska = common_substring * "[{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[1,4]},{\"parameters\":{\"lambda\":-3.9269908169872414},\"type\":\"rz\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[4]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[4,3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[3]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[3,2]},{\"parameters\":{},\"type\":\"t_dag\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[2]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[0]},{\"parameters\":{},\"type\":\"z_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"t\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_minus_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"cz\",\"qubits\":[0,1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"x_90\",\"qubits\":[1]},{\"parameters\":{},\"type\":\"z_90\",\"qubits\":[1]},{\"bits\":[0],\"type\":\"readout\",\"qubits\":[0]}]}}"

expected_json_readout = common_substring * "[{\"parameters\":{},\"type\":\"x\",\"qubits\":[2]},{\"bits\":[2],\"type\":\"readout\",\"qubits\":[2]}]}}"

function make_post_checker(expected_json::String)::Function
    function post_checker(
        url::String,
        user::String,
        input_access_token::String,
        body::String,
    )

        expected_url = host * "/" * Snowflurry.path_jobs

        @assert url == expected_url ("received: \n$url, \nexpected: \n$expected_url")
        @assert input_access_token == expected_access_token (
            "received: \n$input_access_token, expected: \n$expected_access_token"
        )
        @assert body == expected_json ("received: \n$body, expected: \n$expected_json")

        return stubCircuitSubmittedResponse()
    end
end

expected_get_status_response_body = "{\"status\":{\"type\":\"$(Snowflurry.succeeded_status)\"},\"result\":{\"histogram\":{\"001\":100}}}"

function request_checker(url::String, user::String, access_token::String)
    myregex = Regex("(.*)(/$(Snowflurry.path_jobs)/)([^/]*)\$")
    match_obj = match(myregex, url)

    if !isnothing(match_obj)
        # caller is :get_status
        return HTTP.Response(200, [], body = expected_get_status_response_body)
    end
    throw(NotImplementedError(:get_request, url))
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
