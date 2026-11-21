`timescale 1ns/1ps
module tb_parallel;
    parameter integer N_QUBITS=4, LANES=1, PIPE_STAGES=3;
    localparam integer COUNT=1<<N_QUBITS;
    reg clk=0,rst_n=0,instr_valid=0;
    reg [31:0] instr=0;
    reg [N_QUBITS-1:0] rd_addr=0;
    wire ready,done,err;
    wire signed [15:0] rd_re,rd_im;
    wire [31:0] last_cycles;
    reg [31:0] prog [0:16];
    reg [15:0] expected_re [0:COUNT-1],expected_im [0:COUNT-1];
    reg [1023:0] file_name;
    integer n_instr,i,errors=0,total_cycles=0;
    qsim_parallel_top #(.N_QUBITS(N_QUBITS),.LANES(LANES),.PIPE_STAGES(PIPE_STAGES)) dut(
        .clk(clk),.rst_n(rst_n),.instr_valid(instr_valid),.instr(instr),
        .ready(ready),.done(done),.err(err),.rd_addr(rd_addr),
        .rd_re(rd_re),.rd_im(rd_im),.last_cycles(last_cycles));
    always #5 clk=~clk;
    initial begin
        $sformat(file_name,"tb/phase4_instr_n%0d.hex",N_QUBITS);$readmemh(file_name,prog);
        $sformat(file_name,"tb/phase4_expected_re_n%0d.hex",N_QUBITS);$readmemh(file_name,expected_re);
        $sformat(file_name,"tb/phase4_expected_im_n%0d.hex",N_QUBITS);$readmemh(file_name,expected_im);
        n_instr=prog[0];
        repeat(3) @(negedge clk);rst_n=1;
        for(i=1;i<=n_instr;i=i+1) begin
            wait(ready);@(negedge clk);instr=prog[i];instr_valid=1;
            @(negedge clk);instr_valid=0;
            wait(done);total_cycles=total_cycles+last_cycles;
            @(negedge clk);
            if(err) $fatal(1,"Controller error at instruction %0d",i);
        end
        for(i=0;i<COUNT;i=i+1) begin
            @(negedge clk);rd_addr=i;#1;
            if(rd_re!==expected_re[i]||rd_im!==expected_im[i]) begin
                $display("FAIL N=%0d L=%0d P=%0d addr=%0d got=(%h,%h) expected=(%h,%h)",N_QUBITS,LANES,PIPE_STAGES,i,rd_re,rd_im,expected_re[i],expected_im[i]);
                errors=errors+1;
            end
        end
        if(errors!=0) $fatal(1,"FAIL: %0d mismatches",errors);
        $display("PASS: N=%0d LANES=%0d PIPE_STAGES=%0d instructions=%0d amplitudes=%0d cycles=%0d",N_QUBITS,LANES,PIPE_STAGES,n_instr,COUNT,total_cycles);
        $finish;
    end
    initial begin #2000000;$fatal(1,"TIMEOUT");end
endmodule
