module control_unit (
    input  logic [2:0] alu_control,

    output logic       reg_write
);

    always_comb begin

        // Default: don't write to register file
        reg_write = 1'b0;

        // Valid ALU operation
        if (alu_control != 3'b000)
            reg_write = 1'b1;

    end

endmodule
