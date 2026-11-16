"""Test-vector generator for the RTL testbenches (tracker task 1.6).

Writes to tb/vectors/:
  <name>_n<N>.prog  one instruction per line, 32-bit hex word (format: docs/conventions.md)
  <name>_n<N>.exp   expected final state from the fixed-point model, one line per
                    amplitude: "<re 4 hex digits> <im 4 hex digits>" (two's complement)
Initial state is |0...0>. Run: python3 -I python/gen_vectors.py
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fixed_point as fx
from grover_ref import grover_program

OPCODE = {"H": 0, "X": 1, "Z": 2, "T": 3, "CNOT": 4, "MCZ": 5}
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tb", "vectors")


def encode(ins):
    op, tgt, ctl, mask, val = ins
    return OPCODE[op] | (tgt << 3) | (ctl << 6) | (mask << 9) | (val << 15)


def write_case(name, n, program):
    os.makedirs(OUT, exist_ok=True)
    re, im = fx.run_program(n, program)
    with open(os.path.join(OUT, f"{name}_n{n}.prog"), "w") as f:
        f.writelines(f"{encode(i):08x}\n" for i in program)
    with open(os.path.join(OUT, f"{name}_n{n}.exp"), "w") as f:
        f.writelines(f"{int(r) & 0xFFFF:04x} {int(i) & 0xFFFF:04x}\n" for r, i in zip(re, im))


def prep(n):
    """Spread amplitude over all basis states with a phase twist so every gate sees real data."""
    return [("H", q, 0, 0, 0) for q in range(n)] + [("T", 0, 0, 0, 0), ("T", n - 1, 0, 0, 0)]


def main():
    cases = 0
    for n in (4, 5, 6):
        for q in range(n):
            for g in ("H", "X", "Z", "T"):
                write_case(f"{g.lower()}_t{q}", n, prep(n) + [(g, q, 0, 0, 0)]); cases += 1
        for c in range(n):
            for t in range(n):
                if c != t:
                    write_case(f"cnot_c{c}_t{t}", n, prep(n) + [("CNOT", t, c, 0, 0)]); cases += 1
        full = (1 << n) - 1
        for name, mask, val in (("mcz_all1", full, full), ("mcz_zero_ctl", 0b11, 0b01), ("mcz_single", full, 0)):
            write_case(name, n, prep(n) + [("MCZ", 0, 0, mask, val)]); cases += 1
    write_case("grover_it3", 4, grover_program(4, 0b1010, 3)); cases += 1
    print(f"wrote {cases} cases to {os.path.normpath(OUT)}")


if __name__ == "__main__":
    main()
