module alu_tb;

    logic [31:0] a;
    logic [31:0] b;
    logic [2:0]  alu_control;
    logic [31:0] result;

    alu dut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result)
    );

    initial begin

        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        // Test ADD
        a = 10;
        b = 20;
        alu_control = 3'b000;
        #10;

        $display("ADD: %0d + %0d = %0d", a, b, result);

        // Test SUB
        a = 20;
        b = 10;
        alu_control = 3'b001;
        #10;

        $display("SUB: %0d - %0d = %0d", a, b, result);

        // Test AND
        a = 5;
        b = 3;
        alu_control = 3'b010;
        #10;

        $display("AND: %0d & %0d = %0d", a, b, result);

        // Test OR
        a = 5;
        b = 3;
        alu_control = 3'b011;
        #10;

        $display("OR: %0d | %0d = %0d", a, b, result);

        // Test XOR
        a = 5;
        b = 3;
        alu_control = 3'b100;
        #10;

        $display("XOR: %0d ^ %0d = %0d", a, b, result);

        $finish;

    end

endmodule