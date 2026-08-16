module decoder_tb;

    logic [31:0] instruction;

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;

    logic [3:0] alu_control;

    decoder dut (
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_control(alu_control)
    );

    initial begin

        // ADD x3, x1, x2
        instruction = 32'h002081B3;
        #1;

        $display(
            "ADD: rs1=%0d rs2=%0d rd=%0d ALU=%b",
            rs1, rs2, rd, alu_control
        );

        // SUB x4, x3, x1
        instruction = 32'h40118233;
        #1;

        $display(
            "SUB: rs1=%0d rs2=%0d rd=%0d ALU=%b",
            rs1, rs2, rd, alu_control
        );

        // AND x5, x3, x4
        instruction = 32'h0041F2B3;
        #1;

        $display(
            "AND: rs1=%0d rs2=%0d rd=%0d ALU=%b",
            rs1, rs2, rd, alu_control
        );

        // OR x6, x3, x4
        instruction = 32'h0041E333;
        #1;

        $display(
            "OR: rs1=%0d rs2=%0d rd=%0d ALU=%b",
            rs1, rs2, rd, alu_control
        );

        $finish;

    end

endmodule