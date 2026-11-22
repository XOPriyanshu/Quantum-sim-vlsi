set BASENAME "qsim_parallel_top"

set_attribute init_lib_search_path {/vlsi/pdk/course_pdk/tsmc_gp_65_stdio/tcbn65gplus_200a/TSMCHOME/digital/}
set_attribute init_hdl_search_path {Verilog}

set_attribute library {Front_End/timing_power_noise/CCS/tcbn65gplus_200a/tcbn65gplustc_ccs.lib}
set_attribute lef_library {Back_End/lef/tcbn65gplus_200a/lef/tcbn65gplus_9lmT2.lef}

set RTL_FILES [glob Verilog/*.v]

read_hdl -sv $RTL_FILES

elaborate qsim_parallel_top -parameters {5 4 3 16}

read_sdc constraints.sdc

syn_gen
syn_map
syn_opt

file mkdir Synthesis

report timing > Reports/n5_l4_p3/timing.rpt
report area > Reports/n5_l4_p3/area.rpt
report gates > Reports/n5_l4_p3/gates.rpt
report power > Reports/n5_l4_p3/power.rpt
report summary > Reports/n5_l4_p3/summary.rpt

write_hdl > Reports/n5_l4_p3/qsim_parallel_top_netlist.v
write_sdc > Reports/n5_l4_p3/qsim_parallel_top_constraints.sdc
exit
