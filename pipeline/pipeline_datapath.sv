// ============================================================
// pipeline_datapath.sv — 5-Stage Pipelined RV32I CPU
//
// Stages:  IF → ID → EX → MEM → WB
// Features:
//   • Full forwarding (EX-EX and MEM-EX)
//   • Load-use hazard detection + 1-cycle stall
//   • Flush-on-taken branch / jump (2-cycle penalty)
//   • All 11 target instructions:
//     ADD SUB AND OR ADDI LW SW BEQ BNE JAL JALR
//
// Sub-modules reused unchanged from rtl/:
//   alu, register_file, data_memory, decoder,
//   control_unit, immediate_generator,
//   instruction_memory, program_counter
//
// Pipeline registers and control units from pipeline/:
//   if_id, id_ex, ex_mem, mem_wb,
//   forwarding_unit, hazard_unit
// ============================================================

module pipeline_datapath (
    input logic clk,
    input logic reset
);

    // ===========================================================
    // ██████████   IF STAGE   ██████████
    // ===========================================================

    // --- PC ---
    logic [31:0] if_pc;
    logic [31:0] if_pc_plus_4;
    logic [31:0] if_next_pc;
    logic        pc_write;          // 0 = stall (from hazard unit)

    assign if_pc_plus_4 = if_pc + 32'd4;

    // PC register — write-enabled only when pc_write is asserted
    always_ff @(posedge clk) begin
        if (reset)
            if_pc <= 32'b0;
        else if (pc_write)
            if_pc <= if_next_pc;
        // else: pc_write=0 → hold (load-use stall)
    end

    // --- Instruction Memory ---
    logic [31:0] if_instruction;

    instruction_memory imem (
        .address    (if_pc),
        .instruction(if_instruction)
    );

    // ===========================================================
    // ██████  IF/ID PIPELINE REGISTER  ██████
    // ===========================================================

    logic        if_id_stall;
    logic        if_id_flush;

    logic [31:0] id_pc;
    logic [31:0] id_pc_plus_4;
    logic [31:0] id_instruction;

    if_id if_id_reg (
        .clk           (clk),
        .reset         (reset),
        .stall         (if_id_stall),
        .flush         (if_id_flush),
        .if_pc         (if_pc),
        .if_pc_plus_4  (if_pc_plus_4),
        .if_instruction(if_instruction),
        .id_pc         (id_pc),
        .id_pc_plus_4  (id_pc_plus_4),
        .id_instruction(id_instruction)
    );

    // ===========================================================
    // ██████████   ID STAGE   ██████████
    // ===========================================================

    // --- Decoder ---
    logic [4:0]  id_rs1;
    logic [4:0]  id_rs2;
    logic [4:0]  id_rd;
    logic [2:0]  id_alu_control;

    decoder decoder_inst (
        .instruction(id_instruction),
        .rs1        (id_rs1),
        .rs2        (id_rs2),
        .rd         (id_rd),
        .alu_control(id_alu_control)
    );

    // --- Control Unit ---
    logic id_reg_write;
    logic id_alu_src;
    logic id_mem_read;
    logic id_mem_write;
    logic id_mem_to_reg;
    logic id_branch;
    logic id_branch_ne;
    logic id_jump;
    logic id_jalr;

    control_unit ctrl_inst (
        .instruction(id_instruction),
        .reg_write  (id_reg_write),
        .alu_src    (id_alu_src),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .mem_to_reg (id_mem_to_reg),
        .branch     (id_branch),
        .branch_ne  (id_branch_ne),
        .jump       (id_jump),
        .jalr       (id_jalr)
    );

    // --- Immediate Generator ---
    logic [31:0] id_immediate;

    immediate_generator imm_gen_inst (
        .instruction(id_instruction),
        .immediate  (id_immediate)
    );

    // --- Register File (read ports in ID, write port in WB) ---
    logic [31:0] id_read_data1;
    logic [31:0] id_read_data2;

    // WB write-back signals (defined in WB section below,
    // declared here so the register file instantiation compiles)
    logic        wb_write_enable;
    logic [4:0]  wb_rd;
    logic [31:0] wb_write_data;

    register_file reg_file_inst (
        .clk         (clk),
        .reset       (reset),
        // Read port (ID stage)
        .rs1         (id_rs1),
        .rs2         (id_rs2),
        // Write port (WB stage)
        .rd          (wb_rd),
        .write_data  (wb_write_data),
        .write_enable(wb_write_enable),
        // Read data output
        .read_data1  (id_read_data1),
        .read_data2  (id_read_data2)
    );

    // ===========================================================
    // ██████  ID/EX PIPELINE REGISTER  ██████
    // ===========================================================

    logic id_ex_flush;

    logic [31:0] ex_pc;
    logic [31:0] ex_pc_plus_4;
    logic [31:0] ex_read_data1_raw;
    logic [31:0] ex_read_data2_raw;
    logic [31:0] ex_immediate;
    logic [4:0]  ex_rs1;
    logic [4:0]  ex_rs2;
    logic [4:0]  ex_rd;
    logic [2:0]  ex_alu_control;
    logic        ex_reg_write;
    logic        ex_alu_src;
    logic        ex_mem_read;
    logic        ex_mem_write;
    logic        ex_mem_to_reg;
    logic        ex_branch;
    logic        ex_branch_ne;
    logic        ex_jump;
    logic        ex_jalr;

    id_ex id_ex_reg (
        .clk          (clk),
        .reset        (reset),
        .flush        (id_ex_flush),
        .id_pc        (id_pc),
        .id_pc_plus_4 (id_pc_plus_4),
        .id_read_data1(id_read_data1),
        .id_read_data2(id_read_data2),
        .id_immediate (id_immediate),
        .id_rs1       (id_rs1),
        .id_rs2       (id_rs2),
        .id_rd        (id_rd),
        .id_alu_control(id_alu_control),
        .id_reg_write (id_reg_write),
        .id_alu_src   (id_alu_src),
        .id_mem_read  (id_mem_read),
        .id_mem_write (id_mem_write),
        .id_mem_to_reg(id_mem_to_reg),
        .id_branch    (id_branch),
        .id_branch_ne (id_branch_ne),
        .id_jump      (id_jump),
        .id_jalr      (id_jalr),
        // Outputs
        .ex_pc        (ex_pc),
        .ex_pc_plus_4 (ex_pc_plus_4),
        .ex_read_data1(ex_read_data1_raw),
        .ex_read_data2(ex_read_data2_raw),
        .ex_immediate (ex_immediate),
        .ex_rs1       (ex_rs1),
        .ex_rs2       (ex_rs2),
        .ex_rd        (ex_rd),
        .ex_alu_control(ex_alu_control),
        .ex_reg_write (ex_reg_write),
        .ex_alu_src   (ex_alu_src),
        .ex_mem_read  (ex_mem_read),
        .ex_mem_write (ex_mem_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_branch    (ex_branch),
        .ex_branch_ne (ex_branch_ne),
        .ex_jump      (ex_jump),
        .ex_jalr      (ex_jalr)
    );

    // ===========================================================
    // ██████████   EX STAGE   ██████████
    // ===========================================================

    // --- Forwarding Unit ---
    logic [1:0] forward_a;
    logic [1:0] forward_b;

    // EX/MEM and MEM/WB signals needed for forwarding
    // (declared ahead of their pipeline register for wire ordering)
    logic [4:0]  exmem_rd;
    logic        exmem_reg_write;
    logic [31:0] exmem_alu_result;

    forwarding_unit fwd_unit (
        .ex_rs1        (ex_rs1),
        .ex_rs2        (ex_rs2),
        .exmem_rd      (exmem_rd),
        .exmem_reg_write(exmem_reg_write),
        .memwb_rd      (wb_rd),           // wb_rd == MEM/WB.rd
        .memwb_reg_write(wb_write_enable),
        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );

    // --- Forwarding MUXes ---
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b_pre;  // before alu_src mux
    logic [31:0] ex_alu_b;      // after  alu_src mux

    always_comb begin
        case (forward_a)
            2'b10:   ex_alu_a = exmem_alu_result;  // EX-EX forward
            2'b01:   ex_alu_a = wb_write_data;     // MEM-EX forward
            default: ex_alu_a = ex_read_data1_raw; // no hazard
        endcase
    end

    always_comb begin
        case (forward_b)
            2'b10:   ex_alu_b_pre = exmem_alu_result;   // EX-EX forward
            2'b01:   ex_alu_b_pre = wb_write_data;      // MEM-EX forward
            default: ex_alu_b_pre = ex_read_data2_raw;  // no hazard
        endcase
    end

    // alu_src mux: immediate overrides register value
    assign ex_alu_b = ex_alu_src ? ex_immediate : ex_alu_b_pre;

    // --- ALU ---
    logic [31:0] ex_alu_result;
    logic        ex_zero;

    alu alu_inst (
        .a          (ex_alu_a),
        .b          (ex_alu_b),
        .alu_control(ex_alu_control),
        .result     (ex_alu_result)
    );

    assign ex_zero = (ex_alu_result == 32'b0);

    // --- Branch / Jump target ---
    logic [31:0] ex_branch_target;
    assign ex_branch_target = ex_pc + ex_immediate;

    // --- Branch taken logic ---
    logic ex_branch_taken;
    assign ex_branch_taken =
        (ex_branch    &&  ex_zero) ||
        (ex_branch_ne && !ex_zero) ||
        ex_jump                    ||
        ex_jalr;

    // ===========================================================
    // ██████  EX/MEM PIPELINE REGISTER  ██████
    // ===========================================================

    logic        exmem_flush;
    logic        exmem_zero;
    logic [31:0] exmem_read_data2;
    logic [31:0] exmem_branch_target;
    logic        exmem_mem_read;
    logic        exmem_mem_write;
    logic        exmem_mem_to_reg;
    logic        exmem_branch;
    logic        exmem_branch_ne;
    logic        exmem_jump;
    logic        exmem_jalr;
    logic [31:0] exmem_pc_plus_4;

    ex_mem ex_mem_reg (
        .clk              (clk),
        .reset            (reset),
        .flush            (exmem_flush),
        .ex_pc_plus_4     (ex_pc_plus_4),
        .ex_alu_result    (ex_alu_result),
        .ex_zero          (ex_zero),
        .ex_read_data2    (ex_alu_b_pre),    // raw rs2 (after forwarding, before alu_src)
        .ex_rd            (ex_rd),
        .ex_branch_target (ex_branch_target),
        .ex_reg_write     (ex_reg_write),
        .ex_mem_read      (ex_mem_read),
        .ex_mem_write     (ex_mem_write),
        .ex_mem_to_reg    (ex_mem_to_reg),
        .ex_branch        (ex_branch),
        .ex_branch_ne     (ex_branch_ne),
        .ex_jump          (ex_jump),
        .ex_jalr          (ex_jalr),
        // Outputs
        .mem_pc_plus_4    (exmem_pc_plus_4),
        .mem_alu_result   (exmem_alu_result),
        .mem_zero         (exmem_zero),
        .mem_read_data2   (exmem_read_data2),
        .mem_rd           (exmem_rd),
        .mem_branch_target(exmem_branch_target),
        .mem_reg_write    (exmem_reg_write),
        .mem_mem_read     (exmem_mem_read),
        .mem_mem_write    (exmem_mem_write),
        .mem_mem_to_reg   (exmem_mem_to_reg),
        .mem_branch       (exmem_branch),
        .mem_branch_ne    (exmem_branch_ne),
        .mem_jump         (exmem_jump),
        .mem_jalr         (exmem_jalr)
    );

    // ===========================================================
    // ██████████   MEM STAGE   ██████████
    // ===========================================================

    logic [31:0] mem_memory_read_data;

    data_memory data_mem_inst (
        .clk       (clk),
        .reset     (reset),
        .address   (exmem_alu_result),
        .write_data(exmem_read_data2),
        .mem_read  (exmem_mem_read),
        .mem_write (exmem_mem_write),
        .read_data (mem_memory_read_data)
    );

    // ===========================================================
    // ██████  MEM/WB PIPELINE REGISTER  ██████
    // ===========================================================

    logic [31:0] wb_alu_result;
    logic [31:0] wb_memory_read_data;
    logic [31:0] wb_pc_plus_4;
    logic        wb_mem_to_reg;
    logic        wb_jump;
    logic        wb_jalr;

    mem_wb mem_wb_reg (
        .clk                 (clk),
        .reset               (reset),
        .mem_alu_result      (exmem_alu_result),
        .mem_memory_read_data(mem_memory_read_data),
        .mem_rd              (exmem_rd),
        .mem_pc_plus_4       (exmem_pc_plus_4),
        .mem_reg_write       (exmem_reg_write),
        .mem_mem_to_reg      (exmem_mem_to_reg),
        .mem_jump            (exmem_jump),
        .mem_jalr            (exmem_jalr),
        // Outputs
        .wb_alu_result       (wb_alu_result),
        .wb_memory_read_data (wb_memory_read_data),
        .wb_rd               (wb_rd),
        .wb_pc_plus_4        (wb_pc_plus_4),
        .wb_reg_write        (wb_write_enable),
        .wb_mem_to_reg       (wb_mem_to_reg),
        .wb_jump             (wb_jump),
        .wb_jalr             (wb_jalr)
    );

    // ===========================================================
    // ██████████   WB STAGE   ██████████
    // ===========================================================

    // Writeback mux — selects what goes back to the register file
    //   JAL/JALR → return address (PC+4)
    //   LW       → memory data
    //   default  → ALU result
    assign wb_write_data =
        (wb_jump || wb_jalr) ? wb_pc_plus_4        :
        wb_mem_to_reg        ? wb_memory_read_data  :
                               wb_alu_result;

    // wb_write_enable = wb_reg_write (already assigned via mem_wb port)

    // ===========================================================
    // ██████  BRANCH/JUMP FLUSH AND PC MUX  ██████
    // ===========================================================

    // Branch is resolved at the end of EX stage; the resolved
    // values are now latched in EX/MEM.  Flush the two wrong-path
    // instructions still in IF/ID and ID/EX.

    logic        mem_branch_taken;
    logic [31:0] mem_pc_target;

    assign mem_branch_taken =
        (exmem_branch    &&  exmem_zero)  ||
        (exmem_branch_ne && !exmem_zero)  ||
        exmem_jump                        ||
        exmem_jalr;

    // JALR target = alu_result (rs1 + imm), LSB cleared per spec
    // Branch / JAL target = PC + immediate (pre-computed in exmem_branch_target)
    assign mem_pc_target = exmem_jalr
        ? (exmem_alu_result & ~32'h1)
        :  exmem_branch_target;

    // EX/MEM register itself is never flushed (it holds the resolved branch)
    assign exmem_flush = 1'b0;

    // IF/ID is flushed on branch/jump taken
    assign if_id_flush = mem_branch_taken;

    // PC next-value mux — branch/jump overrides normal PC+4
    assign if_next_pc = mem_branch_taken ? mem_pc_target : if_pc_plus_4;

    // ===========================================================
    // ██████  HAZARD DETECTION UNIT  ██████
    // ===========================================================

    // id_ex_flush has two independent sources:
    //   1. Load-use stall  (hazard_unit)
    //   2. Branch/jump taken flush (mem_branch_taken)
    // Use a separate wire for the hazard-unit output, then OR.

    logic id_ex_flush_hazard;

    hazard_unit hazard_inst (
        .idex_mem_read(ex_mem_read),
        .idex_rd      (ex_rd),
        .ifid_rs1     (id_rs1),
        .ifid_rs2     (id_rs2),
        .pc_write     (pc_write),
        .if_id_stall  (if_id_stall),
        .id_ex_flush  (id_ex_flush_hazard)
    );

    // Final ID/EX flush = load-use stall bubble OR branch/jump squash
    assign id_ex_flush = id_ex_flush_hazard || mem_branch_taken;

    // ===========================================================
    // ██████  SVA ASSERTIONS (simulation only)  ██████
    // ===========================================================
`ifndef SYNTHESIS

    always @(posedge clk) begin
        if (!reset) begin
            // x0 must always be zero
            assert (reg_file_inst.registers[0] == 32'b0)
                else $error("[SVA] x0 != 0 at if_pc=%0h", if_pc);

            // PC must be word-aligned
            assert (if_pc[1:0] == 2'b00)
                else $error("[SVA] PC misaligned: if_pc=%0h", if_pc);
        end
    end
`endif

endmodule
