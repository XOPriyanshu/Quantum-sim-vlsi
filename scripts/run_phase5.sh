#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p checks results
python3 scripts/gen_phase4_scoreboard.py
printf 'qubits,lanes,pipeline_stages,instructions,amplitudes,cycles\n' > results/phase5_cycles.csv
for n in 4 5 6; do
  for l in 1 2 4 8; do
    for p in 1 3; do
      iverilog -g2012 -I rtl -s tb_parallel -Ptb_parallel.N_QUBITS="$n" -Ptb_parallel.LANES="$l" -Ptb_parallel.PIPE_STAGES="$p" -o checks/phase5_test \
        rtl/addr_gen.v rtl/control_mask.v rtl/fx_arith.v rtl/gate_h.v rtl/gate_t.v rtl/gate_xz.v rtl/gate_cnot.v rtl/gate_mcz.v rtl/gate_datapath.v rtl/qsim_parallel_top.v tb/tb_parallel.v
      result=$(vvp checks/phase5_test)
      echo "$result" | grep '^PASS:'
      line=$(echo "$result" | grep '^PASS:')
      cycles=$(echo "$line" | sed -n 's/.*cycles=\([0-9][0-9]*\).*/\1/p')
      instructions=$(echo "$line" | sed -n 's/.*instructions=\([0-9][0-9]*\).*/\1/p')
      echo "$n,$l,$p,$instructions,$((1<<n)),$cycles" >> results/phase5_cycles.csv
    done
  done
done
printf 'PASS: all 24 Phase 5 configurations match Python reference.\n'
