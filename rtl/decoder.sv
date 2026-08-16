// ============================================================
// Decoder — extracts register indices and generates alu_control
//
// alu_control encoding (must match alu.sv):
//   3'b000  ADD   (R-type ADD, I-type ADDI, LW addr, SW addr, JALR target)
//   3'b001  SUB   (R-type SUB, B-type comparison)
//   3'b010  AND   (R-type AND)
//   3'b011  OR    (R-type OR)
//   3'b100  XOR   (reserved)
// ============================================================

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

    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];

    always_comb begin
        alu_control = 3'b000; // default: ADD

        // R-type: ADD, SUB, AND, OR
        if (opcode == 7'b0110011) begin
            if (funct3 == 3'b000) begin
                if (funct7 == 7'b0000000)
                    alu_control = 3'b000; // ADD
                else if (funct7 == 7'b0100000)
                    alu_control = 3'b001; // SUB
            end
            else if (funct3 == 3'b111)
                alu_control = 3'b010;     // AND
            else if (funct3 == 3'b110)
                alu_control = 3'b011;     // OR
        end

        // I-type: ADDI  — ALU computes rs1 + imm
        else if (opcode == 7'b0010011) begin
            if (funct3 == 3'b000)
                alu_control = 3'b000;     // ADD
        end

        // I-type: LW  — ALU computes base + offset address
        else if (opcode == 7'b0000011) begin
            if (funct3 == 3'b010)
                alu_control = 3'b000;     // ADD
        end

        // I-type: JALR  — ALU computes rs1 + imm jump target
        else if (opcode == 7'b1100111) begin
            if (funct3 == 3'b000)
                alu_control = 3'b000;     // ADD
        end

        // S-type: SW  — ALU computes base + offset address
        else if (opcode == 7'b0100011) begin
            if (funct3 == 3'b010)
                alu_control = 3'b000;     // ADD
        end

        // B-type: BEQ, BNE  — ALU performs SUB; zero flag used for branch
        else if (opcode == 7'b1100011) begin
            if (funct3 == 3'b000 || funct3 == 3'b001)
                alu_control = 3'b001;     // SUB
        end

        // J-type: JAL  — no ALU computation needed; target = PC + imm
        // alu_control stays at default 3'b000 (result unused)
    end

endmodule
