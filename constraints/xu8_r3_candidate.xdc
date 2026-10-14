# Candidate constraints: excluded from the default project until clock-bank
# electrical review is complete. Not a hardware sign-off.
# Package pin identities verified against AMD xczu7evfbvb900pkg.txt.
set_property -dict {PACKAGE_PIN AC8 IOSTANDARD LVDS} [get_ports spw_din_p]
set_property -dict {PACKAGE_PIN AC7 IOSTANDARD LVDS} [get_ports spw_din_n]
set_property -dict {PACKAGE_PIN AA2 IOSTANDARD LVDS} [get_ports spw_sin_p]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVDS} [get_ports spw_sin_n]
set_property -dict {PACKAGE_PIN AD1 IOSTANDARD LVDS} [get_ports spw_dout_p]
set_property -dict {PACKAGE_PIN AE1 IOSTANDARD LVDS} [get_ports spw_dout_n]
set_property -dict {PACKAGE_PIN AD2 IOSTANDARD LVDS} [get_ports spw_sout_p]
set_property -dict {PACKAGE_PIN AE2 IOSTANDARD LVDS} [get_ports spw_sout_n]
# R3026 and R3027 are DNP. Bank 66 is HP at user-confirmed 1.8 V.
set_property DIFF_TERM_ADV TERM_100 [get_ports {spw_din_p spw_sin_p}]
# Bank 48 is HD at user-confirmed 3.3 V on this custom carrier.
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33 DRIVE 4 SLEW SLOW} [get_ports rail_3v3_enable]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33 DRIVE 4 SLEW SLOW} [get_ports rail_5v_enable]
set_property PACKAGE_PIN AH6 [get_ports clk100_p]
set_property PACKAGE_PIN AJ6 [get_ports clk100_n]
# CLOCK IOSTANDARD INTENTIONALLY UNSET: resolve bank-65 supply, oscillator levels
# and termination from the exact R3 schematic. Never suppress NSTD-1 to build.
create_clock -name clk100 -period 10.000 [get_ports clk100_p]
# Asynchronous D/S capture exceptions and synchronizer placement must be checked
# after synthesis. Never false-path the entire receiver or suppress CDC reports.
