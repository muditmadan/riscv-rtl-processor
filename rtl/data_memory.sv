module data_memory (
    input  logic        clk,
    input  logic        reset,

    input  logic [31:0] address,
    input  logic [31:0] write_data,

    input  logic        mem_read,
    input  logic        mem_write,

    output logic [31:0] read_data
);

    logic [31:0] memory [0:255];

    integer i;

    // Initialize memory
    always_ff @(posedge clk) begin

        if (reset) begin
            for (i = 0; i < 256; i = i + 1)
                memory[i] <= 32'b0;
        end

        else if (mem_write) begin
            memory[address >> 2] <= write_data;
        end

    end

    // Read memory
    always_comb begin

        if (mem_read)
            read_data = memory[address >> 2];

        else
            read_data = 32'b0;

    end

endmodule