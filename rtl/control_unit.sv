module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] alu_control,
    input  logic [2:0] funct3,

    output logic       reg_write,
    output logic       alu_src,
    output logic       branch,
    output logic       branch_ne,
    output logic       jump,
    output logic       jalr
);

    always_comb begin

        reg_write = 1'b0;
        alu_src   = 1'b0;
        branch    = 1'b0;
        branch_ne = 1'b0;
        jump      = 1'b0;
        jalr      = 1'b0;

        // R-type instructions: use register operand B
        if (opcode == 7'b0110011) begin
            reg_write = 1'b1;
            alu_src   = 1'b0;
        end

        // I-type ADDI: use immediate as operand B
        else if (opcode == 7'b0010011) begin
            reg_write = 1'b1;
            alu_src   = 1'b1;
        end

        // I-type LW: use immediate address and memory data for writeback
        else if (opcode == 7'b0000011) begin
            reg_write = 1'b1;
            alu_src   = 1'b1;
        end

        // B-type BEQ/BNE: branch instruction
        else if (opcode == 7'b1100011) begin
            if (funct3 == 3'b000)
                branch = 1'b1;      // BEQ
            else if (funct3 == 3'b001)
                branch_ne = 1'b1;   // BNE
        end

        // J-type JAL: jump and link
        else if (opcode == 7'b1101111) begin
            reg_write = 1'b1;
            jump      = 1'b1;
        end

        // I-type JALR: jump and link register
        else if (opcode == 7'b1100111 && funct3 == 3'b000) begin
            reg_write = 1'b1;
            alu_src   = 1'b1;   // Use immediate (rs1 + immediate)
            jalr      = 1'b1;
        end

    end

endmodule
