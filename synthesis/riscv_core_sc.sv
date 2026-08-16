// ============================================================
// riscv_core_sc.sv — Single-cycle core logic for synthesis
//
// Exposes the full instruction→result datapath as I/O.
// Memories are inputs (as if connected to external SRAMs).
// This is the synthesisable "logic core" — the part that
// matters for area and critical-path comparison.
// ============================================================
`ifdef SYNTHESIS
`define NO_ASSERT
`endif

module riscv_core_sc (
    input  logic        clk,
    input  logic        reset,
    // Instruction memory interface (external SRAM)
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_data,
    // Data memory interface (external SRAM)
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we,
    output logic        dmem_re,
    input  logic [31:0] dmem_rdata
);

    // ---- PC ----
    logic [31:0] pc;
    logic [31:0] pc_plus_4;
    logic [31:0] next_pc;

    assign pc_plus_4 = pc + 32'd4;
    assign imem_addr = pc;

    always_ff @(posedge clk) begin
        if (reset) pc <= 32'b0;
        else       pc <= next_pc;
    end

    // ---- Decode ----
    logic [4:0]  rs1, rs2, rd;
    logic [2:0]  alu_control;
    logic [31:0] immediate;

    decoder dec_inst (
        .instruction(imem_data),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .alu_control(alu_control)
    );

    control_unit ctrl_inst (
        .instruction(imem_data),
        .reg_write  (reg_write),
        .alu_src    (alu_src),
        .mem_read   (dmem_re),
        .mem_write  (dmem_we),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .branch_ne  (branch_ne),
        .jump       (jump),
        .jalr       (jalr)
    );

    immediate_generator imm_inst (
        .instruction(imem_data),
        .immediate  (immediate)
    );

    logic reg_write, alu_src, mem_to_reg, branch, branch_ne, jump, jalr;

    // ---- Register File ----
    logic [31:0] rdata1, rdata2, wb_data;

    register_file rf_inst (
        .clk         (clk),
        .reset       (reset),
        .rs1         (rs1),
        .rs2         (rs2),
        .rd          (rd),
        .write_data  (wb_data),
        .write_enable(reg_write),
        .read_data1  (rdata1),
        .read_data2  (rdata2)
    );

    // ---- ALU ----
    logic [31:0] alu_b, alu_result;
    logic        zero;

    assign alu_b = alu_src ? immediate : rdata2;

    alu alu_inst (
        .a          (rdata1),
        .b          (alu_b),
        .alu_control(alu_control),
        .result     (alu_result)
    );

    assign zero = (alu_result == 32'b0);

    // ---- Memory ----
    assign dmem_addr  = alu_result;
    assign dmem_wdata = rdata2;

    // ---- Writeback ----
    assign wb_data = (jump || jalr) ? pc_plus_4
                   : mem_to_reg     ? dmem_rdata
                   :                  alu_result;

    // ---- PC MUX ----
    logic [31:0] branch_target;
    logic        branch_taken;

    assign branch_target = pc + immediate;
    assign branch_taken  = (branch && zero) || (branch_ne && !zero);
    assign next_pc = jalr         ? (alu_result & ~32'h1)
                   : (branch_taken || jump) ? branch_target
                   : pc_plus_4;

endmodule
