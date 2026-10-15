# Standalone SpaceWire bring-up on the user-confirmed custom carrier.
# Clock input follows Enclustra Mercury_XU8_PE3 reference commit
# 10271e532b01b0304ce2f3a051721485dc38a47a, lines 282-284.
set_property -dict {PACKAGE_PIN AC8 IOSTANDARD LVDS} [get_ports spw_din_p]
set_property -dict {PACKAGE_PIN AC7 IOSTANDARD LVDS} [get_ports spw_din_n]
set_property -dict {PACKAGE_PIN AA2 IOSTANDARD LVDS} [get_ports spw_sin_p]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVDS} [get_ports spw_sin_n]
set_property -dict {PACKAGE_PIN AD1 IOSTANDARD LVDS} [get_ports spw_dout_p]
set_property -dict {PACKAGE_PIN AE1 IOSTANDARD LVDS} [get_ports spw_dout_n]
set_property -dict {PACKAGE_PIN AD2 IOSTANDARD LVDS} [get_ports spw_sout_p]
set_property -dict {PACKAGE_PIN AE2 IOSTANDARD LVDS} [get_ports spw_sout_n]
# Bank 66 is user-confirmed at 1.8 V; external RX termination is DNP.
set_property DIFF_TERM_ADV TERM_100 [get_ports {spw_din_p spw_sin_p}]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33 DRIVE 4 SLEW SLOW} [get_ports rail_3v3_enable]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33 DRIVE 4 SLEW SLOW} [get_ports rail_5v_enable]
set_property PACKAGE_PIN AH6 [get_ports clk100_p]
set_property PACKAGE_PIN AJ6 [get_ports clk100_n]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {clk100_p clk100_n}]
# The module has external clock termination. DIFF_TERM_ADV applies only to
# supported LVDS standards and must not be assigned on DIFF_SSTL12_DCI.
# Clock Wizard supplies the 10 ns input and derived 2.5 ns clock constraints.
# Do not redefine its input clock under a different name.

# D/S are asynchronous to the local sampling clock. Exempt only the input
# path to each first synchronizer D pin, never the synchronizer/datapath stages.
set_false_path -from [get_ports spw_din_p] -to [get_pins -hier -filter {NAME =~ *s_spwdi1_reg/D}]
set_false_path -from [get_ports spw_sin_p] -to [get_pins -hier -filter {NAME =~ *s_spwsi1_reg/D}]
# Conservatively time startup logic at 200 MHz; CFGMCLK is a separate oscillator.
create_clock -name cfg_startup -period 5.000 [get_pins -hier -filter {NAME =~ *startup/CFGMCLK}]
# EOS is an asynchronous hard-macro status output, not a timing startpoint.
set_false_path -to [get_pins -hier -filter {NAME =~ *eos_meta_reg/D}]
