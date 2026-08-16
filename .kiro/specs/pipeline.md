# RISC-V 5-Stage Pipeline — Phases 7–13

## Requirements

### R1 — 5-Stage Pipeline Architecture (Phase 7)
Convert the existing single-cycle datapath (`rtl/datapath.sv`) into a 5-stage in-order pipeline:
- **IF** — Fetch instruction from instruction memory using current PC
- **ID** — Decode instruction; read register file
- **EX** — Execute in ALU; compute branch/jump targets
- **MEM** — Read or write data memory
- **WB** — Write result back to register file

All existing instructions must continue to work: ADD, SUB, AND, OR, ADDI, LW, SW, BEQ, BNE, JAL, JALR.

The pipeline top-level module is `pipeline/pipeline_datapath.sv`. It instantiates the same RTL sub-modules already in `rtl/` (ALU, register file, data memory, etc.) — no RTL sub-module is duplicated or rewritten.

### R2 — Pipeline Registers (Phase 8)
Four synchronous pipeline registers latch all signals that flow between stages:

| Register | File | Signals latched |
|---|---|---|
| IF/ID | `pipeline/if_id.sv` | `pc`, `pc_plus_4`, `instruction` |
| ID/EX | `pipeline/id_ex.sv` | `pc`, `pc_plus_4`, `instruction`, `rs1`, `rs2`, `rd`, `read_data1`, `read_data2`, `immediate`, `alu_control`, `reg_write`, `alu_src`, `mem_read`, `mem_write`, `mem_to_reg`, `branch`, `branch_ne`, `jump`, `jalr` |
| EX/MEM | `pipeline/ex_mem.sv` | `pc_plus_4`, `alu_result`, `zero`, `read_data2`, `rd`, `reg_write`, `mem_read`, `mem_write`, `mem_to_reg`, `branch`, `branch_ne`, `branch_target`, `jump`, `jalr` |
| MEM/WB | `pipeline/mem_wb.sv` | `alu_result`, `memory_read_data`, `rd`, `reg_write`, `mem_to_reg`, `pc_plus_4`, `jump`, `jalr` |

Each register has a synchronous reset (all fields zeroed), a `flush` input (same as reset, used for branch misprediction), and a `stall` input (holds current value, used for load-use hazard).

### R3 — Forwarding Unit (Phase 9)
Handles EX-EX and MEM-EX data hazards so back-to-back ALU instructions execute without stalls.

File: `pipeline/forwarding_unit.sv`

**Forwarding conditions:**

| Condition | Source | Forward to |
|---|---|---|
| EX/MEM.rd == ID/EX.rs1 and EX/MEM.reg_write | EX/MEM.alu_result | ALU input A |
| MEM/WB.rd == ID/EX.rs1 and MEM/WB.reg_write | WB write_data | ALU input A |
| EX/MEM.rd == ID/EX.rs2 and EX/MEM.reg_write | EX/MEM.alu_result | ALU input B (before alu_src mux) |
| MEM/WB.rd == ID/EX.rs2 and MEM/WB.reg_write | WB write_data | ALU input B (before alu_src mux) |

Forwarding does not apply when `rd == 5'b00000`.

Two 3-way MUXes sit in the EX stage:
- `forward_a` selects: `00` = register file, `01` = MEM/WB write_data, `10` = EX/MEM alu_result
- `forward_b` selects: `00` = register file, `01` = MEM/WB write_data, `10` = EX/MEM alu_result

### R4 — Hazard Detection Unit (Phase 10)
Handles the load-use hazard: an LW immediately followed by an instruction that reads the loaded register.

File: `pipeline/hazard_unit.sv`

**Detection condition:**
```
ID/EX.mem_read == 1
AND (ID/EX.rd == IF/ID.rs1  OR  ID/EX.rd == IF/ID.rs2)
```

**Action when hazard detected:**
1. **Stall** IF stage — PC does not increment
2. **Stall** IF/ID register — holds current instruction
3. **Flush** (bubble) ID/EX register — inserts NOP into EX stage

This adds exactly one stall cycle for each load-use hazard.

### R5 — Branch Handling
Branches are resolved at the end of the EX stage (when `zero` and `branch_taken` are known). On a taken branch or jump:
1. Flush IF/ID and ID/EX registers (2 instructions in flight behind the branch are squashed)
2. Redirect PC to the branch/jump target

This is a **flush-on-taken** strategy with a 2-cycle branch penalty.

### R6 — Synthesis (Phase 11)
Synthesize both designs using **Yosys** targeting the **sky130_fd_sc_hd** standard cell library.

Tool chain:
- Yosys 0.68 (already installed at `/opt/homebrew/bin/yosys`)
- OpenSTA for static timing analysis (to be installed via `brew install opensta`)
- sky130 PDK liberty file: `sky130_fd_sc_hd__tt_025C_1v80.lib` (downloaded from `google/skywater-pdk`)

Synthesis scripts live in `synthesis/`:
- `synth_single_cycle.ys` — synthesizes `rtl/datapath.sv` and its sub-modules
- `synth_pipeline.ys` — synthesizes `pipeline/pipeline_datapath.sv` and its sub-modules
- `sta_single_cycle.tcl` — OpenSTA timing script for single-cycle
- `sta_pipeline.tcl` — OpenSTA timing script for pipeline

**Metrics to capture** (actual numbers from tool output — no estimates):
- Cell area (µm²)
- Number of cells
- Critical path delay (ns)
- Maximum operating frequency (MHz) = 1000 / critical_path_ns
- Gate count

### R7 — Design Comparison (Phase 12)
A comparison table populated with actual synthesis numbers goes into `README.md`:

| Metric | Single-cycle | 5-stage pipeline |
|---|---|---|
| Technology | sky130 130nm | sky130 130nm |
| Cell area (µm²) | TBD | TBD |
| Cell count | TBD | TBD |
| Critical path (ns) | TBD | TBD |
| Max frequency (MHz) | TBD | TBD |
| CPI (ideal) | 1 | 1 |
| CPI (with hazards) | 1 | >1 (stalls) |

### R8 — Repository Structure (Phase 13)
Final directory layout after all phases complete:

```
RISCV/
├── rtl/                        # single-cycle RTL (unchanged from Phase 1-4)
│   ├── alu.sv
│   ├── control_unit.sv
│   ├── data_memory.sv
│   ├── datapath.sv
│   ├── decoder.sv
│   ├── immediate_generator.sv
│   ├── instruction_memory.sv
│   ├── program_counter.sv
│   └── register_file.sv
├── pipeline/                   # NEW — pipelined CPU
│   ├── if_id.sv
│   ├── id_ex.sv
│   ├── ex_mem.sv
│   ├── mem_wb.sv
│   ├── forwarding_unit.sv
│   ├── hazard_unit.sv
│   └── pipeline_datapath.sv
├── tb/
│   ├── alu_tb.sv               # unit test (existing)
│   ├── datapath_tb.sv          # single-cycle integration (existing)
│   ├── riscv_tb.sv             # single-cycle verification (existing)
│   └── pipeline_tb.sv          # NEW — pipeline verification
├── synthesis/
│   ├── synth_single_cycle.ys
│   ├── synth_pipeline.ys
│   ├── sta_single_cycle.tcl
│   ├── sta_pipeline.tcl
│   └── results/
│       ├── single_cycle_synth.txt
│       ├── single_cycle_timing.txt
│       ├── pipeline_synth.txt
│       └── pipeline_timing.txt
└── README.md
```

---

## Design

### D1 — Pipeline Stage Boundaries

The single-cycle design already has correct sub-modules. The pipeline wraps them with registers. No existing RTL file changes.

```
Stage  Clock Edge  What happens
-----  ----------  ---------------------------------------------------
IF     rising      PC → imem → instruction captured into IF/ID
ID     rising      IF/ID → decoder, reg_file reads → captured into ID/EX
EX     rising      ID/EX → forwarding mux → ALU → branch logic → EX/MEM
MEM    rising      EX/MEM → data_memory → captured into MEM/WB
WB     rising      MEM/WB → writeback mux → register_file write
```

Each stage is purely combinational between register edges — no latches.

### D2 — PC Update Logic

```
next_pc = flush_taken ? branch_target_exmem
        : stall       ? pc           (hold)
        :               pc + 4
```

`flush_taken` is asserted when EX/MEM shows a taken branch or any jump. This squashes the two wrong-path instructions in IF and ID.

### D3 — Forwarding MUX Placement

```
EX stage:
  alu_a_raw = ID/EX.read_data1
  alu_b_raw = ID/EX.read_data2

  alu_a = forward_a==2'b10 ? EX/MEM.alu_result
        : forward_a==2'b01 ? wb_write_data
        : alu_a_raw

  alu_b_pre = forward_b==2'b10 ? EX/MEM.alu_result
            : forward_b==2'b01 ? wb_write_data
            : alu_b_raw

  alu_b = ID/EX.alu_src ? ID/EX.immediate : alu_b_pre
```

Note: the immediate MUX is applied *after* the forwarding MUX on input B, so forwarding and immediate selection compose correctly.

### D4 — Writeback Data (WB stage)

```
wb_write_data = (MEM/WB.jump || MEM/WB.jalr) ? MEM/WB.pc_plus_4
              : MEM/WB.mem_to_reg             ? MEM/WB.memory_read_data
              :                                 MEM/WB.alu_result
```

This is the value also forwarded back to the EX stage forwarding MUX.

### D5 — Branch Flush Timing

Branch resolved at end of EX stage (posedge of cycle 3 after fetch):
- `flush_taken = (EX_MEM_branch && EX_MEM_zero) || (EX_MEM_branch_ne && !EX_MEM_zero) || EX_MEM_jump || EX_MEM_jalr`
- On the same posedge: IF/ID and ID/EX are flushed (written with zeros/NOPs)
- PC is redirected to `EX_MEM_branch_target` or `EX_MEM_alu_result` (for JALR)

### D6 — Load-Use Hazard Stall Timing

Hazard detected in ID stage, acting on ID/EX register content:
- Cycle N:   LW in EX, dependent inst in ID — hazard detected
- Cycle N+1: LW in MEM, bubble (NOP) in EX, dependent inst stalled in ID/IF
- Cycle N+2: LW in WB, NOP in MEM, forwarding from MEM/WB satisfies the dependent inst in EX

Only 1 stall cycle needed because forwarding from MEM/WB covers the N+2 case.

### D7 — Pipeline Testbench (`tb/pipeline_tb.sv`)

Same structure as `riscv_tb.sv`: isolated per-instruction tests with PASS/FAIL. Additional tests for:
- RAW hazard: ADD then SUB using ADD's result (forwarding, no stall)
- Load-use hazard: LW then ADD using loaded value (1 stall cycle)
- Branch: BEQ taken (2-cycle flush penalty)
- JAL / JALR with correct return addresses

---

## Tasks

- [ ] **T1** — Create `pipeline/` directory and four pipeline register modules: `if_id.sv`, `id_ex.sv`, `ex_mem.sv`, `mem_wb.sv`
- [ ] **T2** — Create `pipeline/forwarding_unit.sv`
- [ ] **T3** — Create `pipeline/hazard_unit.sv`
- [ ] **T4** — Create `pipeline/pipeline_datapath.sv` — wires all stages, registers, forwarding, and hazard units together
- [ ] **T5** — Create `tb/pipeline_tb.sv` — verifies all 11 instructions plus forwarding, stall, and branch flush scenarios; all tests PASS
- [ ] **T6** — Compile and run `pipeline_tb.sv` under Icarus; fix all errors until clean
- [ ] **T7** — Install OpenSTA and download `sky130_fd_sc_hd__tt_025C_1v80.lib`
- [ ] **T8** — Write `synthesis/synth_single_cycle.ys` and `synthesis/synth_pipeline.ys`; run Yosys synthesis on both designs
- [ ] **T9** — Write `synthesis/sta_single_cycle.tcl` and `synthesis/sta_pipeline.tcl`; run OpenSTA; record critical path and max frequency for both
- [ ] **T10** — Write `README.md` with architecture description, block diagram (ASCII), comparison table filled with actual synthesis numbers, and instructions to reproduce
