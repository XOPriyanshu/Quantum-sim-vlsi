
`include "qsim_params.vh"

// Parameterized quantum amplitude pair address generator.
// Generates two addresses differing at target qubit q.

module addr_gen #(
    parameter integer N_QUBITS = `QSIM_DEFAULT_N_QUBITS
)(
    input  wire [2:0]          target_q,
    input  wire [N_QUBITS-2:0] pair_index,
    output reg  [N_QUBITS-1:0] addr_a,
    output reg  [N_QUBITS-1:0] addr_b,
    output wire                valid
);

    // Valid target qubit
    assign valid = (target_q < 3'(N_QUBITS));

    reg [N_QUBITS-1:0] lower_mask;
    reg [N_QUBITS-1:0] lower_bits;
    reg [N_QUBITS-1:0] upper_bits;

    always @* begin
        lower_mask = ({N_QUBITS{1'b1}} >>
                      (N_QUBITS - target_q));

        lower_bits = pair_index & lower_mask;
        upper_bits = (pair_index & ~lower_mask) << 1;

        addr_a = lower_bits | upper_bits;
        addr_b = addr_a;

        if (valid)
            addr_b[target_q[$clog2(N_QUBITS)-1:0]] = 1'b1;
    end

endmodule
