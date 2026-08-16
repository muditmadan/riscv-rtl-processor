module decoder (
    input  logic [31:0] instruction,

    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    output logic [2:0]  alu_control
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    // Extract fields from the instruction
    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];

    // Decode the instruction
    always_comb begin

        // Default: no operation
        alu_control = 3'b000;

        // R-type instruction
        if (opcode == 7'b0110011) begin

            // ADD / SUB
            if (funct3 == 3'b000) begin

                if (funct7 == 7'b0000000)
                    alu_control = 3'b001; // ADD

                else if (funct7 == 7'b0100000)
                    alu_control = 3'b010; // SUB

            end

            // AND
            else if (funct3 == 3'b111)
                alu_control = 3'b011;

            // OR
            else if (funct3 == 3'b110)
                alu_control = 3'b100;

        end

    end

endmodule