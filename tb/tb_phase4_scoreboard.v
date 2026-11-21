`timescale 1ns/1ps
`include "qsim_params.vh"

module tb_phase4_scoreboard;
    parameter integer N_QUBITS = 4;
    localparam integer STATE_COUNT = (1 << N_QUBITS);
    localparam integer MAX_INS = 16;

    reg clk = 0;
    reg rst_n = 0;
    reg instr_valid = 0;
    reg [31:0] instr = 0;
    reg [N_QUBITS-1:0] rd_addr = 0;
    wire ready, done, err;
    wire signed [15:0] rd_re, rd_im;

    reg [31:0] program_mem [0:MAX_INS];
    reg [15:0] expected_re [0:STATE_COUNT-1];
    reg [15:0] expected_im [0:STATE_COUNT-1];
    integer instruction_count;
    integer k, addr, errors;
    string instr_file, re_file, im_file;

    qsim_top #(.N_QUBITS(N_QUBITS)) dut (
        .clk(clk), .rst_n(rst_n), .instr_valid(instr_valid), .instr(instr),
        .ready(ready), .done(done), .rd_addr(rd_addr),
        .rd_re(rd_re), .rd_im(rd_im), .err(err)
    );
    always #5 clk = ~clk;

    task reset_dut;
        begin
            @(negedge clk); rst_n = 0; instr_valid = 0; instr = 0;
            repeat (2) @(negedge clk);
            rst_n = 1;
            wait (ready === 1'b1);
            @(negedge clk);
        end
    endtask

    task send_instruction;
        input [31:0] word;
        begin
            wait (ready === 1'b1);
            @(negedge clk); instr = word; instr_valid = 1;
            @(negedge clk); instr_valid = 0; instr = 0;
            wait (done === 1'b1);
            @(negedge clk);
            if (err !== 1'b0) begin
                $display("FAIL: sticky err while running valid program: %h", word);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        $sformat(instr_file, "tb/phase4_instr_n%0d.hex", N_QUBITS);
        $sformat(re_file, "tb/phase4_expected_re_n%0d.hex", N_QUBITS);
        $sformat(im_file, "tb/phase4_expected_im_n%0d.hex", N_QUBITS);
        $readmemh(instr_file, program_mem);
        $readmemh(re_file, expected_re);
        $readmemh(im_file, expected_im);
        instruction_count = program_mem[0];
        if (instruction_count < 1 || instruction_count > MAX_INS)
            $fatal(1, "Bad instruction count %0d for N=%0d", instruction_count, N_QUBITS);

        reset_dut();
        for (k = 0; k < instruction_count; k = k + 1)
            send_instruction(program_mem[k+1]);

        // Compare EVERY final real and imaginary amplitude with Python Q2.14.
        for (addr = 0; addr < STATE_COUNT; addr = addr + 1) begin
            @(negedge clk); rd_addr = addr; #1;
            if (($signed(rd_re) !== $signed(expected_re[addr])) ||
                ($signed(rd_im) !== $signed(expected_im[addr]))) begin
                $display("MISMATCH N=%0d addr=%0d RTL=(%0d,%0d) PY=(%0d,%0d)",
                         N_QUBITS, addr, $signed(rd_re), $signed(rd_im),
                         $signed(expected_re[addr]), $signed(expected_im[addr]));
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS: Python scoreboard N=%0d; %0d instructions; all %0d complex amplitudes match",
                     N_QUBITS, instruction_count, STATE_COUNT);
        else
            $fatal(1, "FAIL: %0d amplitude/instruction errors for N=%0d", errors, N_QUBITS);
        $finish;
    end
endmodule
