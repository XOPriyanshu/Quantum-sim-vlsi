`include "qsim_params.vh"

// Phase 4 single-lane quantum state-vector simulator top.
// DATA_WIDTH is fixed at 16 by the Phase 3 gate datapaths (Q2.14).
module qsim_top #(
    parameter integer N_QUBITS = `QSIM_DEFAULT_N_QUBITS,
    parameter integer DATA_WIDTH = `QSIM_DEFAULT_DATA_WIDTH
)(
    input  wire clk,
    input  wire rst_n,
    input  wire instr_valid,
    input  wire [31:0] instr,
    output wire ready,
    output wire done,
    input  wire [N_QUBITS-1:0] rd_addr,
    output wire signed [DATA_WIDTH-1:0] rd_re,
    output wire signed [DATA_WIDTH-1:0] rd_im,
    output wire err
);
    wire issue;
    wire [N_QUBITS-2:0] pair_index;
    wire [31:0] active_instr;
    wire [2:0] opcode  = active_instr[2:0];
    wire [2:0] target  = active_instr[5:3];
    wire [2:0] control = active_instr[8:6];
    wire [5:0] mask    = active_instr[14:9];
    wire [5:0] value   = active_instr[20:15];
    wire [2:0] addr_target = (opcode == `QSIM_OP_MCZ) ? 3'd0 : target;

    wire [N_QUBITS-1:0] addr_a, addr_b;
    wire addr_valid;
    wire cnot_valid_a, cnot_swap_a, mcz_valid_a, mcz_flip_a;
    wire cnot_valid_b, cnot_swap_b, mcz_valid_b, mcz_flip_b;
    wire signed [15:0] a_re, a_im, b_re, b_im;
    wire signed [15:0] y_a_re, y_a_im, y_b_re, y_b_im;
    wire valid_opcode;

    qsim_controller #(.N_QUBITS(N_QUBITS)) u_controller (
        .clk(clk), .rst_n(rst_n), .instr_valid(instr_valid), .instr(instr),
        .ready(ready), .done(done), .err(err), .issue(issue),
        .pair_index(pair_index), .active_instr(active_instr)
    );

    // MCZ uses target bit zero only to partition the full state into pairs.
    addr_gen #(.N_QUBITS(N_QUBITS)) u_addr_gen (
        .target_q(addr_target), .pair_index(pair_index),
        .addr_a(addr_a), .addr_b(addr_b), .valid(addr_valid)
    );

    control_mask #(.N_QUBITS(N_QUBITS)) u_control_a (
        .control_q(control), .target_q(target), .pair_addr_a(addr_a),
        .basis_addr(addr_a), .mask(mask), .value(value),
        .cnot_valid(cnot_valid_a), .cnot_swap(cnot_swap_a),
        .mcz_valid(mcz_valid_a), .mcz_flip(mcz_flip_a)
    );
    control_mask #(.N_QUBITS(N_QUBITS)) u_control_b (
        .control_q(control), .target_q(target), .pair_addr_a(addr_b),
        .basis_addr(addr_b), .mask(mask), .value(value),
        .cnot_valid(cnot_valid_b), .cnot_swap(cnot_swap_b),
        .mcz_valid(mcz_valid_b), .mcz_flip(mcz_flip_b)
    );

    state_bank #(.N_QUBITS(N_QUBITS), .DATA_WIDTH(DATA_WIDTH)) u_state_bank (
        .clk(clk), .rst_n(rst_n), .rd_addr(rd_addr), .rd_re(rd_re), .rd_im(rd_im),
        .pair_addr_a(addr_a), .pair_addr_b(addr_b),
        .pair_a_re(a_re), .pair_a_im(a_im), .pair_b_re(b_re), .pair_b_im(b_im),
        .wr_en(issue), .wr_addr_a(addr_a), .wr_addr_b(addr_b),
        .wr_a_re(y_a_re), .wr_a_im(y_a_im), .wr_b_re(y_b_re), .wr_b_im(y_b_im)
    );

    gate_datapath u_gate_datapath (
        .opcode(opcode),
        .cnot_swap(cnot_swap_a && cnot_valid_a),
        .mcz_flip_a(mcz_flip_a && mcz_valid_a),
        .mcz_flip_b(mcz_flip_b && mcz_valid_b),
        .a_re(a_re), .a_im(a_im), .b_re(b_re), .b_im(b_im),
        .y_a_re(y_a_re), .y_a_im(y_a_im),
        .y_b_re(y_b_re), .y_b_im(y_b_im),
        .valid_opcode(valid_opcode)
    );

    // The controller validates each instruction before entering ISSUE.
    // The following wires are retained as useful elaboration-time checks.
    wire _unused_valid = addr_valid & valid_opcode & cnot_valid_b;
endmodule
