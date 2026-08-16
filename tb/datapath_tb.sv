module datapath_tb;

    logic clk;
    logic reset;

    datapath dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("datapath.vcd");
        $dumpvars(0, datapath_tb);

        clk = 0;
        reset = 1;

        #12;
        reset = 0;

        #200;
        
        // Print register file contents to verify JAL saved PC+4
        $display("\n=== Register File Contents ===");
        $display("x1=%0d", dut.reg_file.registers[1]);
        $display("x5=%0d (should be 8, the return address)", dut.reg_file.registers[5]);
        
        $finish;
    end

endmodule
