module datapath_tb;

    logic clk;
    logic reset;

    datapath dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    task check_reg(input int addr, input int expected, input string name);
        if (dut.reg_file.registers[addr] !== expected) begin
            $display("FAIL %s: x%0d=%0d (expected %0d)", name, addr, dut.reg_file.registers[addr], expected);
            $fatal(1);
        end
        else
            $display("PASS %s: x%0d=%0d", name, addr, expected);
    endtask

    initial begin
        $dumpfile("datapath.vcd");
        $dumpvars(0, datapath_tb);

        clk = 0;
        reset = 1;

        #12;
        reset = 0;

        // Enough cycles to run through the full program including JALR
        #400;

        $display("\n=== Register File Verification ===");
        check_reg(1,  88,  "x1 after JALR setup");
        check_reg(2,  5,   "x2");
        check_reg(3,  15,  "x3 ADD result");
        check_reg(4,  5,   "x4 SUB result");
        check_reg(5,  0,   "x5 AND result");
        check_reg(6,  15,  "x6 OR result");
        check_reg(7,  100, "x7 memory base");
        check_reg(8,  15,  "x8 LW result");
        check_reg(9,  0,   "x9 skipped by BEQ");
        check_reg(10, 1,   "x10 BEQ target");
        check_reg(11, 0,   "x11 skipped by BNE");
        check_reg(12, 2,   "x12 BNE target");
        check_reg(13, 64,  "x13 JAL link");
        check_reg(14, 0,   "x14 skipped by JAL");
        check_reg(15, 3,   "x15 JAL target");
        check_reg(16, 80,  "x16 JALR link");
        check_reg(17, 42,  "x17 JALR landing");

        if (dut.data_mem.memory[25] !== 32'd15)
            $fatal(1, "FAIL mem[100]: got %0d expected 15", dut.data_mem.memory[25]);
        else
            $display("PASS mem[100]=15 (SW/LW)");

        $display("\nAll datapath tests passed.");
        $finish;
    end

endmodule
