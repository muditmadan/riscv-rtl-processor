module decoder_tb;

    logic [31:0] instruction;

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [2:0] alu_control;

    decoder dut (
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_control(alu_control)
    );

    task check(
        input string name,
        input [4:0] exp_rs1,
        input [4:0] exp_rs2,
        input [4:0] exp_rd,
        input [2:0] exp_alu
    );
        if (rs1 !== exp_rs1 || rs2 !== exp_rs2 || rd !== exp_rd || alu_control !== exp_alu) begin
            $display("FAIL %s: rs1=%0d rs2=%0d rd=%0d alu=%b (expected rs1=%0d rs2=%0d rd=%0d alu=%b)",
                     name, rs1, rs2, rd, alu_control, exp_rs1, exp_rs2, exp_rd, exp_alu);
            $fatal(1);
        end
        else
            $display("PASS %s", name);
    endtask

    initial begin
        instruction = 32'h002081B3; // ADD x3, x1, x2
        #1;
        check("ADD", 5'd1, 5'd2, 5'd3, 3'b001);

        instruction = 32'h40208233; // SUB x4, x1, x2
        #1;
        check("SUB", 5'd1, 5'd2, 5'd4, 3'b010);

        instruction = 32'h0020F2B3; // AND x5, x1, x2
        #1;
        check("AND", 5'd1, 5'd2, 5'd5, 3'b011);

        instruction = 32'h0020E333; // OR x6, x1, x2
        #1;
        check("OR", 5'd1, 5'd2, 5'd6, 3'b100);

        instruction = 32'h00508193; // ADDI x3, x1, 5
        #1;
        check("ADDI", 5'd1, 5'd5, 5'd3, 3'b001);

        instruction = 32'h0002A503; // LW x10, 0(x5)
        #1;
        check("LW", 5'd5, 5'd0, 5'd10, 3'b001);

        instruction = 32'h0032A023; // SW x3, 0(x5)
        #1;
        check("SW", 5'd5, 5'd3, 5'd0, 3'b001);

        instruction = 32'h00208463; // BEQ x1, x2, 8
        #1;
        check("BEQ", 5'd1, 5'd2, 5'd8, 3'b010);

        instruction = 32'h00209463; // BNE x1, x2, 8
        #1;
        check("BNE", 5'd1, 5'd2, 5'd8, 3'b010);

        instruction = 32'h008006EF; // JAL x13, 8
        #1;
        check("JAL", 5'd0, 5'd8, 5'd13, 3'b000);

        instruction = 32'h004088E7; // JALR x17, 4(x1)
        #1;
        check("JALR", 5'd1, 5'd4, 5'd17, 3'b001);

        $display("All decoder tests passed.");
        $finish;
    end

endmodule
