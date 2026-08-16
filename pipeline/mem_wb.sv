// ============================================================
// MEM/WB Pipeline Register
//
// Latches the outputs of the MEM stage for use in WB.
// No flush input needed here — by the time a branch is
// resolved in EX, this stage already holds a valid (older)
// instruction that must complete.
// ============================================================

module mem_wb (
    input  logic        clk,
    input  logic        reset,

    // --- Datapath values ---
    input  logic [31:0] mem_alu_result,
    input  logic [31:0] mem_memory_read_data,
    input  logic [4:0]  mem_rd,
    input  logic [31:0] mem_pc_plus_4,

    // --- Control signals ---
    input  logic        mem_reg_write,
    input  logic        mem_mem_to_reg,
    input  logic        mem_jump,
    input  logic        mem_jalr,

    // --- Outputs to WB stage ---
    output logic [31:0] wb_alu_result,
    output logic [31:0] wb_memory_read_data,
    output logic [4:0]  wb_rd,
    output logic [31:0] wb_pc_plus_4,

    output logic        wb_reg_write,
    output logic        wb_mem_to_reg,
    output logic        wb_jump,
    output logic        wb_jalr
);

    always_ff @(posedge clk) begin
        if (reset) begin
            wb_alu_result        <= 32'b0;
            wb_memory_read_data  <= 32'b0;
            wb_rd                <= 5'b0;
            wb_pc_plus_4         <= 32'b0;
            wb_reg_write         <= 1'b0;
            wb_mem_to_reg        <= 1'b0;
            wb_jump              <= 1'b0;
            wb_jalr              <= 1'b0;
        end
        else begin
            wb_alu_result        <= mem_alu_result;
            wb_memory_read_data  <= mem_memory_read_data;
            wb_rd                <= mem_rd;
            wb_pc_plus_4         <= mem_pc_plus_4;
            wb_reg_write         <= mem_reg_write;
            wb_mem_to_reg        <= mem_mem_to_reg;
            wb_jump              <= mem_jump;
            wb_jalr              <= mem_jalr;
        end
    end

endmodule
