`include "qsim_params.vh"
// Combinational pair-update datapath. For MCZ, caller supplies pair-specific
// flip signals; for CNOT, caller supplies qualified swap signal.
// Controller/state bank hookup is Phase 4, not included here.
module gate_datapath (
    input wire [2:0] opcode,
    input wire cnot_swap, mcz_flip_a, mcz_flip_b,
    input wire signed [15:0] a_re,a_im,b_re,b_im,
    output reg signed [15:0] y_a_re,y_a_im,y_b_re,y_b_im,
    output wire valid_opcode
);
    wire signed [15:0] hr0,hi0,hr1,hi1,tr0,ti0,tr1,ti1;
    wire signed [15:0] xr0,xi0,xr1,xi1,zr0,zi0,zr1,zi1;
    wire signed [15:0] cr0,ci0,cr1,ci1,mr0,mi0,mr1,mi1;
    gate_h h(a_re,a_im,b_re,b_im,hr0,hi0,hr1,hi1);
    gate_t t(a_re,a_im,b_re,b_im,tr0,ti0,tr1,ti1);
    gate_x x(a_re,a_im,b_re,b_im,xr0,xi0,xr1,xi1);
    gate_z z(a_re,a_im,b_re,b_im,zr0,zi0,zr1,zi1);
    gate_cnot c(cnot_swap,a_re,a_im,b_re,b_im,cr0,ci0,cr1,ci1);
    gate_mcz m(mcz_flip_a,mcz_flip_b,a_re,a_im,b_re,b_im,mr0,mi0,mr1,mi1);
    assign valid_opcode=(opcode<=`QSIM_OP_MCZ);
    always @* begin
        y_a_re=a_re; y_a_im=a_im; y_b_re=b_re; y_b_im=b_im;
        case(opcode)
            `QSIM_OP_H: begin y_a_re=hr0;y_a_im=hi0;y_b_re=hr1;y_b_im=hi1;end
            `QSIM_OP_X: begin y_a_re=xr0;y_a_im=xi0;y_b_re=xr1;y_b_im=xi1;end
            `QSIM_OP_Z: begin y_a_re=zr0;y_a_im=zi0;y_b_re=zr1;y_b_im=zi1;end
            `QSIM_OP_T: begin y_a_re=tr0;y_a_im=ti0;y_b_re=tr1;y_b_im=ti1;end
            `QSIM_OP_CNOT: begin y_a_re=cr0;y_a_im=ci0;y_b_re=cr1;y_b_im=ci1;end
            `QSIM_OP_MCZ: begin y_a_re=mr0;y_a_im=mi0;y_b_re=mr1;y_b_im=mi1;end
            default: begin end
        endcase
    end
endmodule
