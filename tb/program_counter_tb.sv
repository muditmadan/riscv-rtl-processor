module program_counter_tb;

    logic        clk;
    logic        reset;
    logic [31:0] pc;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .pc(pc)
    );

    // Generate clock
    always #5 clk = ~clk;

    initial begin

        // Start values
        clk = 0;
        reset = 1;

        // Reset the PC
        #10;

        $display("After reset: PC = %0d", pc);

        // Release reset
        reset = 0;

        // Wait for clock cycles
        #10;
        $display("Cycle 1: PC = %0d", pc);

        #10;
        $display("Cycle 2: PC = %0d", pc);

        #10;
        $display("Cycle 3: PC = %0d", pc);

        #10;
        $display("Cycle 4: PC = %0d", pc);

        $finish;

    end

endmodule