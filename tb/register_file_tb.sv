module register_file_tb;

    logic        clk;
    logic        reset;

    logic [4:0]  rs1;
    logic [4:0]  rs2;

    logic [4:0]  rd;
    logic [31:0] write_data;
    logic        write_enable;

    logic [31:0] read_data1;
    logic [31:0] read_data2;

    register_file dut (
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

    always #5 clk = ~clk;

    initial begin

        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);

        clk = 0;
        reset = 1;

        rs1 = 0;
        rs2 = 0;
        rd = 0;
        write_data = 0;
        write_enable = 0;

        #10;

        reset = 0;

        // Write 100 into x1
        rd = 5'd1;
        write_data = 32'd100;
        write_enable = 1;

        #10;

        // Write 200 into x2
        rd = 5'd2;
        write_data = 32'd200;

        #10;

        // Stop writing
        write_enable = 0;

        // Read x1 and x2
        rs1 = 5'd1;
        rs2 = 5'd2;

        #1;

        $display("x1 = %0d", read_data1);
        $display("x2 = %0d", read_data2);

        // Test x0
        rs1 = 5'd0;

        #1;

        $display("x0 = %0d", read_data1);

        $finish;

    end

endmodule