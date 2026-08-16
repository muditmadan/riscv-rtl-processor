// ============================================================
// riscv_tb.sv — RISC-V Instruction Subset Verification
//
// Tests all 11 target instructions with isolated test cases.
// Each test loads a minimal program, resets the DUT, runs for
// enough cycles, then checks register / memory values.
//
// Output format per check:
//   TEST <name>
//   Expected <reg/mem> = <value>
//   Actual   <reg/mem> = <value>
//   PASS  /  FAIL
//
// Also includes two top-level SVA property checks:
//   - x0 must always be zero
//   - PC must always be word-aligned
// ============================================================

`timescale 1ns/1ps

module riscv_tb;

    // -------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------
    logic clk;
    logic reset;

    int   pass_count;
    int   fail_count;

    datapath dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;   // 100 MHz clock, 10 ns period

    // -------------------------------------------------------
    // Top-level SVA — checked every rising edge
    // (Procedural immediate assertions, compatible with Icarus)
    // -------------------------------------------------------

    // SVA-TB-1: x0 must always read zero
    always @(posedge clk) begin
        if (!reset)
            assert (dut.reg_file.registers[0] == 32'b0)
                else $error("[SVA-TB-1] x0 must always be zero — got %0h at pc=%0h",
                            dut.reg_file.registers[0], dut.pc);
    end

    // SVA-TB-2: PC must always be word-aligned
    always @(posedge clk) begin
        if (!reset)
            assert (dut.pc[1:0] == 2'b00)
                else $error("[SVA-TB-2] PC alignment violation — pc=%0h", dut.pc);
    end

    // -------------------------------------------------------
    // Helper tasks
    // -------------------------------------------------------

    // Fill every instruction memory word with NOP (ADDI x0,x0,0)
    task automatic clear_imem();
        integer i;
        for (i = 0; i < 32; i = i + 1)
            dut.imem.memory[i] = 32'h00000013;
    endtask

    // Write one word to instruction memory
    task automatic load_inst(input int idx, input logic [31:0] inst);
        dut.imem.memory[idx] = inst;
    endtask

    // Assert reset for 2 cycles, then release
    task automatic reset_dut();
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);   // release on falling edge so PC=0 is stable before next posedge
        reset = 0;
    endtask

    // Advance n rising-edge clock cycles
    task automatic run_cycles(input int n);
        repeat (n) @(posedge clk);
    endtask

    // Check a register value and print PASS/FAIL
    task automatic check_reg(
        input string test_name,
        input int    reg_idx,
        input int    expected
    );
        int actual;
        actual = int'(dut.reg_file.registers[reg_idx]);
        $display("TEST  %s", test_name);
        $display("  Expected  x%0d = %0d", reg_idx, expected);
        $display("  Actual    x%0d = %0d", reg_idx, actual);
        if (actual === expected) begin
            $display("  --> PASS\n");
            pass_count++;
        end else begin
            $display("  --> FAIL\n");
            fail_count++;
        end
    endtask

    // Check a data memory word (word_addr is the byte address / 4)
    task automatic check_mem(
        input string test_name,
        input int    byte_addr,
        input int    expected
    );
        int actual;
        actual = int'(dut.data_mem.memory[byte_addr >> 2]);
        $display("TEST  %s", test_name);
        $display("  Expected  mem[%0d] = %0d", byte_addr, expected);
        $display("  Actual    mem[%0d] = %0d", byte_addr, actual);
        if (actual === expected) begin
            $display("  --> PASS\n");
            pass_count++;
        end else begin
            $display("  --> FAIL\n");
            fail_count++;
        end
    endtask

    // -------------------------------------------------------
    // Individual instruction tests
    //
    // Register file initialises on reset: x1=10, x2=20.
    // Each test starts with clear_imem + reset_dut so those
    // values are always available as operands.
    // -------------------------------------------------------

    // ---------------------------------------------------
    // ADD: x3 = x1 + x2 = 10 + 20 = 30
    // Encoding: ADD x3,x1,x2  funct7=0000000 rs2=x2 rs1=x1 funct3=000 rd=x3 opcode=0110011
    // ---------------------------------------------------
    task automatic test_add();
        clear_imem();
        load_inst(0, 32'h002081B3); // ADD x3, x1, x2
        reset_dut();
        run_cycles(2);              // cycle 1: fetch+exec, cycle 2: writeback committed
        check_reg("ADD  x3 = x1 + x2 = 10 + 20", 3, 30);
    endtask

    // ---------------------------------------------------
    // SUB: x3 = x2 - x1 = 20 - 10 = 10
    // Encoding: SUB x3,x2,x1  funct7=0100000 rs2=x1 rs1=x2 funct3=000 rd=x3 opcode=0110011
    // ---------------------------------------------------
    task automatic test_sub();
        clear_imem();
        load_inst(0, 32'h401101B3); // SUB x3, x2, x1
        reset_dut();
        run_cycles(2);
        check_reg("SUB  x3 = x2 - x1 = 20 - 10", 3, 10);
    endtask

    // ---------------------------------------------------
    // AND: x3 = x1 & x2 = 0b01010 & 0b10100 = 0
    // Encoding: AND x3,x1,x2  funct7=0000000 rs2=x2 rs1=x1 funct3=111 rd=x3 opcode=0110011
    // ---------------------------------------------------
    task automatic test_and();
        clear_imem();
        load_inst(0, 32'h0020F1B3); // AND x3, x1, x2
        reset_dut();
        run_cycles(2);
        check_reg("AND  x3 = x1 & x2 = 10 & 20", 3, 0);
    endtask

    // ---------------------------------------------------
    // OR: x3 = x1 | x2 = 0b01010 | 0b10100 = 30
    // Encoding: OR x3,x1,x2  funct7=0000000 rs2=x2 rs1=x1 funct3=110 rd=x3 opcode=0110011
    // ---------------------------------------------------
    task automatic test_or();
        clear_imem();
        load_inst(0, 32'h0020E1B3); // OR x3, x1, x2
        reset_dut();
        run_cycles(2);
        check_reg("OR   x3 = x1 | x2 = 10 | 20", 3, 30);
    endtask

    // ---------------------------------------------------
    // ADDI: x3 = x1 + 5 = 10 + 5 = 15
    // Encoding: ADDI x3,x1,5  imm=5 rs1=x1 funct3=000 rd=x3 opcode=0010011
    // ---------------------------------------------------
    task automatic test_addi();
        clear_imem();
        load_inst(0, 32'h00508193); // ADDI x3, x1, 5
        reset_dut();
        run_cycles(2);
        check_reg("ADDI x3 = x1 + 5 = 10 + 5", 3, 15);
    endtask

    // ---------------------------------------------------
    // SW + LW: store 30 to mem[100], load it back into x8
    //   word 0: ADD  x3, x1, x2  -> x3 = 30
    //   word 1: ADDI x7, x0, 100 -> x7 = 100
    //   word 2: SW   x3, 0(x7)   -> mem[100] = 30
    //   word 3: LW   x8, 0(x7)   -> x8 = 30
    // ---------------------------------------------------
    task automatic test_sw();
        clear_imem();
        load_inst(0, 32'h002081B3); // ADD  x3, x1, x2   -> x3 = 30
        load_inst(1, 32'h06400393); // ADDI x7, x0, 100
        load_inst(2, 32'h0033A023); // SW   x3, 0(x7)
        reset_dut();
        run_cycles(4);              // 3 instructions + 1 extra for sync write
        check_mem("SW   mem[100] = x3 = 30", 100, 30);
    endtask

    task automatic test_lw();
        clear_imem();
        load_inst(0, 32'h06400393); // ADDI x7, x0, 100
        load_inst(1, 32'h0003A403); // LW   x8, 0(x7)
        reset_dut();
        // Pre-load data memory word at byte address 100 (word index 25)
        dut.data_mem.memory[25] = 32'd77;
        run_cycles(3);
        check_reg("LW   x8 = mem[100] = 77", 8, 77);
    endtask

    // ---------------------------------------------------
    // BEQ: branch taken when x3 == x4
    //   word 0: ADDI x3, x0, 7    -> x3 = 7
    //   word 1: ADDI x4, x0, 7    -> x4 = 7
    //   word 2: BEQ  x3, x4, +8   -> equal, jump to PC=16 (word 4)
    //   word 3: ADDI x5, x0, 99   -> SKIPPED (PC=12)
    //   word 4: ADDI x5, x0, 1    -> branch target (PC=16); x5 = 1
    // ---------------------------------------------------
    task automatic test_beq();
        clear_imem();
        load_inst(0, 32'h00700193); // ADDI x3, x0, 7
        load_inst(1, 32'h00700213); // ADDI x4, x0, 7
        load_inst(2, 32'h00418463); // BEQ  x3, x4, +8
        load_inst(3, 32'h06300293); // ADDI x5, x0, 99  (skipped)
        load_inst(4, 32'h00100293); // ADDI x5, x0, 1   (target)
        reset_dut();
        run_cycles(5);
        check_reg("BEQ  branch taken: x5 must be 1 (not 99)", 5, 1);
    endtask

    // ---------------------------------------------------
    // BNE: branch taken when x1 != x2 (10 != 20 from reset)
    //   word 0: BNE  x1, x2, +8   -> not equal, jump to PC=8 (word 2)
    //   word 1: ADDI x3, x0, 99   -> SKIPPED (PC=4)
    //   word 2: ADDI x3, x0, 2    -> branch target (PC=8); x3 = 2
    // ---------------------------------------------------
    task automatic test_bne();
        clear_imem();
        load_inst(0, 32'h00209463); // BNE  x1, x2, +8  (x1=10, x2=20 → taken)
        load_inst(1, 32'h06300193); // ADDI x3, x0, 99  (skipped)
        load_inst(2, 32'h00200193); // ADDI x3, x0, 2   (target)
        reset_dut();
        run_cycles(3);
        check_reg("BNE  branch taken: x3 must be 2 (not 99)", 3, 2);
    endtask

    // ---------------------------------------------------
    // JAL: unconditional jump, save return address
    //   word 0: JAL  x5, +8       -> x5 = PC+4 = 4, jump to PC=8
    //   word 1: ADDI x3, x0, 99   -> SKIPPED (PC=4)
    //   word 2: ADDI x3, x0, 3    -> jump target (PC=8); x3 = 3
    // ---------------------------------------------------
    task automatic test_jal();
        clear_imem();
        load_inst(0, 32'h008002EF); // JAL  x5, +8
        load_inst(1, 32'h06300193); // ADDI x3, x0, 99  (skipped)
        load_inst(2, 32'h00300193); // ADDI x3, x0, 3   (target)
        reset_dut();
        run_cycles(3);
        check_reg("JAL  return addr: x5 must be 4 (PC+4)", 5, 4);
        check_reg("JAL  jump target: x3 must be 3 (not 99)", 3, 3);
    endtask

    // ---------------------------------------------------
    // JALR: jump to rs1 + imm, save return address
    //   word 0: ADDI x1, x0, 12   -> x1 = 12  (overrides reset x1=10)
    //   word 1: JALR x5, 0(x1)    -> x5 = PC+4 = 8, jump to 12+0=12
    //   word 2: ADDI x3, x0, 99   -> SKIPPED (PC=8)
    //   word 3: ADDI x3, x0, 42   -> JALR landing pad (PC=12); x3 = 42
    // ---------------------------------------------------
    task automatic test_jalr();
        clear_imem();
        load_inst(0, 32'h00C00093); // ADDI x1, x0, 12
        load_inst(1, 32'h000082E7); // JALR x5, 0(x1)
        load_inst(2, 32'h06300193); // ADDI x3, x0, 99  (skipped)
        load_inst(3, 32'h02A00193); // ADDI x3, x0, 42  (landing pad at PC=12)
        reset_dut();
        run_cycles(5);
        check_reg("JALR return addr: x5 must be 8 (PC+4)", 5, 8);
        check_reg("JALR jump target: x3 must be 42 (not 99)", 3, 42);
    endtask

    // -------------------------------------------------------
    // Main test flow
    // -------------------------------------------------------
    initial begin
        $dumpfile("riscv.vcd");
        $dumpvars(0, riscv_tb);

        clk        = 0;
        reset      = 1;
        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("============================================================");
        $display("  RISC-V Instruction Subset Verification  (Phase 2 / 3 / 4)");
        $display("============================================================");
        $display("  Instructions under test:");
        $display("    R-type : ADD  SUB  AND  OR");
        $display("    I-type : ADDI");
        $display("    Memory : LW  SW");
        $display("    Branch : BEQ  BNE");
        $display("    Jump   : JAL  JALR");
        $display("============================================================");
        $display("");

        // ---- R-type ----
        $display("--- R-type instructions ---");
        test_add();
        test_sub();
        test_and();
        test_or();

        // ---- I-type ----
        $display("--- I-type instructions ---");
        test_addi();

        // ---- Memory ----
        $display("--- Memory instructions ---");
        test_sw();
        test_lw();

        // ---- Branch ----
        $display("--- Branch instructions ---");
        test_beq();
        test_bne();

        // ---- Jump ----
        $display("--- Jump instructions ---");
        test_jal();
        test_jalr();

        // ---- Summary ----
        $display("============================================================");
        $display("  RESULTS : %0d PASSED,  %0d FAILED", pass_count, fail_count);
        $display("============================================================");
        $display("");

        if (fail_count != 0)
            $fatal(1, "Verification FAILED — %0d test(s) did not pass.", fail_count);

        $display("All tests passed. Verification complete.");
        $finish;
    end

endmodule
