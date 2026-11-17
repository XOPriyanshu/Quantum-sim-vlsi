`include "qsim_params.vh"

// Register-based quantum state storage, one complex amplitude per address.
// Two write ports allow a gate datapath to update one amplitude pair.
module state_bank #(
    parameter integer N_QUBITS = `QSIM_DEFAULT_N_QUBITS,
    parameter integer DATA_WIDTH = `QSIM_DEFAULT_DATA_WIDTH
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [N_QUBITS-1:0]      rd_addr,
    output wire signed [DATA_WIDTH-1:0] rd_re,
    output wire signed [DATA_WIDTH-1:0] rd_im,
    input  wire [N_QUBITS-1:0]      pair_addr_a,
    input  wire [N_QUBITS-1:0]      pair_addr_b,
    output wire signed [DATA_WIDTH-1:0] pair_a_re,
    output wire signed [DATA_WIDTH-1:0] pair_a_im,
    output wire signed [DATA_WIDTH-1:0] pair_b_re,
    output wire signed [DATA_WIDTH-1:0] pair_b_im,
    input  wire                     wr_en,
    input  wire [N_QUBITS-1:0]      wr_addr_a,
    input  wire [N_QUBITS-1:0]      wr_addr_b,
    input  wire signed [DATA_WIDTH-1:0] wr_a_re,
    input  wire signed [DATA_WIDTH-1:0] wr_a_im,
    input  wire signed [DATA_WIDTH-1:0] wr_b_re,
    input  wire signed [DATA_WIDTH-1:0] wr_b_im
);
    localparam integer STATE_COUNT = (1 << N_QUBITS);
    reg signed [DATA_WIDTH-1:0] state_re [0:STATE_COUNT-1];
    reg signed [DATA_WIDTH-1:0] state_im [0:STATE_COUNT-1];
    integer k;

    // Asynchronous combinational readout; writes commit at rising edge.
    assign rd_re = state_re[rd_addr];
    assign rd_im = state_im[rd_addr];
    assign pair_a_re = state_re[pair_addr_a];
    assign pair_a_im = state_im[pair_addr_a];
    assign pair_b_re = state_re[pair_addr_b];
    assign pair_b_im = state_im[pair_addr_b];

    always @(posedge clk) begin
        if (!rst_n) begin
            for (k = 0; k < STATE_COUNT; k = k + 1) begin
                state_re[k] <= {DATA_WIDTH{1'b0}};
                state_im[k] <= {DATA_WIDTH{1'b0}};
            end
            // Q2.14 representation of +1.0 (for baseline 16-bit width).
            state_re[0] <= `QSIM_ONE_Q14;
        end else if (wr_en) begin
            // Contract: write addresses must differ. Controller enforces this.
            state_re[wr_addr_a] <= wr_a_re;
            state_im[wr_addr_a] <= wr_a_im;
            state_re[wr_addr_b] <= wr_b_re;
            state_im[wr_addr_b] <= wr_b_im;
        end
    end
endmodule
