# Simple Icarus Verilog flow. Edit TOP_TB to your main testbench.
RTL    := $(wildcard rtl/*.v)
TOP_TB := tb/tb_top.v
OUT    := results/sim.out

.PHONY: sim wave clean

sim:
	iverilog -g2012 -o $(OUT) $(RTL) $(TOP_TB)
	vvp $(OUT)

wave:
	gtkwave results/wave.vcd &

clean:
	rm -f results/sim.out results/*.vcd
