# Protocol-only project: no package constraints and no board bitstream.
set root [file normalize [file join [file dirname [info script]] ..]]
set part xczu7ev-fbvb900-2-i
if {[llength [get_parts -quiet $part]] != 1} { error "Required device not installed: $part" }
set destination [file join $root build vivado]
create_project xu8_spacewire $destination -part $part
set_property target_language VHDL [current_project]
foreach unit {spwpkg spwlink spwrecv spwxmit spwrecvfront_generic spwram spwstream} {
    add_files [file join $root vendor spacewire_light rtl ${unit}.vhd]
}
add_files [file join $root rtl spw_endpoint.vhd]
add_files [file join $root rtl spw_test_source.vhd]
add_files -fileset sim_1 [file join $root sim tb_endpoint.vhd]
set_property file_type {VHDL 2008} [get_files *.vhd]
set_property top spw_endpoint [get_filesets sources_1]
set_property top tb_endpoint [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "PROJECT_CREATED: $destination/xu8_spacewire.xpr"
puts "Protocol-only project. Board integration is in create_board_project.tcl."
