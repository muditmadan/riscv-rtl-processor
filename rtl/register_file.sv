module register_file (
    input  logic        clk,
    input  logic        reset,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,

    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    input  logic        write_enable,

    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    // 32 registers, each 32 bits wide
    logic [31:0] registers [0:31];

    integer i;

    // Write operation
    always_ff @(posedge clk) begin

        if (reset) begin

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;

            registers[1] <= 32'd10;
            registers[2] <= 32'd20;

        end
        else if (write_enable && (rd != 5'b00000)) begin

            registers[rd] <= write_data;

        end

    end

    // x0 is hardwired to zero and must never hold a non-zero value
`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (!reset)
            assert (registers[0] == 32'b0)
                else $error("x0 register violation: x0=%0h", registers[0]);
    end
`endif

    // Read operations
    always_comb begin

        if (rs1 == 5'b00000)
            read_data1 = 32'b0;
        else
            read_data1 = registers[rs1];

        if (rs2 == 5'b00000)
            read_data2 = 32'b0;
        else
            read_data2 = registers[rs2];

    end

endmodule