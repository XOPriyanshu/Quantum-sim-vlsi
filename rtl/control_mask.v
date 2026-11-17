`include "qsim_params.vh"

// Combinational CNOT pair qualifier and MCZ basis-index comparator.
// Little-endian qubits: qubit q is index bit q.
module control_mask #(
    parameter integer N_QUBITS = `QSIM_DEFAULT_N_QUBITS
)(
    input  wire [2:0] control_q,
    input  wire [2:0] target_q,
    input  wire [N_QUBITS-1:0] pair_addr_a,
    input  wire [N_QUBITS-1:0] basis_addr,
    input  wire [5:0] mask,
    input  wire [5:0] value,
    output wire cnot_valid,
    output wire cnot_swap,
    output wire mcz_valid,
    output wire mcz_flip
);
    // For CNOT, both members of a target pair have the same control bit.
    assign cnot_valid = (control_q < N_QUBITS) &&
                        (target_q < N_QUBITS) &&
                        (control_q != target_q);
    assign cnot_swap = cnot_valid && pair_addr_a[control_q];

    // Mask/value fields are always six bits, including for 4/5 qubits.
    // Reject any bit outside the implemented qubit range and any value
    // bits that are not included in mask.
    localparam [5:0] ACTIVE_BITS = (6'b111111 >> (6 - N_QUBITS));
    assign mcz_valid = ((mask & ~ACTIVE_BITS) == 6'b0) &&
                       ((value & ~mask) == 6'b0);
    assign mcz_flip = mcz_valid &&
                      (({ {(6-N_QUBITS){1'b0}}, basis_addr } & mask) == value);
endmodule
