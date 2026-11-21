// Project T: |1> amplitude multiplied by (1+j)/sqrt(2).
// Amplitude a (target bit zero) remains unchanged.
module gate_t (
    input wire signed [15:0] a_re, a_im, b_re, b_im,
    output wire signed [15:0] y_a_re, y_a_im, y_b_re, y_b_im
);
    assign y_a_re = a_re;
    assign y_a_im = a_im;
    wire signed [17:0] diff = $signed(b_re) - $signed(b_im);
    wire signed [17:0] sum  = $signed(b_re) + $signed(b_im);
    fx_arith u0(diff,y_b_re);
    fx_arith u1(sum,y_b_im);
endmodule
