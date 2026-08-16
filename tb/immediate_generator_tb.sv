module immediate_generator_tb;

    logic [31:0] instruction;
    logic [31:0] immediate;

    immediate_generator dut (
        .instruction(instruction),
        .immediate(immediate)
    );

    initial begin

        // ADDI x7, x6, 5
        instruction = 32'h00530393;

        #10;

        $display("Instruction = %h", instruction);
        $display("Immediate   = %0d", immediate);

        $finish;

    end

endmodule
