module gate_x (
    input wire signed [15:0] a_re, a_im, b_re, b_im,
    output wire signed [15:0] y_a_re, y_a_im, y_b_re, y_b_im
);
    assign y_a_re=b_re, y_a_im=b_im, y_b_re=a_re, y_b_im=a_im;
endmodule

module gate_z (
    input wire signed [15:0] a_re, a_im, b_re, b_im,
    output wire signed [15:0] y_a_re, y_a_im, y_b_re, y_b_im
);
    assign y_a_re=a_re, y_a_im=a_im;
    fx_negate u0(b_re,y_b_re);
    fx_negate u1(b_im,y_b_im);
endmodule
