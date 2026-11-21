#!/usr/bin/env python3
"""Generate Phase 6 Grover probability and lane-cycle figures from RTL results."""
from pathlib import Path
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / 'results'
FIGURES = RESULTS / 'figures'
FIGURES.mkdir(parents=True, exist_ok=True)

amplitude_file = RESULTS / 'phase6_rtl_l1_p1.csv'
with amplitude_file.open(newline='') as f:
    rows = list(csv.DictReader(f))
indices = [int(r['index']) for r in rows]
probabilities = [(int(r['real_q14']) / 16384.0)**2 + (int(r['imag_q14']) / 16384.0)**2 for r in rows]
if sorted(indices) != list(range(16)):
    raise ValueError('Expected exactly 16 distinct basis-state indices')
fig, ax = plt.subplots(figsize=(11, 5.5))
ax.bar(indices, probabilities, color=['#E28A26' if i == 10 else '#3678AC' for i in indices])
ax.set_xticks(range(16), [f'{i:04b}' for i in range(16)], rotation=45)
ax.set_xlabel('Computational basis state')
ax.set_ylabel('Measurement probability')
ax.set_title('Grover Search: Final RTL Probability Distribution (4 Qubits)')
ax.grid(axis='y', alpha=.2)
ax.set_axisbelow(True)
fig.tight_layout()
fig.savefig(FIGURES / 'grover_probability.png', dpi=300)
plt.close(fig)
print('Saved results/figures/grover_probability.png')

# Use measured cycle counts from the user's successful Phase 6 regression.
# These values correspond to the current verified run (58 instructions).
lanes = [1, 2, 4, 8]
cycles_1 = [1450, 754, 406, 232]
cycles_3 = [2378, 1218, 638, 348]
fig, ax = plt.subplots(figsize=(9, 5.5))
ax.plot(lanes, cycles_1, 'o-', label='1 pipeline stage')
ax.plot(lanes, cycles_3, 's-', label='3 pipeline stages')
ax.set_xticks(lanes)
ax.set_xlabel('Parallel lanes')
ax.set_ylabel('Execution cycles')
ax.set_title('Grover RTL: Cycle Count vs Parallel Lanes')
ax.grid(alpha=.25)
ax.legend()
fig.tight_layout()
fig.savefig(FIGURES / 'grover_cycles.png', dpi=300)
plt.close(fig)
print('Saved results/figures/grover_cycles.png')
