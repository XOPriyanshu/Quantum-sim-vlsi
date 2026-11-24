`timescale 1ns/1ps
module tb_grover;
    parameter integer LANES=1, PIPE_STAGES=1;
    localparam integer N_QUBITS=4, COUNT=16, MAX_WORDS=128;
    reg clk=0,rst_n=0,instr_valid=0;
    reg [31:0] instr=0;
    reg [3:0] rd_addr=0;
    wire ready,done,err;
    wire signed [15:0] rd_re,rd_im;
    wire [31:0] last_cycles;
    reg [31:0] prog [0:MAX_WORDS-1];
    reg [15:0] expected_re [0:COUNT-1],expected_im [0:COUNT-1];
    integer n_instr,i,errors=0,total_cycles=0,fd;
    reg [1023:0] output_file;
    qsim_parallel_top #(.N_QUBITS(4),.LANES(LANES),.PIPE_STAGES(PIPE_STAGES)) dut (
      .clk(clk),.rst_n(rst_n),.instr_valid(instr_valid),.instr(instr),
      .ready(ready),.done(done),.err(err),.rd_addr(rd_addr),
      .rd_re(rd_re),.rd_im(rd_im),.last_cycles(last_cycles));
    always #5 clk=~clk;
    initial begin
      $readmemh("tb/phase6_grover_instr.hex",prog);
      $readmemh("tb/phase6_expected_re.hex",expected_re);
      $readmemh("tb/phase6_expected_im.hex",expected_im);
      n_instr=prog[0];
      if(n_instr<=0 || n_instr>=MAX_WORDS) $fatal(1,"Invalid program length");
      repeat(3) @(negedge clk);rst_n=1;
      for(i=1;i<=n_instr;i=i+1) begin
        wait(ready);@(negedge clk);instr=prog[i];instr_valid=1;
        @(negedge clk);instr_valid=0;
        wait(done);total_cycles=total_cycles+last_cycles;
        @(negedge clk);
        if(err) $fatal(1,"Controller error at instruction %0d",i);
      end
      $sformat(output_file,"results/phase6_rtl_l%0d_p%0d.csv",LANES,PIPE_STAGES);
      fd=$fopen(output_file,"w");
      if(fd==0) $fatal(1,"Could not open result CSV");
      $fdisplay(fd,"index,real_q14,imag_q14");
      for(i=0;i<COUNT;i=i+1) begin
        @(negedge clk);rd_addr=i;#1;
        $fdisplay(fd,"%0d,%0d,%0d",i,$signed(rd_re),$signed(rd_im));
        if(rd_re!==expected_re[i] || rd_im!==expected_im[i]) begin
          $display("FAIL addr=%0d got=(%h,%h) expected=(%h,%h)",i,rd_re,rd_im,expected_re[i],expected_im[i]);
          errors=errors+1;
        end
      end
      $fclose(fd);
      if(errors!=0) $fatal(1,"FAIL: %0d mismatches",errors);
      $display("PASS: Grover 4q 3 iterations LANES=%0d PIPE_STAGES=%0d instructions=%0d amplitudes=16 cycles=%0d",LANES,PIPE_STAGES,n_instr,total_cycles);
      $finish;
    end
    initial begin #20000000;$fatal(1,"TIMEOUT");end
initial begin
    $dumpfile("results/figures/grover_waveform.vcd");
    $dumpvars(0, tb_grover);
end
endmodule
