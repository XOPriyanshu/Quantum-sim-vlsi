// Hadamard on a complex amplitude pair (a,b).
module gate_h (
    input wire signed [15:0] a_re, a_im, b_re, b_im,
    output wire signed [15:0] y_a_re, y_a_im, y_b_re, y_b_im
);
    wire signed [17:0] sum_re = $signed(a_re) + $signed(b_re);
    wire signed [17:0] sum_im = $signed(a_im) + $signed(b_im);
    wire signed [17:0] diff_re = $signed(a_re) - $signed(b_re);
    wire signed [17:0] diff_im = $signed(a_im) - $signed(b_im);
    fx_arith u0(sum_re,y_a_re);
    fx_arith u1(sum_im,y_a_im);
    fx_arith u2(diff_re,y_b_re);
    fx_arith u3(diff_im,y_b_im);
endmodule
