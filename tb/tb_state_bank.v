`timescale 1ns/1ps
module state_bank_case #(parameter N=4)(output reg done);
  localparam COUNT = (1 << N);
  reg clk=0, rst_n=1, wr_en=0;
  always #5 clk=~clk;
  reg [N-1:0] rd_addr=0, pair_addr_a=0, pair_addr_b=1;
  reg [N-1:0] wr_addr_a=0, wr_addr_b=1;
  reg signed [15:0] wr_a_re=0, wr_a_im=0, wr_b_re=0, wr_b_im=0;
  wire signed [15:0] rd_re,rd_im,pair_a_re,pair_a_im,pair_b_re,pair_b_im;
  integer i;
  state_bank #(.N_QUBITS(N),.DATA_WIDTH(16)) dut (
    .clk(clk),.rst_n(rst_n),.rd_addr(rd_addr),.rd_re(rd_re),.rd_im(rd_im),
    .pair_addr_a(pair_addr_a),.pair_addr_b(pair_addr_b),
    .pair_a_re(pair_a_re),.pair_a_im(pair_a_im),.pair_b_re(pair_b_re),.pair_b_im(pair_b_im),
    .wr_en(wr_en),.wr_addr_a(wr_addr_a),.wr_addr_b(wr_addr_b),
    .wr_a_re(wr_a_re),.wr_a_im(wr_a_im),.wr_b_re(wr_b_re),.wr_b_im(wr_b_im));
  task check;
    input signed [15:0] actual, expected;
    input [255:0] description;
    begin
      if (actual !== expected) begin
        $display("FAIL: N=%0d %0s got=%0d expected=%0d",N,description,actual,expected);
        $fatal(1);
      end
    end
  endtask
  initial begin
    done=0;
    // Synchronous active-low reset: assert across a rising edge.
    rst_n=0;
    @(negedge clk); rst_n=1;
    #1;
    for(i=0;i<COUNT;i=i+1) begin
      rd_addr=i; #1;
      check(rd_re,(i==0)?16'sd16384:16'sd0,"reset real");
      check(rd_im,16'sd0,"reset imaginary");
    end
    // Two distinct write addresses, with positive and negative complex data.
    @(negedge clk);
    wr_en=1; wr_addr_a=2; wr_addr_b=COUNT-1;
    wr_a_re=16'sd4096; wr_a_im=-16'sd2048;
    wr_b_re=-16'sd8192; wr_b_im=16'sd1024;
    @(negedge clk); wr_en=0;
    pair_addr_a=2; pair_addr_b=COUNT-1; #1;
    check(pair_a_re,16'sd4096,"pair A real");
    check(pair_a_im,-16'sd2048,"pair A imaginary");
    check(pair_b_re,-16'sd8192,"pair B real");
    check(pair_b_im,16'sd1024,"pair B imaginary");
    rd_addr=2; #1;
    check(rd_re,16'sd4096,"single read real");
    check(rd_im,-16'sd2048,"single read imaginary");
    // No write when disabled.
    wr_a_re=16'sd123; wr_b_re=16'sd456;
    repeat(2) @(negedge clk);
    #1;
    check(pair_a_re,16'sd4096,"write-disabled A");
    check(pair_b_re,-16'sd8192,"write-disabled B");
    // Reset again after modifying storage.
    rst_n=0;
    @(negedge clk); rst_n=1;
    #1;
    for(i=0;i<COUNT;i=i+1) begin
      rd_addr=i; #1;
      check(rd_re,(i==0)?16'sd16384:16'sd0,"second reset real");
      check(rd_im,16'sd0,"second reset imaginary");
    end
    $display("PASS: N_QUBITS=%0d, %0d amplitudes initialized and verified",N,COUNT);
    done=1;
  end
endmodule

module tb_state_bank;
  wire done4,done5,done6;
  state_bank_case #(.N(4)) test4(done4);
  state_bank_case #(.N(5)) test5(done5);
  state_bank_case #(.N(6)) test6(done6);
  initial begin
    wait(done4 && done5 && done6);
    $display("PASS: all state bank tests (4/5/6 qubits)");
    $finish;
  end
  initial begin
    #100000;
    $display("FAIL: testbench timeout");
    $fatal(1);
  end
endmodule
