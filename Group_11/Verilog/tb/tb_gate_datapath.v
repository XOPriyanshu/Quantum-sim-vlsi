`timescale 1ns/1ps
`include "qsim_params.vh"
module tb_gate_datapath;
    reg [2:0] opcode;
    reg cnot_swap,mcz_flip_a,mcz_flip_b;
    reg signed [15:0] a_re,a_im,b_re,b_im;
    wire signed [15:0] y_a_re,y_a_im,y_b_re,y_b_im;
    wire valid_opcode;
    gate_datapath dut(opcode,cnot_swap,mcz_flip_a,mcz_flip_b,
        a_re,a_im,b_re,b_im,y_a_re,y_a_im,y_b_re,y_b_im,valid_opcode);
    integer fd,read_count,n=0,errors=0;
    integer op,cs,fa,fb,ar,ai,br,bi,er0,ei0,er1,ei1;
    initial begin
        opcode=0;cnot_swap=0;mcz_flip_a=0;mcz_flip_b=0;
        a_re=0;a_im=0;b_re=0;b_im=0;
        fd=$fopen("tb/phase3_cases.txt","r");
        if(fd==0) $fatal(1,"Missing tb/phase3_cases.txt: run python3 scripts/gen_phase3_cases.py");
        while (!$feof(fd)) begin
            read_count=$fscanf(fd,"%d %d %d %d %d %d %d %d %d %d %d %d\n",
                op,cs,fa,fb,ar,ai,br,bi,er0,ei0,er1,ei1);
            if(read_count==12) begin
                opcode=op;cnot_swap=cs;mcz_flip_a=fa;mcz_flip_b=fb;
                a_re=ar;a_im=ai;b_re=br;b_im=bi;
                #1;
                if(!valid_opcode || y_a_re!==er0 || y_a_im!==ei0 || y_b_re!==er1 || y_b_im!==ei1) begin
                    $display("FAIL case=%0d op=%0d got=(%0d,%0d,%0d,%0d) exp=(%0d,%0d,%0d,%0d)",
                        n,op,y_a_re,y_a_im,y_b_re,y_b_im,er0,ei0,er1,ei1);
                    errors=errors+1;
                end
                n=n+1;
            end else if(read_count!=-1) $fatal(1,"Malformed case file at case %0d",n);
        end
        $fclose(fd);
        if(n!=1500) $fatal(1,"Expected 1500 cases, found %0d",n);
        opcode=3'd7;#1;
        if(valid_opcode!==1'b0) $fatal(1,"Invalid opcode was accepted");
        if(errors) $fatal(1,"FAIL: %0d errors in %0d tests",errors,n);
        $display("PASS: all %0d Python-reference datapath cases (H/X/Z/T/CNOT/MCZ)",n);
        $finish;
    end
endmodule
