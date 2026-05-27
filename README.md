![](../../workflows/gds/badge.svg)
![](../../workflows/docs/badge.svg)
![](../../workflows/test/badge.svg)
![](../../workflows/fpga/badge.svg)

# PolyTrig – TinyTapeout Digital Waveform Synthesis Core

PolyTrig is a TinyTapeout-compatible digital waveform synthesis core designed
for compact ASIC implementation using lookup-table (LUT) based waveform
generation techniques.

The project explores compact digital signal synthesis using quarter-wave LUT
optimization, waveform reconstruction, phase manipulation, and ASIC-oriented
digital design methods.

---

## Features

- 8-bit TinyTapeout-compatible interface
- LUT-based trigonometric waveform generation
- Sine waveform output
- Cosine waveform output
- Tangent waveform approximation
- Cotangent waveform approximation
- NCO (Numerically Controlled Oscillator) mode
- Triangle waveform generation
- Sawtooth waveform generation
- Square waveform generation
- Rectified sine generation
- Quarter-wave LUT optimization
- Phase-offset waveform synthesis
- Runtime waveform selection
- Runtime amplitude scaling
- Cocotb verification environment
- RTL and Gate-Level simulation support
---

## Architecture Overview

The waveform generation engine operates using:

1. Phase decoding
2. Quadrant extraction
3. LUT address mapping
4. Symmetry reconstruction
5. Signed waveform generation
6. Output remapping

Instead of storing a full waveform, only a quarter-wave lookup table is used,
significantly reducing memory usage while reconstructing the complete waveform
through symmetry operations.

Cosine generation is implemented using phase offset techniques.

---

## TinyTapeout Interface

| Signal | Description |
|---|---|
| `ui_in[7:0]` | Phase input / control input |
| `uo_out[7:0]` | Generated waveform output |
| `uio_in[7:0]` | Optional waveform configuration inputs |
| `uio_out[7:0]` | Debug / auxiliary outputs |
| `uio_oe[7:0]` | Bidirectional output enables |
| `clk` | System clock |
| `rst_n` | Active-low reset |
| `ena` | Design enable |

---

## Repository Structure

```text
src/                RTL source files
test/               Cocotb verification environment
docs/               TinyTapeout documentation
info.yaml           TinyTapeout project metadata
```

---

## Running RTL Simulation

```bash
cd test
make -B
```

---

## Running Gate-Level Simulation

After hardening:

```bash
cp ../runs/wokwi/results/final/verilog/gl/tt_um_polytrig_core.v gate_level_netlist.v
```

Then run:

```bash
make -B GATES=yes
```

---

## Viewing Waveforms

Using GTKWave:

```bash
gtkwave tb.fst tb.gtkw
```

Using Surfer:

```bash
surfer tb.fst
```

---

## Verification Environment

The project uses:

- cocotb
- Icarus Verilog
- GTKWave
- OpenLane / LibreLane
- TinyTapeout ASIC flow

for automated RTL and gate-level verification.

---

## Design Goals

This project explores:

- compact waveform synthesis
- ASIC-friendly digital signal generation
- LUT optimization methods
- compact waveform generation architectures
- open-source RTL-to-GDS flows

---

## Future Improvements

Potential future extensions include:

- DDS / NCO enhancements
- additional waveform modes
- configurable phase accumulation
- higher precision LUTs
- programmable amplitude scaling

---

## Documentation

Additional project information can be found in:

```text
docs/info.md
```

---

## TinyTapeout

Tiny Tapeout is an educational open-source ASIC project enabling low-cost
silicon fabrication for digital and analog designs.

More information:
https://tinytapeout.com