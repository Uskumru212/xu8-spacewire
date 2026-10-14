# Candidate integration project. Requires a valid Vivado license.
# IP property names checked against installed 2026.1 component metadata;
# IP generation and device implementation have NOT been executed.
source [file join [file dirname [info script]] create_project.tcl]
add_files [list [file join $root rtl spw_telemetry_axi.vhd]]
# Vivado module references reject a VHDL-2008 top; this unit is VHDL-93 compatible.
set_property file_type VHDL [get_files spw_telemetry_axi.vhd]
source [file join $root scripts create_telemetry_bd.tcl]
add_files [list [file join $root rtl xu8_spacewire_top.vhd]]
set_property file_type {VHDL 2008} [get_files xu8_spacewire_top.vhd]
set_property top xu8_spacewire_top [get_filesets sources_1]
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name spw_clock
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {400.000} \
    CONFIG.USE_RESET {true} CONFIG.RESET_TYPE {ACTIVE_HIGH} CONFIG.USE_LOCKED {true}] [get_ips spw_clock]
create_ip -name vio -vendor xilinx.com -library ip -version 3.0 -module_name spw_vio
set_property -dict [list CONFIG.C_NUM_PROBE_IN {1} CONFIG.C_NUM_PROBE_OUT {1} \
    CONFIG.C_PROBE_IN0_WIDTH {16} CONFIG.C_PROBE_OUT0_WIDTH {16} \
    CONFIG.C_PROBE_OUT0_INIT_VAL {0x010C}] [get_ips spw_vio]
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name spw_ila
set_property -dict [list CONFIG.C_NUM_OF_PROBES {4} CONFIG.C_PROBE0_WIDTH {16} \
    CONFIG.C_PROBE1_WIDTH {320} CONFIG.C_PROBE2_WIDTH {20} \
    CONFIG.C_PROBE3_WIDTH {4} CONFIG.C_DATA_DEPTH {1024}] [get_ips spw_ila]
generate_target all [get_ips {spw_clock spw_vio spw_ila}]
add_files -fileset constrs_1 [list [file join $root constraints xu8_r3_candidate.xdc]]
set_property IS_ENABLED false [get_files xu8_r3_candidate.xdc]
update_compile_order -fileset sources_1
puts "BOARD_CANDIDATE_CREATED: candidate XDC disabled pending electrical/CDC review."
puts "No synthesis, implementation, bitstream generation or programming requested."
