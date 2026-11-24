`include "qsim_params.vh"

// Single-lane instruction controller.
// One pair is issued per cycle; DRAIN separates dependent instructions.
module qsim_controller #(
    parameter integer N_QUBITS = `QSIM_DEFAULT_N_QUBITS
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        instr_valid,
    input  wire [31:0] instr,
    output wire        ready,
    output reg         done,
    output reg         err,
    output reg         issue,
    output reg  [N_QUBITS-2:0] pair_index,
    output reg  [31:0] active_instr
);
    localparam [1:0] ST_IDLE   = 2'd0;
    localparam [1:0] ST_ISSUE  = 2'd1;
    localparam [1:0] ST_DRAIN  = 2'd2;
    localparam [1:0] ST_COMMIT = 2'd3;
    localparam integer LAST_PAIR = (1 << (N_QUBITS-1)) - 1;

    reg [1:0] state;
    wire [2:0] in_opcode  = instr[2:0];
    wire [2:0] in_target  = instr[5:3];
    wire [2:0] in_control = instr[8:6];
    wire [5:0] in_mask    = instr[14:9];
    wire [5:0] in_value   = instr[20:15];
    localparam [5:0] ACTIVE_MASK = (6'b111111 >> (6-N_QUBITS));

    function instruction_ok;
        input [31:0] word;
        reg [2:0] op, tgt, ctl;
        reg [5:0] msk, val;
        begin
            op  = word[2:0];
            tgt = word[5:3];
            ctl = word[8:6];
            msk = word[14:9];
            val = word[20:15];
            instruction_ok = (word[31:21] == 0) && (op <= `QSIM_OP_MCZ);
            if ((op == `QSIM_OP_H) || (op == `QSIM_OP_X) ||
                (op == `QSIM_OP_Z) || (op == `QSIM_OP_T))
                instruction_ok = instruction_ok && (tgt < N_QUBITS);
            else if (op == `QSIM_OP_CNOT)
                instruction_ok = instruction_ok && (tgt < N_QUBITS) &&
                                 (ctl < N_QUBITS) && (ctl != tgt);
            else if (op == `QSIM_OP_MCZ)
                instruction_ok = instruction_ok && ((msk & ~ACTIVE_MASK) == 0) &&
                                 ((val & ~msk) == 0);
        end
    endfunction

    assign ready = (state == ST_IDLE) || (state == ST_COMMIT);
    always @* begin
        issue = (state == ST_ISSUE);
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            pair_index <= 0;
            active_instr <= 0;
            done <= 0;
            err <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                ST_IDLE: begin
                    if (instr_valid) begin
                        if (instruction_ok(instr)) begin
                            active_instr <= instr;
                            pair_index <= 0;
                            state <= ST_ISSUE;
                        end else begin
                            err <= 1'b1;
                        end
                    end
                end
                ST_ISSUE: begin
                    if (pair_index == LAST_PAIR)
                        state <= ST_DRAIN;
                    else
                        pair_index <= pair_index + 1'b1;
                end
                ST_DRAIN: state <= ST_COMMIT;
                ST_COMMIT: begin
                    done <= 1'b1;
                    if (instr_valid) begin
                        if (instruction_ok(instr)) begin
                            active_instr <= instr;
                            pair_index <= 0;
                            state <= ST_ISSUE;
                        end else begin
                            err <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end else begin
                        state <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
