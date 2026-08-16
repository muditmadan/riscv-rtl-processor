module control_unit (
    input  logic [31:0] instruction,

    output logic       reg_write,
    output logic       alu_src,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       branch,
    output logic       branch_ne,
    output logic       jump,
    output logic       jalr
);

    logic [6:0] opcode;
    logic [2:0] funct3;

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];

    always_comb begin
        reg_write = 1'b0;
        alu_src   = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        branch    = 1'b0;
        branch_ne = 1'b0;
        jump      = 1'b0;
        jalr      = 1'b0;

        // R-type: ADD, SUB, AND, OR
        if (opcode == 7'b0110011) begin
            reg_write = 1'b1;
        end

        // I-type: ADDI
        else if (opcode == 7'b0010011 && funct3 == 3'b000) begin
            reg_write = 1'b1;
            alu_src   = 1'b1;
        end

        // I-type: LW
        else if (opcode == 7'b0000011 && funct3 == 3'b010) begin
            reg_write  = 1'b1;
            alu_src    = 1'b1;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;
        end

        // S-type: SW
        else if (opcode == 7'b0100011 && funct3 == 3'b010) begin
            alu_src   = 1'b1;
            mem_write = 1'b1;
        end

        // B-type: BEQ, BNE
        else if (opcode == 7'b1100011) begin
            if (funct3 == 3'b000)
                branch = 1'b1;
            else if (funct3 == 3'b001)
                branch_ne = 1'b1;
        end

        // J-type: JAL
        else if (opcode == 7'b1101111) begin
            reg_write = 1'b1;
            jump      = 1'b1;
        end

        // I-type: JALR
        else if (opcode == 7'b1100111 && funct3 == 3'b000) begin
            reg_write = 1'b1;
            alu_src   = 1'b1;
            jalr      = 1'b1;
        end
    end

endmodule
