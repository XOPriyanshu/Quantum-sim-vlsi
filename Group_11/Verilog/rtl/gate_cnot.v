// Input swap_enable must come from control_mask.cnot_swap.
module gate_cnot (
    input wire swap_enable,
    input wire signed [15:0] a_re, a_im, b_re, b_im,
    output wire signed [15:0] y_a_re, y_a_im, y_b_re, y_b_im
);
    assign y_a_re=swap_enable ? b_re : a_re;
    assign y_a_im=swap_enable ? b_im : a_im;
    assign y_b_re=swap_enable ? a_re : b_re;
    assign y_b_im=swap_enable ? a_im : b_im;
endmodule
