# Run from any directory: vivado -mode batch -source scripts/create_project.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
set part xczu7ev-fbvb900-2-i
if {[llength [get_parts -quiet $part]] != 1} {
    error "Required device is not installed: $part"
}
set destination [file join $root build vivado]
if {[file exists [file join $destination xu8_spacewire.xpr]]} {
    error "Project already exists. Open build/vivado/xu8_spacewire.xpr or choose a new build directory."
}
create_project xu8_spacewire $destination -part $part
set_property target_language Verilog [current_project]
add_files [glob [file join $root rtl *.sv]]
add_files -fileset sim_1 [file join $root sim tb_spw_ds_tx.sv]
set_property top spw_ds_tx [get_filesets sources_1]
set_property top tb_spw_ds_tx [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "PROJECT_CREATED: $destination/xu8_spacewire.xpr"
puts "Development project only: top is a bit-layer unit, not a board-ready SpaceWire link."
puts "No board XDC or bitstream build is enabled while pin/bank checks are pending."
