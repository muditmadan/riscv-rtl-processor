// ============================================================
// Forwarding Unit
//
// Resolves EX-EX and MEM-EX RAW data hazards by selecting
// the most recent value of a source register.
//
// forward_a / forward_b encoding:
//   2'b00  — no hazard: use register file output (ID/EX stage)
//   2'b01  — MEM-EX hazard: forward from WB write_data (MEM/WB)
//   2'b10  — EX-EX hazard: forward from EX/MEM alu_result
//
// EX-EX takes priority over MEM-EX when both match
// (can happen if the same register appears twice, but the
// younger EX/MEM value is always more recent).
//
// Forwarding is suppressed for rd == x0 (writes to x0 are
// discarded, so forwarding them would be incorrect).
// ============================================================

module forwarding_unit (
    // Source register indices in the EX stage (from ID/EX)
    input  logic [4:0] ex_rs1,
    input  logic [4:0] ex_rs2,

    // Destination register + write-enable from EX/MEM stage
    input  logic [4:0] exmem_rd,
    input  logic       exmem_reg_write,

    // Destination register + write-enable from MEM/WB stage
    input  logic [4:0] memwb_rd,
    input  logic       memwb_reg_write,

    // Forwarding select outputs
    output logic [1:0] forward_a,   // mux select for ALU input A
    output logic [1:0] forward_b    // mux select for ALU input B
);

    // -------------------------------------------------------
    // forward_a
    // -------------------------------------------------------
    always_comb begin
        if (exmem_reg_write && (exmem_rd != 5'b0) && (exmem_rd == ex_rs1))
            forward_a = 2'b10;   // EX-EX: forward from EX/MEM
        else if (memwb_reg_write && (memwb_rd != 5'b0) && (memwb_rd == ex_rs1))
            forward_a = 2'b01;   // MEM-EX: forward from MEM/WB
        else
            forward_a = 2'b00;   // no hazard
    end

    // -------------------------------------------------------
    // forward_b
    // -------------------------------------------------------
    always_comb begin
        if (exmem_reg_write && (exmem_rd != 5'b0) && (exmem_rd == ex_rs2))
            forward_b = 2'b10;   // EX-EX: forward from EX/MEM
        else if (memwb_reg_write && (memwb_rd != 5'b0) && (memwb_rd == ex_rs2))
            forward_b = 2'b01;   // MEM-EX: forward from MEM/WB
        else
            forward_b = 2'b00;   // no hazard
    end

endmodule
