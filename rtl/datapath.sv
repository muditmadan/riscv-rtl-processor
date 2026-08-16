module datapath (
    input logic clk,
    input logic reset
);

    // -------------------------
    // PC
    // -------------------------

    logic [31:0] pc;
    logic [31:0] pc_plus_4;
    logic [31:0] next_pc;
    logic        branch_taken;

    assign pc_plus_4 = pc + 32'd4;

    program_counter pc_unit (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );


    // -------------------------
    // Instruction Memory
    // -------------------------

    logic [31:0] instruction;

    instruction_memory imem (
        .address(pc),
        .instruction(instruction)
    );


    // -------------------------
    // Decoder
    // -------------------------

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;

    logic [2:0] alu_control;
    logic       mem_read;
    logic       mem_write;
    logic       mem_to_reg;

    decoder decoder_unit (
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_control(alu_control),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg)
    );


    // -------------------------
    // Register File
    // -------------------------

    logic [31:0] read_data1;
    logic [31:0] read_data2;

    logic [31:0] write_data;
    logic write_enable;

    register_file reg_file (
        .clk(clk),
        .reset(reset),

        .rs1(rs1),
        .rs2(rs2),

        .rd(rd),
        .write_data(write_data),
        .write_enable(write_enable),

        .read_data1(read_data1),
        .read_data2(read_data2)
    );


    // -------------------------
    // Immediate Generator
    // -------------------------

    logic [31:0] immediate;
    logic [31:0] alu_input_b;
    logic        alu_src;

    immediate_generator imm_gen (
        .instruction(instruction),
        .immediate(immediate)
    );

    assign alu_input_b = alu_src ? immediate : read_data2;

    // -------------------------
    // ALU
    // -------------------------

    logic [31:0] alu_result;

    alu alu_unit (
        .a(read_data1),
        .b(alu_input_b),
        .alu_control(alu_control),
        .result(alu_result)
    );

    // zero flag: 1 if alu_result == 0, 0 otherwise
    logic        zero;
    assign zero = (alu_result == 32'b0);

    // Declare branch control and jump signals early
    logic        branch;
    logic        branch_ne;
    logic        jump;
    logic        jalr;

    // Branch target: PC + immediate
    logic [31:0] branch_target;
    assign branch_target = pc + immediate;

    // PC MUX: choose between PC+4, branch target, or JALR target
    // JALR: jump to rs1 + immediate
    // BEQ/BNE: branch if condition true to PC + immediate
    // JAL: jump to PC + immediate
    // Default: PC + 4
    assign branch_taken = (branch && zero) || (branch_ne && !zero);
    assign next_pc = jalr ? alu_result : ((branch_taken || jump) ? branch_target : pc_plus_4);



    // -------------------------
    // Control Unit
    // -------------------------

    logic [6:0] opcode;
    logic reg_write;

    assign opcode = instruction[6:0];

    logic [2:0] funct3;
    assign funct3 = instruction[14:12];

    control_unit control_unit_inst (
        .opcode(opcode),
        .alu_control(alu_control),
        .funct3(funct3),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .branch(branch),
        .branch_ne(branch_ne),
        .jump(jump),
        .jalr(jalr)
    );


    // -------------------------
    // Data Memory
    // -------------------------

    logic [31:0] memory_read_data;

    data_memory data_mem (
        .clk(clk),
        .reset(reset),

        .address(alu_result),
        .write_data(read_data2),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .read_data(memory_read_data)
    );


    // Writeback MUX: select between PC+4 (JAL/JALR), memory data (LW), or ALU result
    // Priority: (JAL or JALR) > LW > ALU
    assign write_data = (jump || jalr) ? pc_plus_4 : (mem_to_reg ? memory_read_data : alu_result);

    // Control whether register file writes
    assign write_enable = reg_write;

    always @(posedge clk) begin
        $display("PC=%0d Instruction=%h rs1=%0d rs2=%0d rd=%0d ALU_Result=%0d",
                 pc,
                 instruction,
                 rs1,
                 rs2,
                 rd,
                 alu_result);
    end

endmodule