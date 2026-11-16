# Quantum Circuit State-Vector Simulator (RTL-to-Layout)

A pipelined, parameterizable, fixed-point **classical hardware engine** that simulates small quantum circuits (state-vector method) and is taken through synthesis (Cadence Genus) and physical design (Cadence Innovus).

This is **not** a quantum processor. It stores 2^n complex amplitudes and updates them with a pipelined datapath.

## Scope (approved)
- 4 / 5 / 6 qubits
- Gates: H, X, Z, T, CNOT, multi-controlled phase flip
- 1 / 2 / 4 / 8 lanes, configurable pipeline depth and data width
- Grover search demo (4 qubits), NumPy + fixed-point Python verification
- Clock goals: 200 MHz (5 ns), stretch 250 MHz (4 ns) - targets, not achievements
- Full physical design for **only two configs**: 6q 1-lane and 6q 4-lane. All other configs: synthesis only.

## Folder structure

| Folder | What goes here |
|---|---|
| `rtl/` | Synthesizable Verilog only: top, controller, address generator, state memory, lane, arithmetic |
| `tb/` | Testbenches and scoreboard (Icarus Verilog + GTKWave) |
| `python/` | NumPy golden model, fixed-point model, test-vector generator, error metrics |
| `scripts/` | Simulation, Genus synthesis TCL, Innovus TCL, helper scripts |
| `constraints/` | SDC files (5 ns and 4 ns clock) |
| `results/synthesis/` | Genus reports (area, timing, power) per configuration |
| `results/pnr/` | Innovus reports, DRC/antenna/connectivity, post-route timing |
| `results/figures/` | Plots and waveforms for the report and demo |
| `docs/` | Conventions, interface spec, block diagram, task tracker, report drafts |

## Quick start
```bash
git clone <repo-url>
cd quantum-sim-vlsi
make sim          # compile and run the testbench with Icarus Verilog
make wave         # open the last waveform in GTKWave
```

## Team workflow
See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: do not edit someone else's file without telling them, pull before you push, small commits.

## Task tracking
The full task list is in `docs/Quantum_Simulator_Task_Tracker.xlsx` (also shared as a Google Sheet).

## Conventions (must stay consistent across RTL and Python)
Fill these in `docs/conventions.md` before writing RTL:
- Little-endian qubit indexing: qubit q = bit q of state index k
- Fixed-point format, rounding and saturation rules
- Quantized value of 1/sqrt(2) (same constant in Python and RTL)
- Semantics of multi-controlled phase flip (are zero-controls supported?)
