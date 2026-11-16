"""Double-precision NumPy golden model (tracker task 1.1).

Conventions: docs/conventions.md. Little-endian: qubit q is bit q of the state index.
Instruction tuple: (op, target, control, mask, value). Unused fields are 0.
"""
import numpy as np

SQRT_HALF = 1.0 / np.sqrt(2.0)
OPS = ("H", "X", "Z", "T", "CNOT", "MCZ")


def init_state(n):
    psi = np.zeros(1 << n, dtype=np.complex128)
    psi[0] = 1.0
    return psi


def pair_indices(n, q):
    """Return (i, j) index arrays: bit q of i = 0, j = i ^ (1 << q). 2^(n-1) pairs."""
    k = np.arange(1 << n)
    i = k[((k >> q) & 1) == 0]
    return i, i ^ (1 << q)


def apply_h(psi, n, q):
    i, j = pair_indices(n, q)
    a, b = psi[i].copy(), psi[j].copy()
    psi[i], psi[j] = (a + b) * SQRT_HALF, (a - b) * SQRT_HALF
    return psi


def apply_x(psi, n, q):
    i, j = pair_indices(n, q)
    psi[i], psi[j] = psi[j].copy(), psi[i].copy()
    return psi


def apply_z(psi, n, q):
    i, j = pair_indices(n, q)
    psi[j] = -psi[j]
    return psi


def apply_t(psi, n, q):
    """Project 'T': multiply amplitudes with target bit = 1 by (1+j)/sqrt2."""
    i, j = pair_indices(n, q)
    psi[j] = psi[j] * (1 + 1j) * SQRT_HALF
    return psi


def apply_cnot(psi, n, c, t):
    if c == t:
        raise ValueError("CNOT control must differ from target")
    k = np.arange(1 << n)
    sel = k[(((k >> c) & 1) == 1) & (((k >> t) & 1) == 0)]
    other = sel ^ (1 << t)
    psi[sel], psi[other] = psi[other].copy(), psi[sel].copy()
    return psi


def apply_mcz(psi, n, mask, value):
    """Negate amplitudes where (index & mask) == value. Zero-controls supported."""
    if value & ~mask:
        raise ValueError("value has bits outside mask")
    k = np.arange(1 << n)
    psi[(k & mask) == value] *= -1
    return psi


def apply_instr(psi, n, instr):
    op, tgt, ctl, mask, val = instr
    if op == "H":
        return apply_h(psi, n, tgt)
    if op == "X":
        return apply_x(psi, n, tgt)
    if op == "Z":
        return apply_z(psi, n, tgt)
    if op == "T":
        return apply_t(psi, n, tgt)
    if op == "CNOT":
        return apply_cnot(psi, n, ctl, tgt)
    if op == "MCZ":
        return apply_mcz(psi, n, mask, val)
    raise ValueError(f"bad opcode {op}")


def run_program(n, program, psi=None):
    psi = init_state(n) if psi is None else psi.copy()
    for ins in program:
        apply_instr(psi, n, ins)
    return psi
