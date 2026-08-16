// ============================================================
// EX/MEM Pipeline Register
//
// Latches the outputs of the EX stage for use in MEM.
// flush : write zeros / de-assert all control signals
//         (used when branch resolution squashes this stage)
// ============================================================

module ex_mem (
    input  logic        clk,
    input  logic        reset,
    input  logic        flush,

    // --- Datapath values ---
    input  logic [31:0] ex_pc_plus_4,
    input  logic [31:0] ex_alu_result,
    input  logic        ex_zero,
    input  logic [31:0] ex_read_data2,    // store data (SW)
    input  logic [4:0]  ex_rd,
    input  logic [31:0] ex_branch_target, // PC + immediate

    // --- Control signals ---
    input  logic        ex_reg_write,
    input  logic        ex_mem_read,
    input  logic        ex_mem_write,
    input  logic        ex_mem_to_reg,
    input  logic        ex_branch,
    input  logic        ex_branch_ne,
    input  logic        ex_jump,
    input  logic        ex_jalr,

    // --- Outputs to MEM stage ---
    output logic [31:0] mem_pc_plus_4,
    output logic [31:0] mem_alu_result,
    output logic        mem_zero,
    output logic [31:0] mem_read_data2,
    output logic [4:0]  mem_rd,
    output logic [31:0] mem_branch_target,

    output logic        mem_reg_write,
    output logic        mem_mem_read,
    output logic        mem_mem_write,
    output logic        mem_mem_to_reg,
    output logic        mem_branch,
    output logic        mem_branch_ne,
    output logic        mem_jump,
    output logic        mem_jalr
);

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            mem_pc_plus_4    <= 32'b0;
            mem_alu_result   <= 32'b0;
            mem_zero         <= 1'b0;
            mem_read_data2   <= 32'b0;
            mem_rd           <= 5'b0;
            mem_branch_target <= 32'b0;
            mem_reg_write    <= 1'b0;
            mem_mem_read     <= 1'b0;
            mem_mem_write    <= 1'b0;
            mem_mem_to_reg   <= 1'b0;
            mem_branch       <= 1'b0;
            mem_branch_ne    <= 1'b0;
            mem_jump         <= 1'b0;
            mem_jalr         <= 1'b0;
        end
        else begin
            mem_pc_plus_4    <= ex_pc_plus_4;
            mem_alu_result   <= ex_alu_result;
            mem_zero         <= ex_zero;
            mem_read_data2   <= ex_read_data2;
            mem_rd           <= ex_rd;
            mem_branch_target <= ex_branch_target;
            mem_reg_write    <= ex_reg_write;
            mem_mem_read     <= ex_mem_read;
            mem_mem_write    <= ex_mem_write;
            mem_mem_to_reg   <= ex_mem_to_reg;
            mem_branch       <= ex_branch;
            mem_branch_ne    <= ex_branch_ne;
            mem_jump         <= ex_jump;
            mem_jalr         <= ex_jalr;
        end
    end

endmodule
