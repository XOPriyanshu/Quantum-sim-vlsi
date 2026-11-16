#!/usr/bin/env bash
# Tracker task 0.6: verify the open-source tool setup and run a hello-world simulation.
set -u
ok=1
for t in iverilog vvp gtkwave python3; do
  if command -v "$t" >/dev/null 2>&1; then echo "[ok]   $t -> $(command -v $t)"; else echo "[MISS] $t"; ok=0; fi
done
python3 -c "import numpy; print('[ok]   numpy', numpy.__version__)" 2>/dev/null || { echo "[MISS] numpy"; ok=0; }

if command -v iverilog >/dev/null 2>&1; then
  tmp=$(mktemp -d)
  cat > "$tmp/hello.v" <<'V'
module hello; initial begin $display("hello from Icarus Verilog"); $finish; end endmodule
V
  iverilog -g2012 -o "$tmp/hello.out" "$tmp/hello.v" && vvp "$tmp/hello.out"
  rm -rf "$tmp"
fi
[ "$ok" = 1 ] && echo "Tool check PASSED" || { echo "Tool check FAILED"; exit 1; }
