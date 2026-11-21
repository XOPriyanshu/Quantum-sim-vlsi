#!/usr/bin/env python3
"""Generate 4-qubit, 3-iteration Grover RTL program and fixed-point reference."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'python'))
from grover_ref import grover_program
from fixed_point import run_program

MARKED = 0b1010
PROGRAM = grover_program(n=4, marked=MARKED, iters=3)
OPS = {'H':0, 'X':1, 'Z':2, 'T':3, 'CNOT':4, 'MCZ':5}
def encode(inst):
    op, target, control, mask, value = inst
    return ((value & 63) << 15) | ((mask & 63) << 9) | ((control & 7) << 6) | ((target & 7) << 3) | OPS[op]

words = [encode(inst) for inst in PROGRAM]
assert len(words) <= 127
(ROOT/'tb/phase6_grover_instr.hex').write_text('\n'.join([f'{len(words):08x}']+[f'{w:08x}' for w in words]+['00000000']*(127-len(words)))+'\n',encoding='ascii')
re,im = run_program(4, PROGRAM)
for part, values in [('re',re),('im',im)]:
    (ROOT/f'tb/phase6_expected_{part}.hex').write_text(''.join(f'{int(v)&65535:04x}\n' for v in values),encoding='ascii')
print(f'Generated Grover program: {len(words)} instructions, marked state={MARKED} (1010), 3 iterations')
