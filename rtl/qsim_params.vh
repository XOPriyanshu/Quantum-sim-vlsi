`ifndef QSIM_PARAMS_VH
`define QSIM_PARAMS_VH

// Quantum state-vector simulator shared definitions.
// Module parameters N_QUBITS, LANES, DATA_WIDTH, PIPE_STAGES
// are declared in each parameterized module (not as global macros).

// Instruction fields: [31:21] reserved, [20:15] value,
// [14:9] mask, [8:6] control, [5:3] target, [2:0] opcode.
`define QSIM_OPCODE_MSB  2
`define QSIM_OPCODE_LSB  0
`define QSIM_TARGET_MSB  5
`define QSIM_TARGET_LSB  3
`define QSIM_CONTROL_MSB 8
`define QSIM_CONTROL_LSB 6
`define QSIM_MASK_MSB    14
`define QSIM_MASK_LSB    9
`define QSIM_VALUE_MSB   20
`define QSIM_VALUE_LSB   15

`define QSIM_OP_H        3'd0
`define QSIM_OP_X        3'd1
`define QSIM_OP_Z        3'd2
`define QSIM_OP_T        3'd3
`define QSIM_OP_CNOT     3'd4
`define QSIM_OP_MCZ      3'd5

// Baseline fixed-point representation: signed Q2.14, 16 bits.
`define QSIM_DEFAULT_N_QUBITS     6
`define QSIM_DEFAULT_LANES        1
`define QSIM_DEFAULT_DATA_WIDTH   16
`define QSIM_DEFAULT_PIPE_STAGES  3
`define QSIM_FRAC_BITS            14
`define QSIM_INV_SQRT2_Q14        16'sd11585
`define QSIM_ONE_Q14              16'sd16384

`endif
