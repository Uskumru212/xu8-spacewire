# Validate generated interfaces and export a software-only XSA, then synthesize.
# This does not enable candidate board constraints or generate a bitstream.
set root [file normalize [file join [file dirname [info script]] ..]]
if {![info exists ::env(SPW_BUILD_DIR)]} {error "Set SPW_BUILD_DIR to the generated board project directory"}
open_project [file join $::env(SPW_BUILD_DIR) xu8_spacewire.xpr]
set reports [file join $::env(SPW_BUILD_DIR) integration]
file mkdir $reports
open_bd_design [get_files telemetry_system.bd]
validate_bd_design
foreach reset {reset_ps reset_spw} {
    if {[get_property CONFIG.C_EXT_RESET_HIGH [get_bd_cells $reset]] != 0} {
        error "PS external reset polarity did not propagate as active low: $reset"
    }
    if {[get_property CONFIG.C_AUX_RESET_HIGH [get_bd_cells $reset]] != 1} {
        error "Tied-low auxiliary reset must be active high: $reset"
    }
}
report_property [get_bd_cells ps] -file [file join $reports ps_properties.rpt]
report_property [get_bd_addr_segs ps/Data/SEG_monitor_reg0] -file [file join $reports telemetry_address.rpt]
write_hw_platform -fixed -force -file [file join $reports telemetry_software_only.xsa]
puts "SOFTWARE_XSA_EXPORTED: no bitstream; not a deployable platform"
report_ip_status -file [file join $reports ip_status.rpt]
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "Board synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
open_run synth_1
report_utilization -file [file join $reports utilization.rpt]
report_drc -file [file join $reports synthesis_drc.rpt]
report_cdc -details -file [file join $reports synthesis_cdc.rpt]
report_timing_summary -report_unconstrained -file [file join $reports synthesis_timing.rpt]
puts "BOARD_SYNTHESIS_PASS: candidate XDC disabled; not timing or electrical sign-off"
