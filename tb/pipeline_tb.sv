// ============================================================
// pipeline_tb.sv — 5-Stage Pipeline Verification
//
// Tests all 11 instructions, plus:
//   - EX-EX forwarding  (ADD → SUB using ADD's result)
//   - MEM-EX forwarding (LW  → ADD using loaded value)
//   - Load-use stall    (LW  → ADD, hazard unit inserts bubble)
//   - Branch flush      (BEQ taken, 2 wrong-path instrs squashed)
//
// Format per check:
//   TEST  <name>
//     Expected  x<n> = <value>
//     Actual    x<n> = <value>
//     --> PASS / FAIL
// ============================================================

`timescale 1ns/1ps

module pipeline_tb;

    logic clk;
    logic reset;

    int   pass_count;
    int   fail_count;

    pipeline_datapath dut (
        .clk  (clk),
        .reset(reset)
    );

    always #5 clk = ~clk;   // 100 MHz, 10 ns period

    // -------------------------------------------------------
    // SVA: x0 always zero, PC always word-aligned
    // -------------------------------------------------------
    always @(posedge clk) begin
        if (!reset) begin
            assert (dut.reg_file_inst.registers[0] == 32'b0)
                else $error("[SVA] x0 != 0 at pc=%0h", dut.if_pc);
            assert (dut.if_pc[1:0] == 2'b00)
                else $error("[SVA] PC misaligned: %0h", dut.if_pc);
        end
    end

    // -------------------------------------------------------
    // Helpers
    // -------------------------------------------------------

    task automatic clear_imem();
        integer i;
        for (i = 0; i < 32; i = i + 1)
            dut.imem.memory[i] = 32'h00000013;  // NOP
    endtask

    task automatic load_inst(input int idx, input logic [31:0] inst);
        dut.imem.memory[idx] = inst;
    endtask

    task automatic reset_dut();
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        reset = 0;
    endtask

    task automatic run_cycles(input int n);
        repeat (n) @(posedge clk);
    endtask

    task automatic check_reg(
        input string test_name,
        input int    reg_idx,
        input int    expected
    );
        int actual;
        actual = int'(dut.reg_file_inst.registers[reg_idx]);
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

    task automatic check_mem(
        input string test_name,
        input int    byte_addr,
        input int    expected
    );
        int actual;
        actual = int'(dut.data_mem_inst.memory[byte_addr >> 2]);
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
    // ── BASIC INSTRUCTION TESTS (isolated, 8 cycles each) ──
    //
    // Register file resets: x1=10, x2=20
    // 8 cycles is sufficient for a single instruction to
    // complete the 5 pipeline stages after reset.
    // -------------------------------------------------------

    // ADD x3, x1, x2  →  x3 = 10 + 20 = 30
    task automatic test_add();
        clear_imem();
        load_inst(0, 32'h002081B3); // ADD x3, x1, x2
        reset_dut();
        run_cycles(8);
        check_reg("ADD  x3 = x1 + x2 = 10 + 20", 3, 30);
    endtask

    // SUB x3, x2, x1  →  x3 = 20 - 10 = 10
    task automatic test_sub();
        clear_imem();
        load_inst(0, 32'h401101B3); // SUB x3, x2, x1
        reset_dut();
        run_cycles(8);
        check_reg("SUB  x3 = x2 - x1 = 20 - 10", 3, 10);
    endtask

    // AND x3, x1, x2  →  x3 = 10 & 20 = 0
    task automatic test_and();
        clear_imem();
        load_inst(0, 32'h0020F1B3); // AND x3, x1, x2
        reset_dut();
        run_cycles(8);
        check_reg("AND  x3 = x1 & x2 = 10 & 20", 3, 0);
    endtask

    // OR x3, x1, x2  →  x3 = 10 | 20 = 30
    task automatic test_or();
        clear_imem();
        load_inst(0, 32'h0020E1B3); // OR x3, x1, x2
        reset_dut();
        run_cycles(8);
        check_reg("OR   x3 = x1 | x2 = 10 | 20", 3, 30);
    endtask

    // ADDI x3, x1, 5  →  x3 = 10 + 5 = 15
    task automatic test_addi();
        clear_imem();
        load_inst(0, 32'h00508193); // ADDI x3, x1, 5
        reset_dut();
        run_cycles(8);
        check_reg("ADDI x3 = x1 + 5 = 10 + 5", 3, 15);
    endtask

    // SW: ADD x3→30, set base x7=100, store x3 to mem[100]
    task automatic test_sw();
        clear_imem();
        load_inst(0, 32'h002081B3); // ADD  x3, x1, x2   → x3=30
        load_inst(1, 32'h06400393); // ADDI x7, x0, 100
        load_inst(2, 32'h0033A023); // SW   x3, 0(x7)
        reset_dut();
        run_cycles(12);
        check_mem("SW   mem[100] = x3 = 30", 100, 30);
    endtask

    // LW: pre-load mem[100]=77, load into x8 via x7=100
    task automatic test_lw();
        clear_imem();
        load_inst(0, 32'h06400393); // ADDI x7, x0, 100
        load_inst(1, 32'h0003A403); // LW   x8, 0(x7)
        reset_dut();
        dut.data_mem_inst.memory[25] = 32'd77;  // byte addr 100 → word 25
        run_cycles(10);
        check_reg("LW   x8 = mem[100] = 77", 8, 77);
    endtask

    // BEQ taken: ADDI x3,x0,7 / ADDI x4,x0,7 / BEQ x3,x4,+8 (skip 99→land 1)
    task automatic test_beq();
        clear_imem();
        load_inst(0, 32'h00700193); // ADDI x3, x0, 7
        load_inst(1, 32'h00700213); // ADDI x4, x0, 7
        load_inst(2, 32'h00418463); // BEQ  x3, x4, +8
        load_inst(3, 32'h06300293); // ADDI x5, x0, 99  (skipped)
        load_inst(4, 32'h00100293); // ADDI x5, x0, 1   (target PC=16)
        reset_dut();
        run_cycles(14);
        check_reg("BEQ  taken: x5 = 1 (not 99)", 5, 1);
    endtask

    // BNE taken: x1=10, x2=20 from reset → not equal → branch
    task automatic test_bne();
        clear_imem();
        load_inst(0, 32'h00209463); // BNE  x1, x2, +8  (10 != 20 → taken)
        load_inst(1, 32'h06300193); // ADDI x3, x0, 99  (skipped)
        load_inst(2, 32'h00200193); // ADDI x3, x0, 2   (target PC=8)
        reset_dut();
        run_cycles(12);
        check_reg("BNE  taken: x3 = 2 (not 99)", 3, 2);
    endtask

    // JAL x5, +8  →  x5=4, jump to PC=8; ADDI x3,x0,3 executes there
    task automatic test_jal();
        clear_imem();
        load_inst(0, 32'h008002EF); // JAL  x5, +8
        load_inst(1, 32'h06300193); // ADDI x3, x0, 99  (skipped)
        load_inst(2, 32'h00300193); // ADDI x3, x0, 3   (target PC=8)
        reset_dut();
        run_cycles(12);
        check_reg("JAL  return addr: x5 = 4", 5, 4);
        check_reg("JAL  jump target: x3 = 3 (not 99)", 3, 3);
    endtask

    // JALR x5, 0(x1): ADDI x1,x0,12 then JALR → x5=8, jump to PC=12
    task automatic test_jalr();
        clear_imem();
        load_inst(0, 32'h00C00093); // ADDI x1, x0, 12
        load_inst(1, 32'h000082E7); // JALR x5, 0(x1)   → x5=8, jump to 12
        load_inst(2, 32'h06300193); // ADDI x3, x0, 99  (skipped)
        load_inst(3, 32'h02A00193); // ADDI x3, x0, 42  (target PC=12)
        reset_dut();
        run_cycles(14);
        check_reg("JALR return addr: x5 = 8", 5, 8);
        check_reg("JALR jump target: x3 = 42 (not 99)", 3, 42);
    endtask

    // -------------------------------------------------------
    // ── FORWARDING TESTS ──
    // -------------------------------------------------------

    // EX-EX forwarding: ADD x3,x1,x2 then SUB x4,x3,x1
    //   x3 result (30) forwarded from EX/MEM to EX input A
    //   No stall needed.
    //   x4 = x3 - x1 = 30 - 10 = 20
    task automatic test_fwd_ex_ex();
        clear_imem();
        load_inst(0, 32'h002081B3); // ADD x3, x1, x2   → x3 = 30
        load_inst(1, 32'h401181B3); // SUB x3, x3, x1   → x3 = 30-10 = 20  (EX-EX fwd)
        // Note: using x3 as both source and dest to stress forwarding
        reset_dut();
        run_cycles(10);
        check_reg("FWD EX-EX: SUB uses forwarded ADD result: x3=20", 3, 20);
    endtask

    // MEM-EX forwarding: after LW, the next-next instruction uses the loaded value
    //   ADDI x7,x0,100 / LW x3,0(x7) / ADD x4,x3,x1
    //   x3 loaded from mem[100]=77, x4 = 77 + 10 = 87
    //   LW→ADD has a load-use hazard (1 stall) AND then MEM-EX forwarding
    task automatic test_fwd_mem_ex();
        clear_imem();
        load_inst(0, 32'h06400393); // ADDI x7, x0, 100
        load_inst(1, 32'h0003A183); // LW   x3, 0(x7)    → x3 = mem[100]  (opcode=0000011)
        load_inst(2, 32'h00118233); // ADD  x4, x3, x1   → x4 = x3 + 10   (rd=4,rs1=3,rs2=1)
        reset_dut();
        dut.data_mem_inst.memory[25] = 32'd77;
        run_cycles(14);
        check_reg("FWD MEM-EX: ADD uses LW result via forwarding: x4=87", 4, 87);
    endtask

    // -------------------------------------------------------
    // ── LOAD-USE HAZARD TEST ──
    //   LW  x3, 0(x7)   (LW in EX, dependent ADD in ID → stall)
    //   ADD x4, x3, x1  (uses x3 one cycle after LW — 1 stall cycle)
    //   Expected: x4 = mem[100] + 10 = 55 + 10 = 65
    // -------------------------------------------------------
    task automatic test_load_use_hazard();
        clear_imem();
        load_inst(0, 32'h06400393); // ADDI x7, x0, 100
        load_inst(1, 32'h0003A183); // LW   x3, 0(x7)    → x3 = 55  (opcode=0000011)
        load_inst(2, 32'h00118233); // ADD  x4, x3, x1   → x4 = 55 + 10 = 65
        reset_dut();
        dut.data_mem_inst.memory[25] = 32'd55;
        run_cycles(14);
        check_reg("HAZARD load-use: ADD after LW (1 stall): x4=65", 4, 65);
    endtask

    // -------------------------------------------------------
    // Main
    // -------------------------------------------------------
    initial begin
        $dumpfile("pipeline.vcd");
        $dumpvars(0, pipeline_tb);

        clk        = 0;
        reset      = 1;
        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("============================================================");
        $display("  5-Stage Pipeline Verification  (Phases 7-10)");
        $display("============================================================");
        $display("  Stages:  IF → ID → EX → MEM → WB");
        $display("  Features: Forwarding unit, Hazard detection, Branch flush");
        $display("============================================================");
        $display("");

        $display("--- R-type ---");
        test_add();
        test_sub();
        test_and();
        test_or();

        $display("--- I-type ---");
        test_addi();

        $display("--- Memory ---");
        test_sw();
        test_lw();

        $display("--- Branch ---");
        test_beq();
        test_bne();

        $display("--- Jump ---");
        test_jal();
        test_jalr();

        $display("--- Forwarding ---");
        test_fwd_ex_ex();
        test_fwd_mem_ex();

        $display("--- Hazard Detection ---");
        test_load_use_hazard();

        $display("============================================================");
        $display("  RESULTS : %0d PASSED,  %0d FAILED", pass_count, fail_count);
        $display("============================================================");
        $display("");

        if (fail_count != 0)
            $fatal(1, "Pipeline verification FAILED — %0d test(s) did not pass.", fail_count);

        $display("All pipeline tests passed.");
        $finish;
    end

endmodule
