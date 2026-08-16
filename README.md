# RV32I RISC-V Processor in SystemVerilog

A SystemVerilog RTL implementation of a RISC-V RV32I processor, including a
single-cycle datapath, instruction decoding, control logic, memory subsystem,
verification testbenches, and a 5-stage pipelined implementation.

## Overview

This project implements a custom RISC-V processor from the RTL level.

The project was developed to understand and implement:

- RISC-V instruction formats
- Datapath design
- Control-unit design
- Register-file architecture
- ALU design
- Immediate generation
- Branch and jump handling
- Load/store memory operations
- RTL verification
- SystemVerilog assertions
- Pipeline architecture
- Hazard detection and forwarding
- RTL synthesis

---

## Architecture

### Single-Cycle Processor

The main processor implements a single-cycle RISC-V datapath:

```text
                 ┌─────────────────┐
                 │ Instruction     │
                 │ Memory          │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ Decoder /       │
                 │ Control Unit    │
                 └────────┬────────┘
                          │
             ┌────────────┴────────────┐
             ▼                         ▼
      ┌─────────────┐           ┌──────────────┐
      │ Register    │           │ Immediate    │
      │ File        │           │ Generator    │
      └──────┬──────┘           └──────┬───────┘
             │                         │
             └──────────┬──────────────┘
                        ▼
                  ┌───────────┐
                  │    ALU    │
                  └─────┬─────┘
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
       ┌─────────────┐      ┌─────────────┐
       │ Data Memory  │      │ Writeback   │
       └─────────────┘      └──────┬──────┘
                                   │
                                   ▼
                             Register File