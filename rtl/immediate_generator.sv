// ============================================================
// Immediate Generator — sign-extends the immediate field
// for each RISC-V instruction format.
//
// Uses continuous assign (not always_comb) to avoid Icarus
// "constant selects" warnings while remaining synthesisable.
//
// Formats supported:
//   I-type : ADDI, LW, JALR  — 12-bit sign-extended
//   S-type : SW               — 12-bit sign-extended split field
//   B-type : BEQ, BNE         — 13-bit sign-extended (LSB=0)
//   J-type : JAL              — 21-bit sign-extended (LSB=0)
//   R-type : (no immediate used — falls through to I-type default,
//             but alu_src=0 so result is never consumed)
// ============================================================

module immediate_generator (
    input  logic [31:0] instruction,
    output logic [31:0] immediate
);

    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    // I-type (default): sign-extend bits [31:20]
    logic [31:0] imm_i;
    assign imm_i = {{20{instruction[31]}}, instruction[31:20]};

    // S-type: split immediate [31:25] | [11:7]
    logic [31:0] imm_s;
    assign imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

    // B-type: [31][7][30:25][11:8] << 1
    logic [31:0] imm_b;
    assign imm_b = {{19{instruction[31]}}, instruction[31], instruction[7],
                    instruction[30:25], instruction[11:8], 1'b0};

    // J-type: [31][19:12][20][30:21] << 1
    logic [31:0] imm_j;
    assign imm_j = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                    instruction[20], instruction[30:21], 1'b0};

    // Select based on opcode
    always_comb begin
        case (opcode)
            7'b0100011: immediate = imm_s;  // SW
            7'b1100011: immediate = imm_b;  // BEQ, BNE
            7'b1101111: immediate = imm_j;  // JAL
            default:    immediate = imm_i;  // ADDI, LW, JALR, R-type (unused)
        endcase
    end

endmodule
