module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  alu_control,
    output logic [31:0] result
);

    always_comb begin
        case (alu_control)

            3'b001: result = a + b;  // ADD
            3'b010: result = a - b;  // SUB
            3'b011: result = a & b;  // AND
            3'b100: result = a | b;  // OR
            3'b101: result = a ^ b;  // XOR (reserved for later)

            default: result = 32'b0;

        endcase
    end

endmodule