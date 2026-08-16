// ============================================================
// ID/EX Pipeline Register
//
// Latches all decode-stage outputs for use in EX.
// flush : write zeros (branch misprediction squash — inserts bubble)
// stall : not used at this register (hazard unit only stalls IF/ID)
//         kept as a port for structural symmetry.
//
// Control signals default to 0 on flush/reset, which is a
// safe NOP (no register write, no memory access, no branch).
// ============================================================

module id_ex (
    input  logic        clk,
    input  logic        reset,
    input  logic        flush,

    // --- Datapath values ---
    input  logic [31:0] id_pc,
    input  logic [31:0] id_pc_plus_4,
    input  logic [31:0] id_read_data1,
    input  logic [31:0] id_read_data2,
    input  logic [31:0] id_immediate,
    input  logic [4:0]  id_rs1,
    input  logic [4:0]  id_rs2,
    input  logic [4:0]  id_rd,
    input  logic [2:0]  id_alu_control,

    // --- Control signals ---
    input  logic        id_reg_write,
    input  logic        id_alu_src,
    input  logic        id_mem_read,
    input  logic        id_mem_write,
    input  logic        id_mem_to_reg,
    input  logic        id_branch,
    input  logic        id_branch_ne,
    input  logic        id_jump,
    input  logic        id_jalr,

    // --- Outputs to EX stage ---
    output logic [31:0] ex_pc,
    output logic [31:0] ex_pc_plus_4,
    output logic [31:0] ex_read_data1,
    output logic [31:0] ex_read_data2,
    output logic [31:0] ex_immediate,
    output logic [4:0]  ex_rs1,
    output logic [4:0]  ex_rs2,
    output logic [4:0]  ex_rd,
    output logic [2:0]  ex_alu_control,

    output logic        ex_reg_write,
    output logic        ex_alu_src,
    output logic        ex_mem_read,
    output logic        ex_mem_write,
    output logic        ex_mem_to_reg,
    output logic        ex_branch,
    output logic        ex_branch_ne,
    output logic        ex_jump,
    output logic        ex_jalr
);

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            // Datapath zeros
            ex_pc          <= 32'b0;
            ex_pc_plus_4   <= 32'b0;
            ex_read_data1  <= 32'b0;
            ex_read_data2  <= 32'b0;
            ex_immediate   <= 32'b0;
            ex_rs1         <= 5'b0;
            ex_rs2         <= 5'b0;
            ex_rd          <= 5'b0;
            ex_alu_control <= 3'b0;
            // All control signals off (safe NOP bubble)
            ex_reg_write   <= 1'b0;
            ex_alu_src     <= 1'b0;
            ex_mem_read    <= 1'b0;
            ex_mem_write   <= 1'b0;
            ex_mem_to_reg  <= 1'b0;
            ex_branch      <= 1'b0;
            ex_branch_ne   <= 1'b0;
            ex_jump        <= 1'b0;
            ex_jalr        <= 1'b0;
        end
        else begin
            ex_pc          <= id_pc;
            ex_pc_plus_4   <= id_pc_plus_4;
            ex_read_data1  <= id_read_data1;
            ex_read_data2  <= id_read_data2;
            ex_immediate   <= id_immediate;
            ex_rs1         <= id_rs1;
            ex_rs2         <= id_rs2;
            ex_rd          <= id_rd;
            ex_alu_control <= id_alu_control;
            ex_reg_write   <= id_reg_write;
            ex_alu_src     <= id_alu_src;
            ex_mem_read    <= id_mem_read;
            ex_mem_write   <= id_mem_write;
            ex_mem_to_reg  <= id_mem_to_reg;
            ex_branch      <= id_branch;
            ex_branch_ne   <= id_branch_ne;
            ex_jump        <= id_jump;
            ex_jalr        <= id_jalr;
        end
    end

endmodule
