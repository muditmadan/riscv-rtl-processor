module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:15];

    initial begin

        // ADD x3, x1, x2
        memory[0] = 32'h002081B3;

        // SUB x4, x3, x1
        memory[1] = 32'h40118233;

        // AND x5, x3, x4
        memory[2] = 32'h0041F2B3;

        // OR x6, x3, x4
        memory[3] = 32'h0041E333;

    end

    always_comb begin

        instruction = memory[address >> 2];

    end

endmodule