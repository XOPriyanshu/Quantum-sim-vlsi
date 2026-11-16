# Simple Icarus Verilog flow. Edit TOP_TB to your main testbench.
RTL    := $(wildcard rtl/*.v)
TOP_TB := tb/tb_top.v
OUT    := results/sim.out

.PHONY: sim wave clean test-py vectors

sim:
	iverilog -g2012 -o $(OUT) $(RTL) $(TOP_TB)
	vvp $(OUT)

wave:
	gtkwave results/wave.vcd &

clean:
	rm -f results/sim.out results/*.vcd

test-py:
	python3 -I python/test_golden.py
	python3 -I python/test_fixed_point.py

vectors:
	python3 -I python/gen_vectors.py
