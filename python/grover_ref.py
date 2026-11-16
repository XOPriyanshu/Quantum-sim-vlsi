"""Grover search program + double-precision reference (tracker task 1.3).

The same instruction list is reused by the fixed-point model, the RTL testbench and
the test-vector generator, so everything runs one program.
"""
import numpy as np
from golden import run_program


def grover_program(n=4, marked=0b1010, iters=3):
    full = (1 << n) - 1
    prog = [("H", q, 0, 0, 0) for q in range(n)]
    for _ in range(iters):
        prog.append(("MCZ", 0, 0, full, marked))          # oracle: flip |marked>
        prog += [("H", q, 0, 0, 0) for q in range(n)]      # diffusion
        prog += [("X", q, 0, 0, 0) for q in range(n)]
        prog.append(("MCZ", 0, 0, full, full))             # phase flip |1...1>
        prog += [("X", q, 0, 0, 0) for q in range(n)]
        prog += [("H", q, 0, 0, 0) for q in range(n)]
    return prog


def marked_probability(psi, marked):
    return float(abs(psi[marked]) ** 2)


if __name__ == "__main__":
    for it in range(1, 5):
        psi = run_program(4, grover_program(4, 0b1010, it))
        print(f"iterations={it}  P(marked)={marked_probability(psi, 0b1010):.4f}")
