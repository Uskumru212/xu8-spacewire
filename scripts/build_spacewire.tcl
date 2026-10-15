# Build only PL SpaceWire, VIO and ILA. No PS/UART application or hardware writes.
set ::env(SPW_ENABLE_UART_TELEMETRY) 0
set root [file normalize [file join [file dirname [info script]] ..]]
set project_file [file join $::env(SPW_BUILD_DIR) xu8_spacewire.xpr]
if {[file exists $project_file]} {
    open_project $project_file
    reset_run synth_1
} else {
    source [file join [file dirname [info script]] create_board_project.tcl]
    add_files -fileset constrs_1 [list [file join $root constraints xu8_spacewire_runtime.xdc]]
}
set_property generic {ENABLE_UART_TELEMETRY=false ENABLE_DCI_STARTUP=true} [get_filesets sources_1]
update_compile_order -fileset sources_1
set reports [file join $::env(SPW_BUILD_DIR) reports]
file mkdir $reports
launch_runs synth_1 -jobs 3
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {error "Synthesis failed"}
open_run synth_1
report_cdc -details -file [file join $reports synthesis_cdc.rpt]
report_timing_summary -report_unconstrained -file [file join $reports synthesis_timing.rpt]
report_drc -file [file join $reports synthesis_drc.rpt]
close_design
launch_runs impl_1 -to_step route_design -jobs 3
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "route_design Complete!"} {error "Implementation failed"}
open_run impl_1
report_timing_summary -report_unconstrained -file [file join $reports routed_timing.rpt]
report_drc -file [file join $reports routed_drc.rpt]
report_cdc -details -file [file join $reports routed_cdc.rpt]
report_utilization -file [file join $reports routed_utilization.rpt]
puts "SPACEWIRE_ROUTE_COMPLETE: inspect reports before generating/programming a bitstream"
close_project
