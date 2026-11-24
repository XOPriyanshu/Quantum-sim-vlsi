`timescale 1ns/1ps

module addr_gen_checker #(
    parameter integer N_QUBITS = 4
)(
    output reg done,
    output reg passed
);
    localparam integer STATES = (1 << N_QUBITS);
    localparam integer PAIRS  = STATES / 2;
    reg [2:0] target_q;
    reg [N_QUBITS-2:0] pair_index;
    wire [N_QUBITS-1:0] addr_a, addr_b;
    wire valid;
    reg [STATES-1:0] seen;
    integer q, p, errors, expected_a, expected_b;
    integer bit_pos, lower_mask;

    addr_gen #(.N_QUBITS(N_QUBITS)) dut (
        .target_q(target_q), .pair_index(pair_index),
        .addr_a(addr_a), .addr_b(addr_b), .valid(valid)
    );

    initial begin
        done = 0;
        passed = 0;
        errors = 0;
        target_q = 0;
        pair_index = 0;
        #1;
        for (q = 0; q < N_QUBITS; q = q + 1) begin
            seen = {STATES{1'b0}};
            for (p = 0; p < PAIRS; p = p + 1) begin
                target_q = q;
                pair_index = p;
                #1;
                lower_mask = (1 << q) - 1;
                expected_a = (p & lower_mask) | ((p >> q) << (q + 1));
                expected_b = expected_a | (1 << q);
                if (valid !== 1'b1 || addr_a !== expected_a || addr_b !== expected_b) begin
                    $display("FAIL N=%0d q=%0d pair=%0d got=(%0d,%0d) valid=%b expected=(%0d,%0d)",
                        N_QUBITS, q, p, addr_a, addr_b, valid, expected_a, expected_b);
                    errors = errors + 1;
                end
                if (addr_a >= STATES || addr_b >= STATES || addr_a == addr_b) begin
                    $display("FAIL invalid addresses N=%0d q=%0d pair=%0d", N_QUBITS, q, p);
                    errors = errors + 1;
                end else begin
                    if (seen[addr_a] || seen[addr_b]) begin
                        $display("FAIL duplicate N=%0d q=%0d pair=%0d", N_QUBITS, q, p);
                        errors = errors + 1;
                    end
                    seen[addr_a] = 1'b1;
                    seen[addr_b] = 1'b1;
                end
            end
            if (seen !== {STATES{1'b1}}) begin
                $display("FAIL missing addresses N=%0d q=%0d seen=%h", N_QUBITS, q, seen);
                errors = errors + 1;
            end
        end
        // 3-bit target field supports invalid q values up to 7.
        for (q = N_QUBITS; q < 8; q = q + 1) begin
            target_q = q;
            pair_index = 0;
            #1;
            if (valid !== 1'b0) begin
                $display("FAIL invalid target accepted N=%0d q=%0d", N_QUBITS, q);
                errors = errors + 1;
            end
        end
        passed = (errors == 0);
        if (passed)
            $display("PASS: N_QUBITS=%0d, %0d pairs checked across %0d targets", N_QUBITS, PAIRS*N_QUBITS, N_QUBITS);
        else
            $display("FAIL: N_QUBITS=%0d errors=%0d", N_QUBITS, errors);
        done = 1;
    end
endmodule

module tb_addr_gen;
    wire done4, done5, done6;
    wire pass4, pass5, pass6;
    addr_gen_checker #(.N_QUBITS(4)) check4(done4, pass4);
    addr_gen_checker #(.N_QUBITS(5)) check5(done5, pass5);
    addr_gen_checker #(.N_QUBITS(6)) check6(done6, pass6);

    initial begin
        wait (done4 && done5 && done6);
        if (pass4 && pass5 && pass6)
            $display("PASS: all address generator tests (4/5/6 qubits)");
        else
            $fatal(1, "FAIL: address generator regression");
        $finish;
    end
endmodule
