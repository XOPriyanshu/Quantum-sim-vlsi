#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p checks results
python3 scripts/gen_phase6_grover.py
printf 'lanes,pipeline_stages,instructions,cycles\n' > results/phase6_cycles.csv
for l in 1 2 4 8; do
  for p in 1 3; do
    iverilog -g2012 -I rtl -s tb_grover -Ptb_grover.LANES="$l" -Ptb_grover.PIPE_STAGES="$p" -o checks/phase6_test \
      rtl/addr_gen.v rtl/control_mask.v rtl/fx_arith.v rtl/gate_h.v rtl/gate_t.v rtl/gate_xz.v rtl/gate_cnot.v rtl/gate_mcz.v rtl/gate_datapath.v rtl/qsim_parallel_top.v tb/tb_grover.v
    result=$(vvp checks/phase6_test)
    echo "$result" | grep '^PASS:'
    line=$(echo "$result" | grep '^PASS:')
    cycles=$(echo "$line" | sed -n 's/.*cycles=\([0-9][0-9]*\).*/\1/p')
    instructions=$(echo "$line" | sed -n 's/.*instructions=\([0-9][0-9]*\).*/\1/p')
    echo "$l,$p,$instructions,$cycles" >> results/phase6_cycles.csv
  done
done
python3 scripts/analyze_phase6.py
