# Candidate PS telemetry subsystem; execute inside create_board_project.tcl.
# OCM-only debug application: no DDR or boot-media peripheral configuration.
# Reference facts: Enclustra XU8 PE3 reference commit
# 10271e532b01b0304ce2f3a051721485dc38a47a (33.333333 MHz PS ref, UART0 MIO38..39).
create_bd_design telemetry_system
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 ps
set_property -dict [list \
    CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.333333} \
    CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
    CONFIG.PSU__DDRC__ENABLE {0} \
    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 38 .. 39} \
    CONFIG.PSU__UART0__BAUD_RATE {115200} \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
    CONFIG.PSU__MAXIGP0__DATA_WIDTH {32} \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {100}] [get_bd_cells ps]
# Custom carrier VCC_CFG_MIO is user-confirmed at 3.3 V (2026-10-15).
# Banks 501/503 therefore default to LVCMOS33; retain an explicit carrier override.
set mio_standard LVCMOS33
if {[info exists ::env(SPW_PS_MIO_STANDARD)]} {
    set mio_standard $::env(SPW_PS_MIO_STANDARD)
    if {$mio_standard ni {LVCMOS18 LVCMOS25 LVCMOS33}} {
        error "SPW_PS_MIO_STANDARD must be LVCMOS18, LVCMOS25 or LVCMOS33"
    }
}
set_property -dict [list CONFIG.PSU_BANK_1_IO_STANDARD $mio_standard \
    CONFIG.PSU_BANK_3_IO_STANDARD $mio_standard] [get_bd_cells ps]
create_bd_cell -type module -reference spw_telemetry_axi monitor
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 bridge
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1} CONFIG.NUM_CLKS {2}] [get_bd_cells bridge]
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_ps
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_spw
# Reset polarity is propagated from the connected ACTIVE_LOW PS reset pin.
set_property CONFIG.C_AUX_RESET_HIGH {1} [get_bd_cells reset_ps]
set_property CONFIG.C_AUX_RESET_HIGH {1} [get_bd_cells reset_spw]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 one
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 zero
set_property CONFIG.CONST_VAL {0} [get_bd_cells zero]
create_bd_port -dir I -type clk -freq_hz 400000000 spw_clk
set_property CONFIG.FREQ_HZ {400000000} [get_bd_ports spw_clk]
create_bd_port -dir I -type rst spw_resetn
set_property CONFIG.POLARITY {ACTIVE_LOW} [get_bd_ports spw_resetn]
set_property CONFIG.ASSOCIATED_RESET {spw_resetn} [get_bd_ports spw_clk]
foreach {name width} {status 16 control 16 counters 320} {
    create_bd_port -dir I -from [expr {$width-1}] -to 0 $name
    connect_bd_net [get_bd_ports $name] [get_bd_pins monitor/$name]
}
connect_bd_net [get_bd_pins ps/pl_clk0] [get_bd_pins ps/maxihpm0_fpd_aclk] \
    [get_bd_pins bridge/aclk] [get_bd_pins reset_ps/slowest_sync_clk]
connect_bd_net [get_bd_ports spw_clk] [get_bd_pins bridge/aclk1] \
    [get_bd_pins monitor/aclk] [get_bd_pins reset_spw/slowest_sync_clk]
connect_bd_net [get_bd_pins ps/pl_resetn0] [get_bd_pins reset_ps/ext_reset_in] [get_bd_pins reset_spw/ext_reset_in]
connect_bd_net [get_bd_ports spw_resetn] [get_bd_pins reset_spw/dcm_locked]
connect_bd_net [get_bd_pins one/dout] [get_bd_pins reset_ps/dcm_locked]
connect_bd_net [get_bd_pins zero/dout] [get_bd_pins reset_ps/aux_reset_in] \
    [get_bd_pins reset_ps/mb_debug_sys_rst] [get_bd_pins reset_spw/aux_reset_in] [get_bd_pins reset_spw/mb_debug_sys_rst]
connect_bd_net [get_bd_pins reset_ps/peripheral_aresetn] [get_bd_pins bridge/aresetn]
connect_bd_net [get_bd_pins reset_spw/peripheral_aresetn] [get_bd_pins monitor/aresetn]
connect_bd_intf_net [get_bd_intf_pins ps/M_AXI_HPM0_FPD] [get_bd_intf_pins bridge/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins bridge/M00_AXI] [get_bd_intf_pins monitor/S_AXI]
set telemetry_segments [get_bd_addr_segs -of_objects [get_bd_intf_pins monitor/S_AXI]]
if {[llength $telemetry_segments] != 1} {
    error "Expected one telemetry AXI register segment, found: $telemetry_segments"
}
assign_bd_address -offset 0xA0000000 -range 0x00001000 \
    -target_address_space [get_bd_addr_spaces ps/Data] $telemetry_segments -force
validate_bd_design
save_bd_design
generate_target all [get_files telemetry_system.bd]
add_files [make_wrapper -files [get_files telemetry_system.bd] -top]
