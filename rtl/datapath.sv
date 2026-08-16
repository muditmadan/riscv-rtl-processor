module datapath (
    input logic clk,
    input logic reset
);

    // -------------------------
    // PC
    // -------------------------

    logic [31:0] pc;

    program_counter pc_unit (
        .clk(clk),
        .reset(reset),
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

    decoder decoder_unit (
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_control(alu_control)
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
    // Control Unit
    // -------------------------

    logic reg_write;

    control_unit control_unit_inst (
        .alu_control(alu_control),
        .reg_write(reg_write)
    );


    // -------------------------
    // ALU
    // -------------------------

    logic [31:0] alu_result;

    alu alu_unit (
        .a(read_data1),
        .b(read_data2),
        .alu_control(alu_control),
        .result(alu_result)
    );


    // ALU result goes back to Register File
    assign write_data = alu_result;

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