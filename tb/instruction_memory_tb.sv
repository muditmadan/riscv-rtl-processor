module instruction_memory_tb;

    logic [31:0] address;
    logic [31:0] instruction;

    instruction_memory dut (
        .address(address),
        .instruction(instruction)
    );

    initial begin

        address = 32'd0;
        #1;
        $display("Address %0d: Instruction = %h", address, instruction);

        address = 32'd4;
        #1;
        $display("Address %0d: Instruction = %h", address, instruction);

        address = 32'd8;
        #1;
        $display("Address %0d: Instruction = %h", address, instruction);

        address = 32'd12;
        #1;
        $display("Address %0d: Instruction = %h", address, instruction);

        $finish;

    end

endmodule