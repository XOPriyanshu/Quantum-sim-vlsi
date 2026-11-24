`timescale 1ns/1ps
`include "qsim_params.vh"

module tb_qsim_top;
    parameter integer N_QUBITS = 4;
    reg clk = 0;
    reg rst_n = 0;
    reg instr_valid = 0;
    reg [31:0] instr = 0;
    reg [N_QUBITS-1:0] rd_addr = 0;
    wire ready, done, err;
    wire signed [15:0] rd_re, rd_im;
    integer errors = 0;

    qsim_top #(.N_QUBITS(N_QUBITS)) dut (
        .clk(clk), .rst_n(rst_n), .instr_valid(instr_valid), .instr(instr),
        .ready(ready), .done(done), .rd_addr(rd_addr),
        .rd_re(rd_re), .rd_im(rd_im), .err(err)
    );
    always #5 clk = ~clk;

    function [31:0] make_instr;
        input [2:0] op, tgt, ctl;
        input [5:0] msk, val;
        begin
            make_instr = {11'b0, val, msk, ctl, tgt, op};
        end
    endfunction

    task reset_dut;
        begin
            @(negedge clk); rst_n=0; instr_valid=0; instr=0;
            repeat (2) @(negedge clk);
            rst_n=1;
            wait (ready == 1'b1);
            @(negedge clk);
        end
    endtask

    task apply_gate;
        input [31:0] word;
        begin
            wait (ready == 1'b1);
            @(negedge clk); instr=word; instr_valid=1;
            @(negedge clk); instr_valid=0; instr=0;
            wait (done == 1'b1);
            @(negedge clk);
            if (err) begin
                $display("FAIL: unexpected sticky err after instruction %h", word);
                errors=errors+1;
            end
        end
    endtask

    task check_amp;
        input integer address;
        input integer expected_re;
        input integer expected_im;
        begin
            @(negedge clk); rd_addr=address; #1;
            if (($signed(rd_re) !== expected_re) || ($signed(rd_im) !== expected_im)) begin
                $display("FAIL N=%0d addr=%0d got=(%0d,%0d) expected=(%0d,%0d)",
                         N_QUBITS,address,$signed(rd_re),$signed(rd_im),expected_re,expected_im);
                errors=errors+1;
            end
        end
    endtask

    initial begin
        // Reset state must be |00...0>.
        reset_dut();
        check_amp(0,16384,0);
        check_amp(1,0,0);

        // H on q0: |0> -> (|0>+|1>)/sqrt(2).
        reset_dut();
        apply_gate(make_instr(`QSIM_OP_H,0,0,0,0));
        check_amp(0,11585,0);
        check_amp(1,11585,0);

        // X on q0: |0> -> |1>.
        reset_dut();
        apply_gate(make_instr(`QSIM_OP_X,0,0,0,0));
        check_amp(0,0,0);
        check_amp(1,16384,0);

        // Z on q0 negates the target-bit-one amplitude.
        reset_dut();
        apply_gate(make_instr(`QSIM_OP_X,0,0,0,0));
        apply_gate(make_instr(`QSIM_OP_Z,0,0,0,0));
        check_amp(1,-16384,0);

        // Project T convention: (1+j)/sqrt(2) on target-bit-one amplitude.
        reset_dut();
        apply_gate(make_instr(`QSIM_OP_X,0,0,0,0));
        apply_gate(make_instr(`QSIM_OP_T,0,0,0,0));
        check_amp(1,11585,11585);

        // CNOT control q0, target q1: |01> -> |11>.
        reset_dut();
        apply_gate(make_instr(`QSIM_OP_X,0,0,0,0));
        apply_gate(make_instr(`QSIM_OP_CNOT,1,0,0,0));
        check_amp(1,0,0);
        check_amp(3,16384,0);

        // MCZ with mask=000001,value=000001 flips basis state |...0001>.
        reset_dut();
        apply_gate(make_instr(`QSIM_OP_X,0,0,0,0));
        apply_gate(make_instr(`QSIM_OP_MCZ,0,0,6'b000001,6'b000001));
        check_amp(1,-16384,0);

        // Illegal CNOT with control==target must set sticky error and not execute.
        reset_dut();
        wait (ready);
        @(negedge clk); instr=make_instr(`QSIM_OP_CNOT,1,1,0,0); instr_valid=1;
        @(negedge clk); instr_valid=0; instr=0; #1;
        if (!err || !ready) begin
            $display("FAIL: illegal instruction was not rejected (err=%b ready=%b)",err,ready);
            errors=errors+1;
        end

        if (errors==0)
            $display("PASS: qsim_top integration tests for N_QUBITS=%0d",N_QUBITS);
        else
            $fatal(1,"FAIL: %0d integration errors for N_QUBITS=%0d",errors,N_QUBITS);
        $finish;
    end
endmodule
