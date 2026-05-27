# PolyTrig Verification Environment

This directory contains the cocotb-based verification environment for the
PolyTrig TinyTapeout project.

The testbench verifies:

- Static sine/cosine generation
- Tangent/cotangent approximations
- NCO waveform generation
- Triangle waveform generation
- Sawtooth waveform generation
- Square waveform generation
- Rectified waveform generation
- Runtime amplitude scaling

---

## Simulation Flow

The verification environment supports:

- RTL simulation
- Gate-level simulation
- FST waveform dumping
- GTKWave visualization
- Cocotb automated verification

---

## Files

| File | Description |
|---|---|
| `test.py` | Cocotb verification test |
| `tb.v` | Verilog simulation wrapper |
| `Makefile` | Simulation configuration |
| `tb.gtkw` | GTKWave configuration |

---

## Running RTL Simulation

```sh
make -B
```

---

## Running Gate-Level Simulation

After hardening, copy the generated gate-level netlist:

```sh
cp ../runs/wokwi/results/final/verilog/gl/tt_um_polytrig_core.v gate_level_netlist.v
```

Then run:

```sh
make -B GATES=yes
```

---

## Waveform Visualization

Using GTKWave:

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer:

```sh
surfer tb.fst
```

---

## Notes

The verification flow uses:

- cocotb
- Icarus Verilog
- GTKWave
- TinyTapeout
- OpenLane / LibreLane