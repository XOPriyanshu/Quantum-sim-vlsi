// MCZ can negate either/both amplitudes, independently.
// flip_a / flip_b come from control_mask.mcz_flip for each basis index.
module gate_mcz (
    input wire flip_a, flip_b,
    input wire signed [15:0] a_re, a_im, b_re, b_im,
    output wire signed [15:0] y_a_re, y_a_im, y_b_re, y_b_im
);
    wire signed [15:0] na_re,na_im,nb_re,nb_im;
    fx_negate u0(a_re,na_re); fx_negate u1(a_im,na_im);
    fx_negate u2(b_re,nb_re); fx_negate u3(b_im,nb_im);
    assign y_a_re=flip_a ? na_re : a_re;
    assign y_a_im=flip_a ? na_im : a_im;
    assign y_b_re=flip_b ? nb_re : b_re;
    assign y_b_im=flip_b ? nb_im : b_im;
endmodule
