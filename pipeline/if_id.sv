// ============================================================
// IF/ID Pipeline Register
//
// Latches the outputs of the IF stage for use in ID.
// stall : hold current value (PC does not advance)
// flush : write zeros/NOP (branch misprediction squash)
//
// Flush takes priority over stall.
// ============================================================

module if_id (
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    input  logic        flush,

    // Inputs from IF stage
    input  logic [31:0] if_pc,
    input  logic [31:0] if_pc_plus_4,
    input  logic [31:0] if_instruction,

    // Outputs to ID stage
    output logic [31:0] id_pc,
    output logic [31:0] id_pc_plus_4,
    output logic [31:0] id_instruction
);

    always_ff @(posedge clk) begin
        if (reset || flush) begin
            id_pc          <= 32'b0;
            id_pc_plus_4   <= 32'b0;
            id_instruction <= 32'h00000013; // NOP: ADDI x0, x0, 0
        end
        else if (!stall) begin
            id_pc          <= if_pc;
            id_pc_plus_4   <= if_pc_plus_4;
            id_instruction <= if_instruction;
        end
        // stall: all outputs hold their current value (no else branch)
    end

endmodule
