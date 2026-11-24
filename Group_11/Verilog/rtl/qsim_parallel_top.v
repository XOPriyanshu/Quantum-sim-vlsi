`include "qsim_params.vh"
// Phase 5: register-array multiport implementation, one pair per lane.
// Pipeline latency is PIPE_STAGES clocks. One batch is issued only after
// the previous batch commits, avoiding RAW hazards without forwarding.
// This is deliberately a conservative, conflict-free baseline.
module qsim_parallel_top #(
    parameter integer N_QUBITS=4,
    parameter integer LANES=2,
    parameter integer PIPE_STAGES=3,
    parameter integer DATA_WIDTH=16
)(
    input wire clk, rst_n, instr_valid,
    input wire [31:0] instr,
    output wire ready,
    output reg done, err,
    input wire [N_QUBITS-1:0] rd_addr,
    output wire signed [DATA_WIDTH-1:0] rd_re, rd_im,
    output reg [31:0] last_cycles
);
    localparam integer COUNT=(1<<N_QUBITS);
    localparam integer PAIRS=COUNT/2;
    localparam integer IDX_W=N_QUBITS-1;
    localparam [1:0] ST_IDLE=2'd0,ST_ISSUE=2'd1,ST_WAIT=2'd2,ST_DONE=2'd3;
    reg [1:0] fsm;
    reg [31:0] active_instr;
    reg [IDX_W:0] next_pair;
    reg [31:0] cycles;
    reg [31:0] wait_count;
    reg signed [DATA_WIDTH-1:0] mem_re [0:COUNT-1];
    reg signed [DATA_WIDTH-1:0] mem_im [0:COUNT-1];
    reg [PIPE_STAGES-1:0] valid_pipe;
    reg [N_QUBITS-1:0] pa [0:PIPE_STAGES-1][0:LANES-1];
    reg [N_QUBITS-1:0] pb [0:PIPE_STAGES-1][0:LANES-1];
    reg signed [15:0] pra [0:PIPE_STAGES-1][0:LANES-1];
    reg signed [15:0] pia [0:PIPE_STAGES-1][0:LANES-1];
    reg signed [15:0] prb [0:PIPE_STAGES-1][0:LANES-1];
    reg signed [15:0] pib [0:PIPE_STAGES-1][0:LANES-1];
    reg [LANES-1:0] lane_valid [0:PIPE_STAGES-1];
    wire [2:0] opcode=active_instr[2:0];
    wire [2:0] target=active_instr[5:3];
    wire [2:0] control=active_instr[8:6];
    wire [5:0] mask=active_instr[14:9];
    wire [5:0] value=active_instr[20:15];
    wire [2:0] pair_target=(opcode==`QSIM_OP_MCZ)?3'd0:target;
    wire [LANES-1:0] active_lane;
    wire [N_QUBITS-1:0] aa[0:LANES-1],bb[0:LANES-1];
    wire signed [15:0] ya_re[0:LANES-1],ya_im[0:LANES-1],yb_re[0:LANES-1],yb_im[0:LANES-1];
    wire [LANES-1:0] addr_ok,dp_ok; // diagnostic validity outputs
    genvar g;
    generate for(g=0;g<LANES;g=g+1) begin: lane
        wire [IDX_W-1:0] idx=IDX_W'(next_pair+g);
        wire cvalid,cswap,mvalid_a,mflip_a,mvalid_b,mflip_b;
        assign active_lane[g]=(($unsigned(next_pair)+g)<PAIRS);
        addr_gen #(.N_QUBITS(N_QUBITS)) u_addr(.target_q(pair_target),.pair_index(idx),.addr_a(aa[g]),.addr_b(bb[g]),.valid(addr_ok[g]));
        control_mask #(.N_QUBITS(N_QUBITS)) ca(.control_q(control),.target_q(target),.pair_addr_a(aa[g]),.basis_addr(aa[g]),.mask(mask),.value(value),.cnot_valid(cvalid),.cnot_swap(cswap),.mcz_valid(mvalid_a),.mcz_flip(mflip_a));
        control_mask #(.N_QUBITS(N_QUBITS)) cb(.control_q(control),.target_q(target),.pair_addr_a(bb[g]),.basis_addr(bb[g]),.mask(mask),.value(value),.cnot_valid(),.cnot_swap(),.mcz_valid(mvalid_b),.mcz_flip(mflip_b));
        gate_datapath dp(.opcode(opcode),.cnot_swap(cvalid&&cswap),.mcz_flip_a(mvalid_a&&mflip_a),.mcz_flip_b(mvalid_b&&mflip_b),.a_re(mem_re[aa[g]]),.a_im(mem_im[aa[g]]),.b_re(mem_re[bb[g]]),.b_im(mem_im[bb[g]]),.y_a_re(ya_re[g]),.y_a_im(ya_im[g]),.y_b_re(yb_re[g]),.y_b_im(yb_im[g]),.valid_opcode(dp_ok[g]));
    end endgenerate
    assign rd_re=mem_re[rd_addr];
    assign rd_im=mem_im[rd_addr];
    assign ready=(fsm==ST_IDLE);
    function instruction_ok;
        input [31:0] w;
        reg [2:0] op,t,c;
        reg [5:0] m,v;
        begin
            op=w[2:0];t=w[5:3];c=w[8:6];m=w[14:9];v=w[20:15];
            instruction_ok=(w[31:21]==0)&&(op<=`QSIM_OP_MCZ);
            if(op<=`QSIM_OP_T) instruction_ok=instruction_ok&&(t<3'(N_QUBITS));
            else if(op==`QSIM_OP_CNOT) instruction_ok=instruction_ok&&(t<3'(N_QUBITS))&&(c<3'(N_QUBITS))&&(c!=t);
            else if(op==`QSIM_OP_MCZ) instruction_ok=instruction_ok&&((m>>(N_QUBITS))==0)&&((v&~m)==0);
        end
    endfunction
    integer i,j;
    // synopsys translate_off
    initial begin
        if(N_QUBITS<4||N_QUBITS>6||DATA_WIDTH!=16||PIPE_STAGES<1||LANES<1||LANES>8) $fatal(1,"Unsupported Phase 5 parameters");
    end
    // synopsys translate_on
    always @(posedge clk) begin
        if(!rst_n) begin
            fsm<=ST_IDLE;active_instr<=0;next_pair<=0;cycles<=0;last_cycles<=0;wait_count<=0;done<=0;err<=0;
            valid_pipe<=0;
            for(i=0;i<COUNT;i=i+1) begin mem_re[i]<=0;mem_im[i]<=0;end
            mem_re[0]<=`QSIM_ONE_Q14;
            for(i=0;i<PIPE_STAGES;i=i+1) lane_valid[i]<=0;
        end else begin
            done<=0;
            // Final pipeline stage writes one distinct pair per valid lane.
            if(valid_pipe[PIPE_STAGES-1]) begin
                for(j=0;j<LANES;j=j+1) if(lane_valid[PIPE_STAGES-1][j]) begin
                    mem_re[pa[PIPE_STAGES-1][j]]<=pra[PIPE_STAGES-1][j];
                    mem_im[pa[PIPE_STAGES-1][j]]<=pia[PIPE_STAGES-1][j];
                    mem_re[pb[PIPE_STAGES-1][j]]<=prb[PIPE_STAGES-1][j];
                    mem_im[pb[PIPE_STAGES-1][j]]<=pib[PIPE_STAGES-1][j];
                end
            end
            for(i=PIPE_STAGES-1;i>0;i=i-1) begin
                valid_pipe[i]<=valid_pipe[i-1];lane_valid[i]<=lane_valid[i-1];
                for(j=0;j<LANES;j=j+1) begin
                    pa[i][j]<=pa[i-1][j];pb[i][j]<=pb[i-1][j];
                    pra[i][j]<=pra[i-1][j];pia[i][j]<=pia[i-1][j];
                    prb[i][j]<=prb[i-1][j];pib[i][j]<=pib[i-1][j];
                end
            end
            valid_pipe[0]<=0;lane_valid[0]<=0;
            if(fsm!=ST_IDLE) cycles<=cycles+1;
            case(fsm)
                ST_IDLE: if(instr_valid) begin
                    if(instruction_ok(instr)) begin
                        active_instr<=instr;next_pair<=0;cycles<=0;fsm<=ST_ISSUE;
                    end else err<=1;
                end
                ST_ISSUE: begin
                    valid_pipe[0]<=1;
                    for(j=0;j<LANES;j=j+1) begin
                        lane_valid[0][j]<=active_lane[j];
                        pa[0][j]<=aa[j];pb[0][j]<=bb[j];
                        pra[0][j]<=ya_re[j];pia[0][j]<=ya_im[j];
                        prb[0][j]<=yb_re[j];pib[0][j]<=yb_im[j];
                    end
                    if(($unsigned(next_pair)+LANES)>=PAIRS) begin
                        wait_count<=PIPE_STAGES;fsm<=ST_WAIT;
                    end else begin
                        // Conservative drain before next batch prevents RAW hazards.
                        wait_count<=PIPE_STAGES;fsm<=ST_WAIT;
                    end
                end
                ST_WAIT: begin
                    if(wait_count==0) begin
                        if(($unsigned(next_pair)+LANES)>=PAIRS) fsm<=ST_DONE;
                        else begin next_pair<=(IDX_W+1)'(next_pair+LANES);fsm<=ST_ISSUE;end
                    end else wait_count<=wait_count-1;
                end
                ST_DONE: begin done<=1;last_cycles<=cycles+1;fsm<=ST_IDLE;end
            endcase
        end
    end
endmodule
