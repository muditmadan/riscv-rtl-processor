module datapath_tb;

    logic clk;
    logic reset;

    datapath dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("datapath.vcd");
        $dumpvars(0, datapath_tb);

        clk = 0;
        reset = 1;

        #12;
        reset = 0;

        #200;
        $finish;
    end

endmodule
