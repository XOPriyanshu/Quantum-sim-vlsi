`include "qsim_params.vh"

// Combinational pair-address generator for one-qubit gates.
// pair_index ranges from 0 to 2^(N_QUBITS-1)-1.
// Inserting a zero at target bit q gives address a;
// setting that bit gives partner address b.
module addr_gen #(
    parameter integer N_QUBITS = `QSIM_DEFAULT_N_QUBITS
)(
    input  wire [2:0]                 target_q,
    input  wire [N_QUBITS-2:0]        pair_index,
    output reg  [N_QUBITS-1:0]        addr_a,
    output reg  [N_QUBITS-1:0]        addr_b,
    output wire                       valid
);
    integer bit_pos;
    always @* begin
        addr_a = {N_QUBITS{1'b0}};
        for (bit_pos = 0; bit_pos < N_QUBITS; bit_pos = bit_pos + 1) begin
            if (bit_pos < target_q)
                addr_a[bit_pos] = pair_index[bit_pos];
            else if (bit_pos > target_q)
                addr_a[bit_pos] = pair_index[bit_pos-1];
        end
        addr_b = addr_a;
        if (target_q < N_QUBITS)
            addr_b[target_q] = 1'b1;
    end
    assign valid = (target_q < N_QUBITS);
endmodule
