<!--
  README GENERATION INSTRUCTIONS (for the next regeneration run)
  ----------------------------------------------------------------
  This README follows the common Asylum IP model. Regenerate it from the
  sources, never from the previous README text alone.

  Sources of truth (in priority order):
    1. hdl/*.vhd            : entities, generics, ports, packages
    2. hdl/csr/*.hjson      : register map (regtool); *_csr.md/.h are generated
    3. <IP>.core            : VLNV (name), filesets, targets, depends, revisions
    4. mk/targets.txt       : target list shown by `make help`; mk/defs.mk
    5. sim/, syn/, esw/, boards/ : testbenches, constraints, software
  Section order (keep it, same headings in every IP):
    CI badge / Title + one-line description + VLNV / Table of Contents /
    Introduction (Key Features) / Block Diagram / Top-Level (Parameters,
    Ports, Instantiation Example) / HDL Modules / Register Map /
    Verification / Synthesis / Design Notes (optional) /
    Directory Structure / Dependencies
  Rules:
    - Language: English. Tables: Parameters = Name|Type|Default|Description,
      Ports = Name|Direction|Type|Description (grouped by interface).
    - Register Map: link to the generated hdl/csr/<X>_csr.md (plus the
      .hjson source and _csr.h header); never copy register tables here.
    - Top-Level = sbi_* wrapper if present, else the entity used by the
      `default` target, else the main entity (libraries: list packages).
    - Write "This IP has no software-visible registers." / "No dedicated
      synthesis target ..." instead of removing a section.
    - Keep still-accurate hand-written content (ISA tables, results,
      images) in "Design Notes"; drop anything not backed by the sources.
    - Block diagram: doc/<NAME>.drawio (NAME = 4th field of the VLNV),
      top entity box with generics on top, inputs left, outputs right,
      bus interfaces as bold arrows, internal blocks colour-coded
      (CSR yellow, FIFO/memory green, core logic blue, external grey).
      Update it whenever ports/generics/sub-blocks change.
    - Do not edit generated files (hdl/csr/*_csr.*) or the CI badge URL.
-->
[![CI](https://github.com/deuskane/asylum-target-techmap/actions/workflows/ci.yml/badge.svg)](https://github.com/deuskane/asylum-target-techmap/actions/workflows/ci.yml)

# asylum-target-techmap

**Technology cell library (clock buffer, clock gate, 2-FF synchronizers, I/O buffers) with a generic inferred implementation and a NanoXplore NG-MEDIUM variant, selected by a FuseSoC flag.**

VLNV: `asylum:target:techmap:1.0.0`

## Table of Contents

1. [Introduction](#introduction)
2. [Block Diagram](#block-diagram)
3. [Top-Level](#top-level)
4. [HDL Modules](#hdl-modules)
5. [Register Map](#register-map)
6. [Verification](#verification)
7. [Synthesis](#synthesis)
8. [Design Notes](#design-notes)
9. [Directory Structure](#directory-structure)
10. [Dependencies](#dependencies)

## Introduction

This repository isolates the technology-dependent cells of the Asylum project behind one package, `asylum.techmap_pkg`. IPs depend on the wrapper core `asylum:target:techmap` and instantiate the cells by name; the wrapper pulls in exactly one technology core, which compiles the package and an implementation of every cell into library `asylum`. Three FuseSoC cores live in the repository:

| Core file | VLNV | Content |
|-----------|------|---------|
| [target_techmap.core](target_techmap.core) | `asylum:target:techmap:1.0.0` | Wrapper, no file: selects one of the two cores below |
| [target_generic.core](target_generic.core) | `asylum:target:generic:1.1.5` | Inferred (technology-independent) cells, default |
| [target_ng_medium.core](target_ng_medium.core) | `nanoxplore:target:ng_medium:1.0.5` | NanoXplore NG-MEDIUM cells (flag `TARGET_NANOXPLORE_NG_MEDIUM`) |

The Makefile works on `target_generic.core` (`mk/defs.mk`), which also holds the lint and simulation targets.

### Key Features

- Single component package `techmap_pkg` (`hdl/common/`) shared by all technologies
- Clock cells: `cbufg` (global clock buffer), `cgate` (latch-based clock gate with DFT test enable)
- CDC cells: `sync2dff`, `sync2dffrn` (2-FF synchronizers, without / with asynchronous reset)
- I/O cells: `ibuf`, `obuf`, `iobuf` with generic-controlled inversion of data / enables and a configurable value when the input is disabled
- Technology selection by FuseSoC flag, no source change in the consuming IPs
- NG-MEDIUM variant: `cbufg` mapped on the `NX_WFG` primitive; all other cells shared with the generic core

## Block Diagram

Diagram: [doc/techmap.drawio](doc/techmap.drawio) (open with diagrams.net or the VS Code Draw.io extension).

- `target_techmap.core` (`asylum:target:techmap`) chooses `target_ng_medium.core` when `TARGET_NANOXPLORE_NG_MEDIUM` is set, `target_generic.core` otherwise.
- Both technology cores compile `hdl/common/techmap_pkg.vhd` and the shared cells of `hdl/generic/` (`cgate`, `sync2dff`, `sync2dffrn`, `ibuf`, `obuf`, `iobuf`).
- Only `cbufg` differs: a wire in `hdl/generic/cbufg.vhd`, an `NX_WFG` instance in `hdl/ng_medium/cbufg.vhd`.
- No port is drawn: each cell has its own interface (see Top-Level).

## Top-Level

Library IP: there is no single top-level. Units compiled in library `asylum`:

| Unit | Kind | File | Description |
|------|------|------|-------------|
| `techmap_pkg` | package | [hdl/common/techmap_pkg.vhd](hdl/common/techmap_pkg.vhd) | Component declarations of all cells |
| `cbufg` | entity | [hdl/generic/cbufg.vhd](hdl/generic/cbufg.vhd) | Global clock buffer, generic: `d_o <= d_i` |
| `cbufg` | entity | [hdl/ng_medium/cbufg.vhd](hdl/ng_medium/cbufg.vhd) | Global clock buffer, NG-MEDIUM: `NX_WFG` instance |
| `cgate` | entity | [hdl/generic/cgate.vhd](hdl/generic/cgate.vhd) | Clock gate (latch + AND) |
| `sync2dff` | entity | [hdl/generic/sync2dff.vhd](hdl/generic/sync2dff.vhd) | 2-FF synchronizer |
| `sync2dffrn` | entity | [hdl/generic/sync2dffrn.vhd](hdl/generic/sync2dffrn.vhd) | 2-FF synchronizer with asynchronous reset |
| `ibuf` | entity | [hdl/generic/ibuf.vhd](hdl/generic/ibuf.vhd) | Input buffer |
| `obuf` | entity | [hdl/generic/obuf.vhd](hdl/generic/obuf.vhd) | Tri-state output buffer |
| `iobuf` | entity | [hdl/generic/iobuf.vhd](hdl/generic/iobuf.vhd) | Bidirectional buffer |

### Parameters

Only the I/O buffers have generics (all of type std_logic):

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `INPUT_VALUE_DISABLED` | std_logic | `'0'` | `ibuf`, `iobuf`: value of `d_o` when the input is disabled |
| `INVERT_D_I` | std_logic | `'0'` | `obuf`, `iobuf`: `'1'` inverts `d_i` before driving `buf_io` |
| `INVERT_D_O` | std_logic | `'0'` | `ibuf`, `iobuf`: `'1'` inverts `buf_io` before `d_o` |
| `INVERT_OE_I` | std_logic | `'0'` | `obuf`, `iobuf`: `'1'` makes `oe_i` active low |
| `INVERT_IE_I` | std_logic | `'0'` | `ibuf`, `iobuf`: `'1'` makes `ie_i` active low |

`cbufg`, `cgate`, `sync2dff` and `sync2dffrn` have no generic.

### Ports

#### cbufg

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `d_i` | in | std_logic | Input clock |
| `d_o` | out | std_logic | Buffered clock |

#### cgate

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | Input clock |
| `cke_i` | in | std_logic | Clock enable, active high (0: clock stopped low, 1: clock running) |
| `clk_o` | out | std_logic | Gated clock |
| `dft_te_i` | in | std_logic | DFT test enable, active high (forces the clock on) |

#### sync2dff / sync2dffrn

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | Destination clock |
| `arst_b_i` | in | std_logic | `sync2dffrn` only: asynchronous reset, active low (chain cleared to 0) |
| `d_i` | in | std_logic | Asynchronous input |
| `q_o` | out | std_logic | Synchronized output (2 clock cycles of latency) |

#### ibuf / obuf / iobuf

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `buf_io` | inout | std_logic | Pad side (driven by `obuf` / `iobuf`; `ibuf` only reads it and drives `'Z'`) |
| `d_i` | in | std_logic | `obuf`, `iobuf`: data to drive on the pad |
| `oe_i` | in | std_logic | `obuf`, `iobuf`: output enable (`buf_io` = `'Z'` when disabled) |
| `d_o` | out | std_logic | `ibuf`, `iobuf`: data read from the pad |
| `ie_i` | in | std_logic | `ibuf`, `iobuf`: input enable (`d_o` = `INPUT_VALUE_DISABLED` when disabled) |

### Instantiation Example

```vhdl
library asylum;
use     asylum.techmap_pkg.all;

  -- Resynchronize an external signal in the clk domain
  ins_sync : sync2dffrn
    port map
    ( clk_i    => clk
     ,arst_b_i => arst_b
     ,d_i      => button_async
     ,q_o      => button_sync
    );

  -- Bidirectional pad with active-low output enable
  ins_pad_sda : iobuf
    generic map
    ( INPUT_VALUE_DISABLED => '1'
     ,INVERT_D_I           => '0'
     ,INVERT_D_O           => '0'
     ,INVERT_OE_I          => '1'
     ,INVERT_IE_I          => '0'
    )
    port map
    ( buf_io => sda_io
     ,d_i    => sda_out
     ,d_o    => sda_in
     ,oe_i   => sda_oe_b
     ,ie_i   => '1'
    );
```

The consuming core only declares `asylum:target:techmap` in its `depend:` list; the technology is chosen when the flow runs (see Synthesis).

## HDL Modules

| File | Unit | Kind | Role |
|------|------|------|------|
| [hdl/common/techmap_pkg.vhd](hdl/common/techmap_pkg.vhd) | `techmap_pkg` | package | Components (both cores) |
| [hdl/generic/cbufg.vhd](hdl/generic/cbufg.vhd) | `cbufg` | entity | Generic core only |
| [hdl/ng_medium/cbufg.vhd](hdl/ng_medium/cbufg.vhd) | `cbufg` | entity | NG-MEDIUM core only (library `nx`) |
| [hdl/generic/cgate.vhd](hdl/generic/cgate.vhd) | `cgate` | entity | Both cores |
| [hdl/generic/sync2dff.vhd](hdl/generic/sync2dff.vhd) | `sync2dff` | entity | Both cores |
| [hdl/generic/sync2dffrn.vhd](hdl/generic/sync2dffrn.vhd) | `sync2dffrn` | entity | Both cores |
| [hdl/generic/ibuf.vhd](hdl/generic/ibuf.vhd) | `ibuf` | entity | Both cores |
| [hdl/generic/obuf.vhd](hdl/generic/obuf.vhd) | `obuf` | entity | Both cores |
| [hdl/generic/iobuf.vhd](hdl/generic/iobuf.vhd) | `iobuf` | entity | Both cores |

### cbufg

| Core | File | Implementation |
|------|------|----------------|
| `asylum:target:generic` | hdl/generic/cbufg.vhd | `d_o <= d_i` (the synthesis tool infers the clock buffer) |
| `nanoxplore:target:ng_medium` | hdl/ng_medium/cbufg.vhd | `NX_WFG` (`nx.nxPackage`) with `wfg_edge => '0'`, `mode => '0'` (no pattern), `delay_on => '0'`, `RDY => '1'`; `NX_BD` (`global_lowskew`) and `NX_CSC` alternatives are present but commented out |

### cgate

`cke = cke_i or dft_te_i` is captured by a latch transparent while `clk_i = '0'`, and `clk_o = clk_i and cke_l`: the enable can only change while the clock is low, so `clk_o` has no glitch.

### sync2dff / sync2dffrn

2-bit shift register `q_r` clocked on the rising edge of `clk_i`, `q_o = q_r(1)`. `sync2dffrn` clears the chain asynchronously when `arst_b_i = '0'`; `sync2dff` has no reset.

### ibuf / obuf / iobuf

| Cell | Pad drive | Input path |
|------|-----------|------------|
| `ibuf` | `'Z'` (never drives) | `d_o = buf_io` (inverted if `INVERT_D_O`) when `ie` = 1, else `INPUT_VALUE_DISABLED` |
| `obuf` | `buf_io = d_i` (inverted if `INVERT_D_I`) when `oe` = 1, else `'Z'` | none |
| `iobuf` | as `obuf` | as `ibuf` |

`oe` / `ie` are `oe_i` / `ie_i` inverted when `INVERT_OE_I` / `INVERT_IE_I` = `'1'`. `INPUT_VALUE_DISABLED` is not affected by `INVERT_D_O`.

## Register Map

This IP has no software-visible registers.

## Verification

### Testbenches

| File | DUT | Description |
|------|-----|-------------|
| [sim/src/tb_techmap.vhd](sim/src/tb_techmap.vhd) | all generic cells (components of `techmap_pkg`) | Self-checking UVVM testbench. `cbufg`: `d_o = d_i` for `'0'` / `'1'`, clock passed without delay. `cgate`: clock gated / running, `cke_i` falling or rising (and a 1 ns glitch) during the high phase has no effect until the clock is low, `cke_i` changing during the low phase acts on the next pulse, `dft_te_i` forces the clock; a monitor checks that every `clk_o` pulse starts on a rising edge of `clk_i` and lasts a full half period. `sync2dff`: 2-edge latency in both directions, 1-cycle pulse. `sync2dffrn`: held at 0 during reset, 2-edge latency, asynchronous reset between two edges clears the whole chain. `ibuf` (8 generic combinations), `obuf` (4) and `iobuf` (32): `d_o` / pad value for every `oe_i` / `ie_i` / `d_i` / external pad value, `'Z'` on the pad when the output is disabled, iobuf loopback. 1227 checks |
| [sim/src/tb_dummy.vhd](sim/src/tb_dummy.vhd) | every cell | Elaboration check only (lint): one component instance of each cell from `techmap_pkg`, inputs tied to `'0'`, outputs open, no stimulus and no check |

### Targets

`mk/targets.txt` lists the targets of `target_generic.core` (`FILE_CORE ?= target_generic.core`):

| Target | Toplevel | Description |
|--------|----------|-------------|
| `default` | *(none)* | Default Target (DON'T RUN): `hdl` fileset only |
| `lint_generic` | `tb_dummy` | Lint (elaboration of every generic cell): `hdl` + `sim` filesets, GHDL with `-fsynopsys` |
| `sim_techmap` | `tb_techmap` | Self-checking UVVM testbench of the generic cells: `hdl` + `sim_uvvm` filesets (depends on `bitvis:verification:uvvm`), GHDL `-Wall -frelaxed` |

`target_ng_medium.core` and `target_techmap.core` only have a `default` target (DON'T RUN).

### How to Run

The default tool is GHDL (`mk/defs.mk`: `TOOL ?= ghdl`, `TARGET ?= sim_techmap`).

```bash
make help                 # variables, rules and target list (mk/targets.txt)
make sim_techmap          # run the UVVM testbench (log in log/)
make lint_generic         # analyze / elaborate / run tb_dummy
make nonreg_sim           # run every sim_* target (sim_techmap)
make nonreg_lint          # run every lint_* target (lint_generic)
make clean                # remove build/ and log/
```

Equivalent FuseSoC command:

```bash
fusesoc --cores-root . run --build-root build --target sim_techmap asylum:target:generic:1.1.5
```

The CI workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs the `sim_techmap` job (generated from the `sim_*` targets by `make ci_generate`).

## Synthesis

No dedicated synthesis target: the cells are synthesized inside the consuming designs.

- **Technology selection**: the `default` target of `target_techmap.core` uses the filesets `"TARGET_NANOXPLORE_NG_MEDIUM ? (target_nanoxplore_ng_medium)"` and `"!TARGET_NANOXPLORE_NG_MEDIUM ? (target_generic)"`. Without the flag the generic cells are used; to map on NG-MEDIUM, set the flag for the run, e.g. `fusesoc run --flag TARGET_NANOXPLORE_NG_MEDIUM ...` or `flags: {TARGET_NANOXPLORE_NG_MEDIUM: true}` in the target of the consuming core. No core of the project sets this flag today.
- **NG-MEDIUM**: `hdl/ng_medium/cbufg.vhd` needs library `nx` (`nxPackage`), supplied by the NanoXplore tools; it is not a FuseSoC dependency.
- **Generic cells**: plain RTL without simulation-only code. `cgate` describes a latch (inferred as such), `sync2dff` / `sync2dffrn` carry no synthesis attribute (no `ASYNC_REG`-like constraint), and the I/O buffers rely on `'Z'` assignments, so they must end up at the chip / FPGA top level to map on pads.

## Design Notes

- To add a technology: create `hdl/<tech>/` with the cells that differ, a `target_<tech>.core` listing `hdl/common/techmap_pkg.vhd` plus the generic and specific files, and a flag-conditioned fileset in `target_techmap.core`.
- Every implementation of a cell must keep the entity interface declared in `techmap_pkg`, since consumers instantiate the components of that package.
- `techmap_pkg` moved from `hdl/generic/` to `hdl/common/` in `asylum:target:generic:1.1.4` / `nanoxplore:target:ng_medium:1.0.4`.

## Directory Structure

```
asylum-target-techmap/
├── target_techmap.core         # FuseSoC wrapper (asylum:target:techmap)
├── target_generic.core         # FuseSoC core (asylum:target:generic)
├── target_ng_medium.core       # FuseSoC core (nanoxplore:target:ng_medium)
├── Makefile                    # Common Asylum Makefile (FuseSoC wrapper)
├── mk/
│   ├── defs.mk                 # FILE_CORE (target_generic.core), default TARGET and TOOL
│   └── targets.txt             # Target list (generated from the .core)
├── doc/
│   └── techmap.drawio          # Block diagram
├── hdl/
│   ├── common/
│   │   └── techmap_pkg.vhd
│   ├── generic/
│   │   ├── cbufg.vhd
│   │   ├── cgate.vhd
│   │   ├── ibuf.vhd
│   │   ├── iobuf.vhd
│   │   ├── obuf.vhd
│   │   ├── sync2dff.vhd
│   │   └── sync2dffrn.vhd
│   └── ng_medium/
│       └── cbufg.vhd
├── sim/
│   └── src/
│       ├── tb_techmap.vhd      # Self-checking UVVM testbench (sim_techmap)
│       └── tb_dummy.vhd        # Elaboration testbench (lint_generic)
└── .github/workflows/ci.yml    # CI (sim_techmap job)
```

## Dependencies

| Core | Used by (fileset) | Purpose |
|------|-------------------|---------|
| `asylum:target:generic` | `target_generic` (target_techmap.core) | Generic cells, selected when `TARGET_NANOXPLORE_NG_MEDIUM` is not set |
| `nanoxplore:target:ng_medium` | `target_nanoxplore_ng_medium` (target_techmap.core) | NG-MEDIUM cells, selected when `TARGET_NANOXPLORE_NG_MEDIUM` is set |

| `bitvis:verification:uvvm` | `sim_uvvm` (target_generic.core) | UVVM utility library for `tb_techmap` |

The `hdl` filesets of `target_generic.core` and `target_ng_medium.core` have no `depend:`. Cores of the project depending on `asylum:target:techmap`: `asylum:system:mailbox`, `asylum:system:spinlock`, `asylum:communication:SPI` (models fileset), and the GIC, UART, clock divider and PicoSoC cores.
