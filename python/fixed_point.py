"""Bit-exact fixed-point model of the RTL arithmetic (tracker task 1.4).

Format Q2.14 in 16-bit signed (real, imag). Rounding: round-half-up. Saturation: clamp.
All values are python/numpy int64 so intermediates are never wrapped.
See docs/conventions.md - keep in sync.
"""
import numpy as np
from golden import pair_indices

WIDTH = 16
FRAC = 14
ONE = 1 << FRAC                     # 0x4000
SQRT_HALF_Q = 11585                 # 0x2D41 = round(2^14 / sqrt2)
MAXV = (1 << (WIDTH - 1)) - 1
MINV = -(1 << (WIDTH - 1))


def sat(x):
    return np.clip(x, MINV, MAXV)


def round_shift(x, s=FRAC):
    """Round-half-up arithmetic right shift."""
    return (x + (1 << (s - 1))) >> s


def mul_sqrt_half(x):
    """x (wide int) * quantized 1/sqrt2, rounded, saturated to 16 bits."""
    return sat(round_shift(x * SQRT_HALF_Q))


def init_state(n):
    re = np.zeros(1 << n, dtype=np.int64)
    im = np.zeros(1 << n, dtype=np.int64)
    re[0] = ONE
    return re, im


def to_complex(state):
    re, im = state
    return (re + 1j * im) / ONE


def from_complex(c):
    c = np.asarray(c)
    return (sat(np.rint(c.real * ONE).astype(np.int64)),
            sat(np.rint(c.imag * ONE).astype(np.int64)))


def apply_h(s, n, q):
    re, im = s
    i, j = pair_indices(n, q)
    ar, ai, br, bi = re[i].copy(), im[i].copy(), re[j].copy(), im[j].copy()
    re[i], im[i] = mul_sqrt_half(ar + br), mul_sqrt_half(ai + bi)
    re[j], im[j] = mul_sqrt_half(ar - br), mul_sqrt_half(ai - bi)


def apply_t(s, n, q):
    re, im = s
    _, j = pair_indices(n, q)
    br, bi = re[j].copy(), im[j].copy()
    re[j] = mul_sqrt_half(br - bi)          # (x - y)/sqrt2
    im[j] = mul_sqrt_half(br + bi)          # (x + y)/sqrt2


def apply_x(s, n, q):
    re, im = s
    i, j = pair_indices(n, q)
    re[i], re[j] = re[j].copy(), re[i].copy()
    im[i], im[j] = im[j].copy(), im[i].copy()


def apply_z(s, n, q):
    re, im = s
    _, j = pair_indices(n, q)
    re[j], im[j] = sat(-re[j]), sat(-im[j])


def apply_cnot(s, n, c, t):
    if c == t:
        raise ValueError("CNOT control must differ from target")
    re, im = s
    k = np.arange(1 << n)
    sel = k[(((k >> c) & 1) == 1) & (((k >> t) & 1) == 0)]
    oth = sel ^ (1 << t)
    re[sel], re[oth] = re[oth].copy(), re[sel].copy()
    im[sel], im[oth] = im[oth].copy(), im[sel].copy()


def apply_mcz(s, n, mask, value):
    if value & ~mask:
        raise ValueError("value has bits outside mask")
    re, im = s
    k = np.arange(1 << n)
    m = (k & mask) == value
    re[m], im[m] = sat(-re[m]), sat(-im[m])


def apply_instr(s, n, instr):
    op, tgt, ctl, mask, val = instr
    if op == "H":
        apply_h(s, n, tgt)
    elif op == "X":
        apply_x(s, n, tgt)
    elif op == "Z":
        apply_z(s, n, tgt)
    elif op == "T":
        apply_t(s, n, tgt)
    elif op == "CNOT":
        apply_cnot(s, n, ctl, tgt)
    elif op == "MCZ":
        apply_mcz(s, n, mask, val)
    else:
        raise ValueError(f"bad opcode {op}")


def run_program(n, program, state=None):
    s = init_state(n) if state is None else (state[0].copy(), state[1].copy())
    for ins in program:
        apply_instr(s, n, ins)
    return s
