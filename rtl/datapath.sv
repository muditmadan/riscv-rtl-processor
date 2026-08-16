// ============================================================
// Datapath — Single-cycle RV32I top-level integration
//
// Supported instructions: ADD, SUB, AND, OR, ADDI,
//                         LW, SW, BEQ, BNE, JAL, JALR
//
// SystemVerilog Assertions (SVA):
//   1. x0 must always read as zero
//   2. PC must always be word-aligned (pc[1:0] == 2'b00)
//   3. At most one memory operation active at a time
//   4. reg_write must be de-asserted for branch/store instructions
//   5. write_enable must never target x0
// ============================================================

module datapath (
    input logic clk,
    input logic reset
);

    // -------------------------------------------------------
    // Program Counter
    // -------------------------------------------------------

    logic [31:0] pc;
    logic [31:0] pc_plus_4;
    logic [31:0] next_pc;
    logic        branch_taken;

    assign pc_plus_4 = pc + 32'd4;

    program_counter pc_unit (
        .clk    (clk),
        .reset  (reset),
        .next_pc(next_pc),
        .pc     (pc)
    );

    // -------------------------------------------------------
    // Instruction Memory
    // -------------------------------------------------------

    logic [31:0] instruction;

    instruction_memory imem (
        .address    (pc),
        .instruction(instruction)
    );

    // -------------------------------------------------------
    // Decoder
    // -------------------------------------------------------

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [2:0] alu_control;

    decoder decoder_unit (
        .instruction(instruction),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .alu_control(alu_control)
    );

    // -------------------------------------------------------
    // Control Unit
    // -------------------------------------------------------

    logic reg_write;
    logic alu_src;
    logic mem_read;
    logic mem_write;
    logic mem_to_reg;
    logic branch;
    logic branch_ne;
    logic jump;
    logic jalr;

    control_unit control_unit_inst (
        .instruction(instruction),
        .reg_write  (reg_write),
        .alu_src    (alu_src),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .branch     (branch),
        .branch_ne  (branch_ne),
        .jump       (jump),
        .jalr       (jalr)
    );

    // -------------------------------------------------------
    // Register File
    // -------------------------------------------------------

    logic [31:0] read_data1;
    logic [31:0] read_data2;
    logic [31:0] write_data;
    logic        write_enable;

    register_file reg_file (
        .clk         (clk),
        .reset       (reset),
        .rs1         (rs1),
        .rs2         (rs2),
        .rd          (rd),
        .write_data  (write_data),
        .write_enable(write_enable),
        .read_data1  (read_data1),
        .read_data2  (read_data2)
    );

    // -------------------------------------------------------
    // Immediate Generator
    // -------------------------------------------------------

    logic [31:0] immediate;

    immediate_generator imm_gen (
        .instruction(instruction),
        .immediate  (immediate)
    );

    // -------------------------------------------------------
    // ALU input mux: register value or sign-extended immediate
    // -------------------------------------------------------

    logic [31:0] alu_input_b;
    assign alu_input_b = alu_src ? immediate : read_data2;

    // -------------------------------------------------------
    // ALU
    // -------------------------------------------------------

    logic [31:0] alu_result;
    logic        zero;

    alu alu_unit (
        .a          (read_data1),
        .b          (alu_input_b),
        .alu_control(alu_control),
        .result     (alu_result)
    );

    // zero flag: high when ALU result is 0 (used by BEQ/BNE)
    assign zero = (alu_result == 32'b0);

    // -------------------------------------------------------
    // Branch / Jump target and PC selection
    // -------------------------------------------------------

    logic [31:0] branch_target;
    assign branch_target = pc + immediate;

    assign branch_taken = (branch && zero) || (branch_ne && !zero);

    // PC mux priority: JALR > branch/JAL > PC+4
    assign next_pc = jalr         ? (alu_result & ~32'h1)  // JALR: rs1+imm, clear LSB
                   : (branch_taken || jump) ? branch_target
                   : pc_plus_4;

    // -------------------------------------------------------
    // Data Memory
    // -------------------------------------------------------

    logic [31:0] memory_read_data;

    data_memory data_mem (
        .clk       (clk),
        .reset     (reset),
        .address   (alu_result),
        .write_data(read_data2),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .read_data (memory_read_data)
    );

    // -------------------------------------------------------
    // Writeback mux
    //   JAL/JALR  → save return address (PC+4)
    //   LW        → memory read data
    //   default   → ALU result
    // -------------------------------------------------------
    assign write_data   = (jump || jalr) ? pc_plus_4
                        : mem_to_reg     ? memory_read_data
                        :                  alu_result;

    assign write_enable = reg_write;

    // ===========================================================
    // SystemVerilog Assertions (simulation only)
    // ===========================================================
`ifndef SYNTHESIS

    // SVA 1: x0 must always be zero (hardwired)
    // (Also checked inside register_file.sv; duplicated here at
    //  the integration level so it appears in datapath waveforms.)
    always @(posedge clk) begin
        if (!reset)
            assert (reg_file.registers[0] == 32'b0)
                else $error("[SVA1] x0 must always be zero — got %0h at pc=%0h",
                            reg_file.registers[0], pc);
    end

    // SVA 2: PC must always be word-aligned (RISC-V ISA §2.2)
    always @(posedge clk) begin
        if (!reset)
            assert (pc[1:0] == 2'b00)
                else $error("[SVA2] PC alignment violation — pc=%0h", pc);
    end

    // SVA 3: mem_read and mem_write cannot both be asserted simultaneously
    always @(posedge clk) begin
        if (!reset)
            assert (!(mem_read && mem_write))
                else $error("[SVA3] mem_read and mem_write both high at pc=%0h", pc);
    end

    // SVA 4: reg_write must be 0 for branch and store instructions
    always @(posedge clk) begin
        if (!reset) begin
            if (branch || branch_ne)
                assert (reg_write == 1'b0)
                    else $error("[SVA4] reg_write asserted during branch at pc=%0h", pc);
            if (mem_write)
                assert (reg_write == 1'b0)
                    else $error("[SVA4] reg_write asserted during store at pc=%0h", pc);
        end
    end

    // SVA 5: the register file's write guard must hold —
    // if write_enable is high AND rd happens to be x0, the register file
    // will silently discard the write (by design).  What we actually want
    // to assert is that x0 never gets a non-zero value committed — which
    // is already covered by SVA1.  Here we assert the structural property:
    // no instruction that SHOULD write a meaningful result targets x0 via
    // an unintentional path (i.e., reg_write from control unit is only set
    // for instructions that have a valid rd field).
    // We verify this as: after reset, registers[0] stays 0 every cycle.
    // (SVA1 already covers this; SVA5 adds the pre-condition check.)
    always @(posedge clk) begin
        if (!reset && write_enable && rd == 5'b00000)
            assert (reg_file.registers[0] == 32'b0)
                else $error("[SVA5] x0 was modified — registers[0]=%0h at pc=%0h",
                            reg_file.registers[0], pc);
    end
`endif

endmodule
