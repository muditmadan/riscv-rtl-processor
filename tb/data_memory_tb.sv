module data_memory_tb;

    logic clk;
    logic reset;

    logic [31:0] address;
    logic [31:0] write_data;

    logic mem_read;
    logic mem_write;

    logic [31:0] read_data;

    data_memory dut (
        .clk(clk),
        .reset(reset),
        .address(address),
        .write_data(write_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;

        address = 0;
        write_data = 0;
        mem_read = 0;
        mem_write = 0;

        #10;

        reset = 0;

        // Store 100 at address 0
        address = 32'd0;
        write_data = 32'd100;
        mem_write = 1;

        #10;

        mem_write = 0;

        // Read from address 0
        mem_read = 1;

        #10;

        $display("Read Data = %0d", read_data);

        $finish;

    end

endmodule