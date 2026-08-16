// ============================================================
// Instruction Memory — 32-word ROM (PC-addressed, word-indexed)
//
// Default program exercises all 11 target instructions:
//   ADD, SUB, AND, OR, ADDI, SW, LW, BEQ, BNE, JAL, JALR
//
// Uninitialized slots default to NOP (ADDI x0, x0, 0 = 32'h00000013).
// ============================================================

module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:31];

    initial begin
        // --- Fill entire ROM with NOP first ---
        // NOP = ADDI x0, x0, 0 = 32'h00000013
        integer k;
        for (k = 0; k < 32; k = k + 1)
            memory[k] = 32'h00000013;

        // -----------------------------------------------
        // PC=0  (word 0):  ADDI x1, x0, 10   -> x1 = 10
        memory[0]  = 32'h00A00093;

        // PC=4  (word 1):  ADDI x2, x0, 5    -> x2 = 5
        memory[1]  = 32'h00500113;

        // PC=8  (word 2):  ADD  x3, x1, x2   -> x3 = 15
        memory[2]  = 32'h002081B3;

        // PC=12 (word 3):  SUB  x4, x1, x2   -> x4 = 5
        memory[3]  = 32'h40208233;

        // PC=16 (word 4):  AND  x5, x1, x2   -> x5 = 0  (10 & 5 = 0)
        memory[4]  = 32'h0020F2B3;

        // PC=20 (word 5):  OR   x6, x1, x2   -> x6 = 15 (10 | 5 = 15)
        memory[5]  = 32'h0020E333;

        // PC=24 (word 6):  ADDI x7, x0, 100  -> x7 = 100 (memory base)
        memory[6]  = 32'h06400393;

        // PC=28 (word 7):  SW   x3, 0(x7)    -> mem[100] = 15
        memory[7]  = 32'h0033A023;

        // PC=32 (word 8):  LW   x8, 0(x7)    -> x8 = 15
        memory[8]  = 32'h0003A403;

        // PC=36 (word 9):  BEQ  x3, x8, +8   -> x3==x8 (both 15), branch to PC=44
        memory[9]  = 32'h00818463;

        // PC=40 (word 10): ADDI x9, x0, 99   -> SKIPPED by BEQ
        memory[10] = 32'h06300493;

        // PC=44 (word 11): ADDI x10, x0, 1   -> BEQ branch target; x10 = 1
        memory[11] = 32'h00100513;

        // PC=48 (word 12): BNE  x1, x2, +8   -> x1!=x2 (10!=5), branch to PC=56
        memory[12] = 32'h00209463;

        // PC=52 (word 13): ADDI x11, x0, 99  -> SKIPPED by BNE
        memory[13] = 32'h06300593;

        // PC=56 (word 14): ADDI x12, x0, 2   -> BNE branch target; x12 = 2
        memory[14] = 32'h00200613;

        // PC=60 (word 15): JAL  x13, +8      -> x13 = 64, jump to PC=68
        memory[15] = 32'h008006EF;

        // PC=64 (word 16): ADDI x14, x0, 99  -> SKIPPED by JAL
        memory[16] = 32'h06300713;

        // PC=68 (word 17): ADDI x15, x0, 3   -> JAL target; x15 = 3
        memory[17] = 32'h00300793;

        // PC=72 (word 18): ADDI x1, x0, 88   -> x1 = 88 (JALR base)
        memory[18] = 32'h05800093;

        // PC=76 (word 19): JALR x16, 0(x1)   -> x16 = 80, jump to PC=88
        memory[19] = 32'h00008867;

        // PC=80 (word 20): NOP               -> SKIPPED by JALR (pre-filled above)
        // PC=84 (word 21): NOP               -> SKIPPED by JALR (pre-filled above)

        // PC=88 (word 22): ADDI x17, x0, 42  -> JALR landing pad; x17 = 42
        memory[22] = 32'h02A00893;

        // PC=92+ : NOP (pre-filled above)
    end

    always_comb begin
        instruction = memory[address >> 2];
    end

endmodule
