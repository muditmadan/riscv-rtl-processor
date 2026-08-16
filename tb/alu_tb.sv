// ============================================================
// alu_tb.sv — ALU unit testbench
//
// alu_control encoding (must match rtl/alu.sv):
//   3'b000  ADD
//   3'b001  SUB
//   3'b010  AND
//   3'b011  OR
//   3'b100  XOR
//
// Each test prints:
//   TEST <name>
//   Expected result = <value>
//   Actual   result = <value>
//   PASS / FAIL
// ============================================================

`timescale 1ns/1ps

module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [2:0]  alu_control;
    logic [31:0] result;

    int pass_count;
    int fail_count;

    alu dut (
        .a          (a),
        .b          (b),
        .alu_control(alu_control),
        .result     (result)
    );

    // Self-checking task
    task automatic check(
        input string   op_name,
        input logic [31:0] a_in,
        input logic [31:0] b_in,
        input logic [2:0]  ctrl,
        input int          expected
    );
        int actual;
        a           = a_in;
        b           = b_in;
        alu_control = ctrl;
        #1; // allow combinational propagation
        actual = int'(result);
        $display("TEST  %s", op_name);
        $display("  Expected  result = %0d", expected);
        $display("  Actual    result = %0d", actual);
        if (actual === expected) begin
            $display("  --> PASS\n");
            pass_count++;
        end else begin
            $display("  --> FAIL\n");
            fail_count++;
        end
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("==================================");
        $display("  ALU Unit Testbench");
        $display("==================================");
        $display("");

        // ADD: 10 + 20 = 30
        check("ADD  10 + 20",  32'd10, 32'd20, 3'b000, 30);

        // ADD negative: -5 + 3 = -2 (two's complement)
        check("ADD  -5 + 3",   32'hFFFFFFFB, 32'd3, 3'b000, -2);

        // SUB: 20 - 10 = 10
        check("SUB  20 - 10",  32'd20, 32'd10, 3'b001, 10);

        // SUB producing zero (used by BEQ comparison)
        check("SUB  7 - 7 = 0", 32'd7, 32'd7, 3'b001, 0);

        // AND: 0b01010 & 0b10100 = 0
        check("AND  10 & 20",   32'd10, 32'd20, 3'b010, 0);

        // AND: 0b0101 & 0b0011 = 0b0001 = 1
        check("AND  5 & 3",     32'd5,  32'd3,  3'b010, 1);

        // OR: 0b01010 | 0b10100 = 0b11110 = 30
        check("OR   10 | 20",   32'd10, 32'd20, 3'b011, 30);

        // OR: 5 | 3 = 7
        check("OR   5 | 3",     32'd5,  32'd3,  3'b011, 7);

        // XOR: 5 ^ 3 = 6
        check("XOR  5 ^ 3",     32'd5,  32'd3,  3'b100, 6);

        // XOR with itself = 0
        check("XOR  x ^ x = 0", 32'd42, 32'd42, 3'b100, 0);

        $display("==================================");
        $display("  RESULTS : %0d PASSED,  %0d FAILED", pass_count, fail_count);
        $display("==================================");

        if (fail_count != 0)
            $fatal(1, "ALU testbench FAILED.");

        $finish;
    end

endmodule
