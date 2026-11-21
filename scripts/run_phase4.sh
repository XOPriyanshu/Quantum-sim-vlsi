#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p checks
RTL=(rtl/controller.v rtl/qsim_top.v rtl/state_bank.v rtl/addr_gen.v rtl/control_mask.v \
     rtl/fx_arith.v rtl/gate_h.v rtl/gate_t.v rtl/gate_xz.v rtl/gate_cnot.v \
     rtl/gate_mcz.v rtl/gate_datapath.v)
for nq in 4 5 6; do
  echo "=== Phase 4 integration test: N_QUBITS=$nq ==="
  iverilog -g2012 -I rtl -s tb_qsim_top -Ptb_qsim_top.N_QUBITS=$nq \
    -o "checks/phase4_n${nq}" "${RTL[@]}" tb/tb_qsim_top.v
  vvp "checks/phase4_n${nq}"
done
