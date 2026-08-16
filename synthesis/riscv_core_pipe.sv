// ============================================================
// riscv_core_pipe.sv — 5-stage pipeline core logic for synthesis
//
// Same memory interface as riscv_core_sc.sv.
// Contains all pipeline registers, forwarding unit, hazard unit.
// ============================================================

module riscv_core_pipe (
    input  logic        clk,
    input  logic        reset,
    // Instruction memory interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_data,
    // Data memory interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we,
    output logic        dmem_re,
    input  logic [31:0] dmem_rdata
);

    // ===========================================================
    // IF STAGE
    // ===========================================================
    logic [31:0] if_pc;
    logic [31:0] if_pc_plus_4;
    logic [31:0] if_next_pc;
    logic        pc_write;

    assign if_pc_plus_4 = if_pc + 32'd4;
    assign imem_addr    = if_pc;

    always_ff @(posedge clk) begin
        if (reset)      if_pc <= 32'b0;
        else if (pc_write) if_pc <= if_next_pc;
    end

    // ===========================================================
    // IF/ID REGISTER
    // ===========================================================
    logic        if_id_stall, if_id_flush;
    logic [31:0] id_pc, id_pc_plus_4, id_instruction;

    if_id if_id_r (
        .clk(clk), .reset(reset), .stall(if_id_stall), .flush(if_id_flush),
        .if_pc(if_pc), .if_pc_plus_4(if_pc_plus_4), .if_instruction(imem_data),
        .id_pc(id_pc), .id_pc_plus_4(id_pc_plus_4), .id_instruction(id_instruction)
    );

    // ===========================================================
    // ID STAGE
    // ===========================================================
    logic [4:0]  id_rs1, id_rs2, id_rd;
    logic [2:0]  id_alu_ctrl;
    logic [31:0] id_imm;
    logic        id_rw, id_as, id_mr, id_mw, id_m2r, id_br, id_bne, id_jmp, id_jalr;

    decoder dec_inst (
        .instruction(id_instruction),
        .rs1(id_rs1), .rs2(id_rs2), .rd(id_rd), .alu_control(id_alu_ctrl)
    );
    control_unit ctrl_inst (
        .instruction(id_instruction),
        .reg_write(id_rw), .alu_src(id_as), .mem_read(id_mr), .mem_write(id_mw),
        .mem_to_reg(id_m2r), .branch(id_br), .branch_ne(id_bne), .jump(id_jmp), .jalr(id_jalr)
    );
    immediate_generator imm_inst (
        .instruction(id_instruction), .immediate(id_imm)
    );

    // Register file write-back (driven from WB stage below)
    logic        wb_we;
    logic [4:0]  wb_rd;
    logic [31:0] wb_data;

    logic [31:0] id_rd1, id_rd2;
    register_file rf_inst (
        .clk(clk), .reset(reset),
        .rs1(id_rs1), .rs2(id_rs2),
        .rd(wb_rd), .write_data(wb_data), .write_enable(wb_we),
        .read_data1(id_rd1), .read_data2(id_rd2)
    );

    // ===========================================================
    // ID/EX REGISTER
    // ===========================================================
    logic        id_ex_flush;
    logic [31:0] ex_pc, ex_pc4, ex_rd1_raw, ex_rd2_raw, ex_imm;
    logic [4:0]  ex_rs1, ex_rs2, ex_rd;
    logic [2:0]  ex_alu_ctrl;
    logic        ex_rw, ex_as, ex_mr, ex_mw, ex_m2r, ex_br, ex_bne, ex_jmp, ex_jalr;

    id_ex id_ex_r (
        .clk(clk), .reset(reset), .flush(id_ex_flush),
        .id_pc(id_pc), .id_pc_plus_4(id_pc_plus_4),
        .id_read_data1(id_rd1), .id_read_data2(id_rd2), .id_immediate(id_imm),
        .id_rs1(id_rs1), .id_rs2(id_rs2), .id_rd(id_rd), .id_alu_control(id_alu_ctrl),
        .id_reg_write(id_rw), .id_alu_src(id_as), .id_mem_read(id_mr), .id_mem_write(id_mw),
        .id_mem_to_reg(id_m2r), .id_branch(id_br), .id_branch_ne(id_bne),
        .id_jump(id_jmp), .id_jalr(id_jalr),
        .ex_pc(ex_pc), .ex_pc_plus_4(ex_pc4),
        .ex_read_data1(ex_rd1_raw), .ex_read_data2(ex_rd2_raw), .ex_immediate(ex_imm),
        .ex_rs1(ex_rs1), .ex_rs2(ex_rs2), .ex_rd(ex_rd), .ex_alu_control(ex_alu_ctrl),
        .ex_reg_write(ex_rw), .ex_alu_src(ex_as), .ex_mem_read(ex_mr), .ex_mem_write(ex_mw),
        .ex_mem_to_reg(ex_m2r), .ex_branch(ex_br), .ex_branch_ne(ex_bne),
        .ex_jump(ex_jmp), .ex_jalr(ex_jalr)
    );

    // ===========================================================
    // EX STAGE
    // ===========================================================
    logic [31:0] exmem_alu_result;
    logic [4:0]  exmem_rd;
    logic        exmem_rw;

    logic [1:0]  fwd_a, fwd_b;
    forwarding_unit fwd_inst (
        .ex_rs1(ex_rs1), .ex_rs2(ex_rs2),
        .exmem_rd(exmem_rd), .exmem_reg_write(exmem_rw),
        .memwb_rd(wb_rd), .memwb_reg_write(wb_we),
        .forward_a(fwd_a), .forward_b(fwd_b)
    );

    logic [31:0] ex_a, ex_b_pre, ex_b;
    always_comb begin
        case (fwd_a)
            2'b10:   ex_a = exmem_alu_result;
            2'b01:   ex_a = wb_data;
            default: ex_a = ex_rd1_raw;
        endcase
        case (fwd_b)
            2'b10:   ex_b_pre = exmem_alu_result;
            2'b01:   ex_b_pre = wb_data;
            default: ex_b_pre = ex_rd2_raw;
        endcase
    end
    assign ex_b = ex_as ? ex_imm : ex_b_pre;

    logic [31:0] ex_alu_res;
    logic        ex_zero;
    alu alu_inst (
        .a(ex_a), .b(ex_b), .alu_control(ex_alu_ctrl), .result(ex_alu_res)
    );
    assign ex_zero = (ex_alu_res == 32'b0);

    logic [31:0] ex_br_target;
    assign ex_br_target = ex_pc + ex_imm;

    // ===========================================================
    // EX/MEM REGISTER
    // ===========================================================
    logic [31:0] exmem_pc4, exmem_rd2, exmem_br_target;
    logic        exmem_zero, exmem_mr, exmem_mw, exmem_m2r;
    logic        exmem_br, exmem_bne, exmem_jmp, exmem_jalr;

    ex_mem ex_mem_r (
        .clk(clk), .reset(reset), .flush(1'b0),
        .ex_pc_plus_4(ex_pc4), .ex_alu_result(ex_alu_res), .ex_zero(ex_zero),
        .ex_read_data2(ex_b_pre), .ex_rd(ex_rd), .ex_branch_target(ex_br_target),
        .ex_reg_write(ex_rw), .ex_mem_read(ex_mr), .ex_mem_write(ex_mw),
        .ex_mem_to_reg(ex_m2r), .ex_branch(ex_br), .ex_branch_ne(ex_bne),
        .ex_jump(ex_jmp), .ex_jalr(ex_jalr),
        .mem_pc_plus_4(exmem_pc4), .mem_alu_result(exmem_alu_result), .mem_zero(exmem_zero),
        .mem_read_data2(exmem_rd2), .mem_rd(exmem_rd), .mem_branch_target(exmem_br_target),
        .mem_reg_write(exmem_rw), .mem_mem_read(dmem_re), .mem_mem_write(dmem_we),
        .mem_mem_to_reg(exmem_m2r), .mem_branch(exmem_br), .mem_branch_ne(exmem_bne),
        .mem_jump(exmem_jmp), .mem_jalr(exmem_jalr)
    );

    assign dmem_addr  = exmem_alu_result;
    assign dmem_wdata = exmem_rd2;

    // ===========================================================
    // MEM/WB REGISTER
    // ===========================================================
    logic [31:0] wb_alu_res, wb_mem_rdata, wb_pc4;
    logic        wb_m2r, wb_jmp, wb_jalr;

    mem_wb mem_wb_r (
        .clk(clk), .reset(reset),
        .mem_alu_result(exmem_alu_result), .mem_memory_read_data(dmem_rdata),
        .mem_rd(exmem_rd), .mem_pc_plus_4(exmem_pc4),
        .mem_reg_write(exmem_rw), .mem_mem_to_reg(exmem_m2r),
        .mem_jump(exmem_jmp), .mem_jalr(exmem_jalr),
        .wb_alu_result(wb_alu_res), .wb_memory_read_data(wb_mem_rdata),
        .wb_rd(wb_rd), .wb_pc_plus_4(wb_pc4),
        .wb_reg_write(wb_we), .wb_mem_to_reg(wb_m2r),
        .wb_jump(wb_jmp), .wb_jalr(wb_jalr)
    );

    // ===========================================================
    // WB STAGE
    // ===========================================================
    assign wb_data = (wb_jmp || wb_jalr) ? wb_pc4
                   : wb_m2r              ? wb_mem_rdata
                   :                       wb_alu_res;

    // ===========================================================
    // HAZARD UNIT
    // ===========================================================
    logic id_ex_flush_hz;
    hazard_unit hz_inst (
        .idex_mem_read(ex_mr), .idex_rd(ex_rd),
        .ifid_rs1(id_rs1), .ifid_rs2(id_rs2),
        .pc_write(pc_write), .if_id_stall(if_id_stall), .id_ex_flush(id_ex_flush_hz)
    );

    // ===========================================================
    // BRANCH/JUMP PC MUX + FLUSH
    // ===========================================================
    logic        branch_taken;
    logic [31:0] pc_target;

    assign branch_taken = (exmem_br  &&  exmem_zero) || (exmem_bne && !exmem_zero)
                        || exmem_jmp || exmem_jalr;
    assign pc_target    = exmem_jalr ? (exmem_alu_result & ~32'h1) : exmem_br_target;
    assign if_next_pc   = branch_taken ? pc_target : if_pc_plus_4;
    assign if_id_flush  = branch_taken;
    assign id_ex_flush  = id_ex_flush_hz || branch_taken;

endmodule
