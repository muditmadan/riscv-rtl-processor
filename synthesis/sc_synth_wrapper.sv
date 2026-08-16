// ============================================================
// sc_synth_wrapper.sv
// Synthesis wrapper for the single-cycle datapath.
// Exposes internal signals as output ports so the synthesizer
// cannot dead-code-eliminate the logic.
// ============================================================
`define SYNTHESIS
module sc_synth_wrapper (
    input  logic        clk,
    input  logic        reset,
    // Observable outputs for synthesis (prevent DCE)
    output logic [31:0] o_pc,
    output logic [31:0] o_instruction,
    output logic [31:0] o_alu_result,
    output logic [31:0] o_write_data,
    output logic        o_write_enable
);
    datapath dut (
        .clk  (clk),
        .reset(reset)
    );
    assign o_pc           = dut.pc;
    assign o_instruction  = dut.instruction;
    assign o_alu_result   = dut.alu_result;
    assign o_write_data   = dut.write_data;
    assign o_write_enable = dut.write_enable;
endmodule
