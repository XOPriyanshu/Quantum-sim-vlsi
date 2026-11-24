`include "qsim_params.vh"
// Signed Q2.14 helpers: 18-bit intermediate -> 34-bit product -> 16-bit saturated result.
// Matches python/fixed_point.py: (x*11585 + 8192) >>> 14, then clamp.
module fx_arith (
    input wire signed [17:0] x,
    output reg signed [15:0] scaled
);
    wire signed [33:0] product = x * 16'sd11585;
    wire signed [33:0] rounded = (product + 34'sd8192) >>> 14;
    always @* begin
        if (rounded > 34'sd32767) scaled = 16'sd32767;
        else if (rounded < -34'sd32768) scaled = -16'sd32768;
        else scaled = rounded[15:0];
    end
endmodule

// Saturating signed negation (special case -32768 -> +32767).
module fx_negate (
    input wire signed [15:0] x,
    output wire signed [15:0] y
);
    assign y = (x == -16'sd32768) ? 16'sd32767 : -x;
endmodule
