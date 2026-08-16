module immediate_generator (
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        // Default: I-type immediate
        immediate = {{20{instruction[31]}}, instruction[31:20]};

        // B-type immediate for BEQ, BNE, etc.
        if (opcode == 7'b1100011) begin
            immediate = {
                {19{instruction[31]}},
                instruction[31],
                instruction[7],
                instruction[30:25],
                instruction[11:8],
                1'b0
            };
        end

        // J-type immediate for JAL
        else if (opcode == 7'b1101111) begin
            immediate = {
                {11{instruction[31]}},
                instruction[31],
                instruction[19:12],
                instruction[20],
                instruction[30:21],
                1'b0
            };
        end
    end

endmodule
