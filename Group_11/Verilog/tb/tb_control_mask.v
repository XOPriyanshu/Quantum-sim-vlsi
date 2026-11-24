`timescale 1ns/1ps
module tb_control_mask;
    reg [2:0] control_q, target_q;
    reg [3:0] pair_addr_a, basis_addr;
    reg [5:0] mask, value;
    wire cnot_valid, cnot_swap, mcz_valid, mcz_flip;
    integer errors = 0;
    control_mask #(.N_QUBITS(4)) dut (
        .control_q(control_q), .target_q(target_q),
        .pair_addr_a(pair_addr_a), .basis_addr(basis_addr),
        .mask(mask), .value(value),
        .cnot_valid(cnot_valid), .cnot_swap(cnot_swap),
        .mcz_valid(mcz_valid), .mcz_flip(mcz_flip)
    );
    task check;
        input exp_cv, exp_cs, exp_mv, exp_mf;
        begin
            #1;
            if ({cnot_valid,cnot_swap,mcz_valid,mcz_flip} !==
                {exp_cv,exp_cs,exp_mv,exp_mf}) begin
                $display("FAIL: cv=%b cs=%b mv=%b mf=%b",cnot_valid,cnot_swap,mcz_valid,mcz_flip);
                errors = errors + 1;
            end
        end
    endtask
    initial begin
        control_q=2; target_q=1; pair_addr_a=4'b0100;
        basis_addr=4'b1010; mask=6'b001010; value=6'b001010;
        check(1,1,1,1);
        pair_addr_a=4'b0000; basis_addr=4'b1000;
        check(1,0,1,0);
        control_q=1; target_q=1;
        check(0,0,1,0);
        control_q=4; target_q=1;
        check(0,0,1,0);
        mask=6'b010000; value=0;
        check(0,0,0,0);
        mask=6'b000001; value=6'b000010;
        check(0,0,0,0);
        if (errors==0) $display("PASS: control_mask basic tests");
        else $fatal(1,"%0d failures",errors);
        $finish;
    end
endmodule
