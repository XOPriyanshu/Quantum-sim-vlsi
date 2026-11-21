#!/usr/bin/env python3
"""Compare captured RTL amplitudes with fixed-point and double precision Grover."""
from pathlib import Path
import csv, sys
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'python'))
from golden import run_program as double_run
from grover_ref import grover_program
from fixed_point import run_program as fixed_run, to_complex
from metrics import max_amp_error, fidelity, norm_drift

prog=grover_program(4,0b1010,3)
double=double_run(4,prog)
fixed=to_complex(fixed_run(4,prog))
marked=10
rows=[]
for lanes in (1,2,4,8):
  for stages in (1,3):
    path=ROOT/f'results/phase6_rtl_l{lanes}_p{stages}.csv'
    with path.open(newline='') as f:
      samples=list(csv.DictReader(f))
    if len(samples)!=16 or [int(s['index']) for s in samples]!=list(range(16)):
      raise RuntimeError(f'Invalid amplitude data in {path}')
    rtl=np.array([complex(int(s['real_q14']),int(s['imag_q14']))/16384 for s in samples])
    if not np.array_equal(rtl,fixed):
      raise RuntimeError(f'RTL does not match fixed-point reference: {path}')
    rows.append(dict(lanes=lanes,pipeline_stages=stages,marked_probability=f'{abs(rtl[marked])**2:.8f}',max_amplitude_error=f'{max_amp_error(double,rtl):.8f}',fidelity=f'{fidelity(double,rtl):.8f}',norm_drift=f'{norm_drift(rtl):.8f}'))
with (ROOT/'results/phase6_metrics.csv').open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print(f'Double-precision P(marked)={abs(double[marked])**2:.6f}')
print(f'Fixed-point P(marked)={abs(fixed[marked])**2:.6f}')
print(f'Max amplitude error={max_amp_error(double,fixed):.8f}, fidelity={fidelity(double,fixed):.8f}, norm drift={norm_drift(fixed):.8f}')
print('PASS: all 8 captured RTL states exactly match Python fixed-point reference')
print('Saved results/phase6_metrics.csv')
