#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p checks
python3 scripts/gen_phase4_scoreboard.py
RTL=(rtl/controller.v rtl/qsim_top.v rtl/state_bank.v rtl/addr_gen.v rtl/control_mask.v \
     rtl/fx_arith.v rtl/gate_h.v rtl/gate_t.v rtl/gate_xz.v rtl/gate_cnot.v \
     rtl/gate_mcz.v rtl/gate_datapath.v)
for nq in 4 5 6; do
  echo "=== Python scoreboard: N_QUBITS=$nq ==="
  iverilog -g2012 -I rtl -s tb_phase4_scoreboard -Ptb_phase4_scoreboard.N_QUBITS="$nq" \
    -o "checks/phase4_scoreboard_n${nq}" "${RTL[@]}" tb/tb_phase4_scoreboard.v
  vvp "checks/phase4_scoreboard_n${nq}"
done
