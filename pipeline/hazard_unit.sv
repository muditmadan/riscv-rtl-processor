// ============================================================
// Hazard Detection Unit
//
// Detects the load-use hazard:
//   LW  x3, 0(x1)
//   ADD x4, x3, x2    <- needs x3 one cycle too early
//
// The LW result is not available until the end of the MEM
// stage, which is too late to forward to the immediately
// following instruction's EX stage.  One stall cycle is
// inserted between them.
//
// Detection condition (evaluated while LW is in ID/EX):
//   ID/EX.mem_read == 1
//   AND ( ID/EX.rd == IF/ID.rs1  OR  ID/EX.rd == IF/ID.rs2 )
//
// Actions when hazard is detected:
//   pc_write  = 0  -> freeze PC (do not advance)
//   if_id_stall = 1 -> freeze IF/ID register (re-fetch same instr)
//   id_ex_flush = 1 -> flush ID/EX register (insert NOP bubble)
//
// After one stall cycle the LW result is in MEM/WB and the
// forwarding unit handles the rest automatically.
// ============================================================

module hazard_unit (
    // From ID/EX register
    input  logic       idex_mem_read,
    input  logic [4:0] idex_rd,

    // Source register indices of the instruction currently in ID
    // (read from IF/ID.instruction by the decoder)
    input  logic [4:0] ifid_rs1,
    input  logic [4:0] ifid_rs2,

    // Stall / flush outputs
    output logic       pc_write,       // 1 = normal, 0 = stall (hold PC)
    output logic       if_id_stall,    // 1 = stall IF/ID register
    output logic       id_ex_flush     // 1 = flush ID/EX register (bubble)
);

    logic load_use_hazard;

    assign load_use_hazard =
        idex_mem_read &&
        (idex_rd != 5'b0) &&
        ((idex_rd == ifid_rs1) || (idex_rd == ifid_rs2));

    // Active-low style for stall signals:
    //   pc_write = 0 means "hold" (stall); normal operation = 1
    assign pc_write    = ~load_use_hazard;
    assign if_id_stall = load_use_hazard;
    assign id_ex_flush = load_use_hazard;

endmodule
