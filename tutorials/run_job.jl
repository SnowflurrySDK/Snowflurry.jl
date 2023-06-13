using Snowflake

c=QuantumCircuit(qubit_count=2)
push!(c,hadamard(1),control_x(1,2))

qpu=AnyonQPU(host="http://qms-dev.vm-maas:50053", user="user", access_token="token")

run_job(qpu,c,101)
