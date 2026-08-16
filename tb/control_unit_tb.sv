module control_unit_tb;

    logic [31:0] instruction;

    logic reg_write;
    logic alu_src;
    logic mem_read;
    logic mem_write;
    logic mem_to_reg;
    logic branch;
    logic branch_ne;
    logic jump;
    logic jalr;

    control_unit dut (
        .instruction(instruction),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .branch_ne(branch_ne),
        .jump(jump),
        .jalr(jalr)
    );

    task check(
        input string name,
        input exp_reg_write,
        input exp_alu_src,
        input exp_mem_read,
        input exp_mem_write,
        input exp_mem_to_reg,
        input exp_branch,
        input exp_branch_ne,
        input exp_jump,
        input exp_jalr
    );
        if (reg_write !== exp_reg_write || alu_src !== exp_alu_src ||
            mem_read !== exp_mem_read || mem_write !== exp_mem_write ||
            mem_to_reg !== exp_mem_to_reg || branch !== exp_branch ||
            branch_ne !== exp_branch_ne || jump !== exp_jump || jalr !== exp_jalr) begin
            $display("FAIL %s", name);
            $display("  got  rw=%b as=%b mr=%b mw=%b mtr=%b br=%b bne=%b jmp=%b jalr=%b",
                     reg_write, alu_src, mem_read, mem_write, mem_to_reg,
                     branch, branch_ne, jump, jalr);
            $fatal(1);
        end
        else
            $display("PASS %s", name);
    endtask

    initial begin
        instruction = 32'h002081B3; // ADD
        #1;
        check("ADD", 1, 0, 0, 0, 0, 0, 0, 0, 0);

        instruction = 32'h40208233; // SUB
        #1;
        check("SUB", 1, 0, 0, 0, 0, 0, 0, 0, 0);

        instruction = 32'h0020F2B3; // AND
        #1;
        check("AND", 1, 0, 0, 0, 0, 0, 0, 0, 0);

        instruction = 32'h0020E333; // OR
        #1;
        check("OR", 1, 0, 0, 0, 0, 0, 0, 0, 0);

        instruction = 32'h00508193; // ADDI
        #1;
        check("ADDI", 1, 1, 0, 0, 0, 0, 0, 0, 0);

        instruction = 32'h0002A503; // LW
        #1;
        check("LW", 1, 1, 1, 0, 1, 0, 0, 0, 0);

        instruction = 32'h0032A023; // SW
        #1;
        check("SW", 0, 1, 0, 1, 0, 0, 0, 0, 0);

        instruction = 32'h00208463; // BEQ
        #1;
        check("BEQ", 0, 0, 0, 0, 0, 1, 0, 0, 0);

        instruction = 32'h00209463; // BNE
        #1;
        check("BNE", 0, 0, 0, 0, 0, 0, 1, 0, 0);

        instruction = 32'h008006EF; // JAL
        #1;
        check("JAL", 1, 0, 0, 0, 0, 0, 0, 1, 0);

        instruction = 32'h004080E7; // JALR
        #1;
        check("JALR", 1, 1, 0, 0, 0, 0, 0, 0, 1);

        $display("All control unit tests passed.");
        $finish;
    end

endmodule
