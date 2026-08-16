// ============================================================
// pipe_synth_wrapper.sv
// Synthesis wrapper for the 5-stage pipeline datapath.
// ============================================================
`define SYNTHESIS
module pipe_synth_wrapper (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] o_pc,
    output logic [31:0] o_instruction,
    output logic [31:0] o_alu_result,
    output logic [31:0] o_write_data,
    output logic        o_write_enable
);
    pipeline_datapath dut (
        .clk  (clk),
        .reset(reset)
    );
    assign o_pc           = dut.if_pc;
    assign o_instruction  = dut.if_instruction;
    assign o_alu_result   = dut.ex_alu_result;
    assign o_write_data   = dut.wb_write_data;
    assign o_write_enable = dut.wb_write_enable;
endmodule
