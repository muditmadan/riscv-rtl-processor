module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:31];

    initial begin

        // ADDI x1, x0, 16  (PC=0: x1 = 16)
        memory[0] = 32'h01000093;

        // JALR x5, 4(x1)  (PC=4: jump to x1+4=20, save PC+4=8 to x5)
        memory[1] = 32'h004082E7;

        // skipped (PC=8)
        memory[2] = 32'h00000000;

        // skipped (PC=12)
        memory[3] = 32'h00000000;

        // skipped (PC=16)
        memory[4] = 32'h00000000;

        // skipped (PC=20, will be at address 20>>2 = 5)
        memory[5] = 32'h00000000;

        // ADDI x2, x0, 55  (PC=24: x2 = 55, verification)
        memory[6] = 32'h03700113;

    end

    always_comb begin

        instruction = memory[address >> 2];

    end

endmodule