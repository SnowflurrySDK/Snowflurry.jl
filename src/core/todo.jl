#TODO
# function Base.show(io::IO, readout::Readout)
#     targets = get_connected_qubits(readout)

#     parameters = get_gate_parameters(get_gate_symbol(gate))

#     if isempty(parameters)
#         show_gate(
#             io,
#             typeof(get_gate_symbol(gate)),
#             targets,
#             get_operator(get_gate_symbol(gate)),
#         )
#     else
#         show_gate(
#             io,
#             typeof(get_gate_symbol(gate)),
#             targets,
#             get_operator(get_gate_symbol(gate)),
#             parameters,
#         )
#     end
# end
