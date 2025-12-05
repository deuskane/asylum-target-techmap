# asylum-target-techmap

Set of technology cells for the Asylum project, providing both generic (inferred) implementations and technology-specific implementations for various FPGA platforms.

## Table of Contents

- [asylum-target-techmap](#asylum-target-techmap)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
    - [Key Features](#key-features)
    - [Project Structure](#project-structure)
  - [Modules](#modules)
    - [CBUFG - Clock Buffer Global](#cbufg---clock-buffer-global)
      - [Generics](#generics)
      - [Ports](#ports)
      - [Operation](#operation)
    - [CGATE - Clock Gate](#cgate---clock-gate)
      - [Generics](#generics-1)
      - [Ports](#ports-1)
      - [Operation](#operation-1)
    - [SYNC2DFF - 2 FF Synchronizer](#sync2dff---2-ff-synchronizer)
      - [Generics](#generics-2)
      - [Ports](#ports-2)
      - [Operation](#operation-2)
    - [SYNC2DFFRN - 2 FF Synchronizer with Async Reset](#sync2dffrn---2-ff-synchronizer-with-async-reset)
      - [Generics](#generics-3)
      - [Ports](#ports-3)
      - [Operation](#operation-3)

## Introduction

The `asylum-target-techmap` repository contains a library of technology cells that provide common digital design primitives across different FPGA platforms. These cells include clock management, synchronization, and gating functions that are fundamental building blocks in digital systems.

Set of technology cells

| Name       | Description |
|------------|-------------|
| cbufg      | Clock Buffer Global |
| cgate      | Clock Gate |
| sync2dff   | 2 FF synchronizer |
| sync2dffrn | 2 FF synchronizer with asynchronous reset active low|

| VLNV                          | Flag                        | Description                                         |
|-------------------------------|-----------------------------|-----------------------------------------------------|
| asylum:target:generic         | N/A                         | Inferred Technology Cells                           |
| nanoxplore:target:ng_medium   | TARGET_NANOXPLORE_NG_MEDIUM | Technology Cells for FPGA NG_MEDIUM from NanoXplore | 


### Key Features

- **Multi-target support**: Supports both generic (technology-independent) and technology-specific implementations
- **Clock management**: Provides clock buffering and gating primitives
- **CDC (Clock Domain Crossing)**: Synchronization primitives with and without asynchronous reset
- **Portable design**: Generic implementations allow designs to be synthesized across platforms, with technology-specific cells available for optimized implementations

### Project Structure

```
asylum-target-techmap/
├── hdl/                          # HDL source files
│   ├── generic/                  # Technology-independent implementations
│   │   ├── cbufg.vhd
│   │   ├── cgate.vhd
│   │   ├── sync2dff.vhd
│   │   ├── sync2dffrn.vhd
│   │   └── techmap_pkg.vhd       # Component package
│   └── ng_medium/                # NanoXplore NG_MEDIUM specific implementations
│       └── cbufg.vhd
├── sim/                          # Simulation files
│   └── src/
│       └── tb_dummy.vhd          # Dummy testbench
├── mk/                           # Build infrastructure
│   ├── defs.mk
│   └── targets.txt
├── target_techmap.core           # FuseSoC wrapper
├── target_generic.core           # FuseSoC generic target
└── target_ng_medium.core         # FuseSoC NanoXplore target
```

## Modules

### CBUFG - Clock Buffer Global

**File**: `hdl/generic/cbufg.vhd`

This module implements a global clock buffer, typically used to distribute high-fanout clock signals with minimal skew and delay.

#### Generics

| Name | Type | Default | Description |
|------|------|---------|-------------|
| (None) | - | - | This module has no generic parameters |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `d_i` | input | `std_logic` | Input clock signal |
| `d_o` | output | `std_logic` | Output buffered clock signal |

#### Operation

The CBUFG module provides a simple clock buffer abstraction. In the generic implementation, it acts as a direct connection. For technology-specific implementations (such as NanoXplore NG_MEDIUM), this module can instantiate platform-specific primitives (e.g., `NX_BD` or `NX_CSC`) to provide optimal clock distribution with reduced skew and jitter.

---

### CGATE - Clock Gate

**File**: `hdl/generic/cgate.vhd`

This module implements an integrated clock gate (ICG) cell, used to selectively disable clock signals to reduce dynamic power consumption when functional blocks are idle.

#### Generics

| Name | Type | Default | Description |
|------|------|---------|-------------|
| (None) | - | - | This module has no generic parameters |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | input | `std_logic` | Input clock signal |
| `cke_i` | input | `std_logic` | Clock enable command (active high): `0` = disable clock, `1` = enable clock |
| `clk_o` | output | `std_logic` | Gated output clock |
| `dft_te_i` | input | `std_logic` | DFT test enable (active high) |

#### Operation

The CGATE module implements a latch-based integrated clock gate. The operation is as follows:

1. The clock enable signal is combined with the test enable via OR logic: `cke <= cke_i OR dft_te_i`
2. On the low phase of the input clock, the latch captures the current state of `cke`, storing it in `cke_l`
3. The output clock is generated by ANDing the input clock with the latched enable signal: `clk_o <= clk_i AND cke_l`

This approach ensures that:
- Clock glitches are minimized by capturing the enable signal on the non-active clock edge
- The test mode can force the clock to remain active regardless of the `cke_i` input
- Power is reduced when `cke_i` is low and the gate is not in test mode

---

### SYNC2DFF - 2 FF Synchronizer

**File**: `hdl/generic/sync2dff.vhd`

This module implements a two-stage flip-flop synchronizer, used to safely transfer asynchronous signals from one clock domain to another, reducing metastability risk.

#### Generics

| Name | Type | Default | Description |
|------|------|---------|-------------|
| (None) | - | - | This module has no generic parameters |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | input | `std_logic` | Input clock signal |
| `d_i` | input | `std_logic` | Input data signal (asynchronous) |
| `q_o` | output | `std_logic` | Synchronized output data signal |

#### Operation

The SYNC2DFF module implements a simple two-stage synchronization chain:

1. The input signal `d_i` is passed through two cascaded flip-flops on each rising clock edge
2. The first flip-flop captures the asynchronous input, potentially entering a metastable state
3. The second flip-flop (fed by the first) provides sufficient time for metastability to resolve
4. The output `q_o` is taken from the second flip-flop, providing a synchronized signal

The module uses a 2-bit internal shift register `q_r` that shifts in new data on each clock cycle:
- `q_r(0)` captures the input `d_i`
- `q_r(1)` provides the final synchronized output to `q_o`

This architecture significantly reduces (though does not eliminate) the probability of metastable output states.

---

### SYNC2DFFRN - 2 FF Synchronizer with Async Reset

**File**: `hdl/generic/sync2dffrn.vhd`

This module is similar to SYNC2DFF but includes an additional asynchronous reset input, allowing external reset logic to quickly clear the synchronization chain.

#### Generics

| Name | Type | Default | Description |
|------|------|---------|-------------|
| (None) | - | - | This module has no generic parameters |

#### Ports

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | input | `std_logic` | Input clock signal |
| `arst_b_i` | input | `std_logic` | Asynchronous reset (active low) |
| `d_i` | input | `std_logic` | Input data signal (asynchronous) |
| `q_o` | output | `std_logic` | Synchronized output data signal |

#### Operation

The SYNC2DFFRN module operates identically to SYNC2DFF during normal operation but adds asynchronous reset capability:

1. When `arst_b_i = '0'` (active low reset), the entire internal shift register `q_r` is asynchronously cleared to all zeros
2. When `arst_b_i = '1'` (inactive), normal synchronization operation proceeds as in SYNC2DFF
3. The output `q_o` is taken from the second flip-flop, providing a synchronized signal

The asynchronous reset is useful in designs that need to quickly initialize the synchronization chain without waiting for clock edges, particularly important during power-up or when exiting low-power modes.

