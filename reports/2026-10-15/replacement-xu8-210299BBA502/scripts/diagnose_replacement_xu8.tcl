# Volatile JTAG programming for the detected XU8. Does not write boot media.
set build [file normalize $::env(SPW_BUILD_DIR)]
set bit [file join $build spacewire.bit]
set probes [file join $build spacewire.ltx]
if {![file exists $bit] || ![file exists $probes]} {error "Run finish_spacewire.tcl first"}
if {![info exists ::env(SPW_JTAG_SERIAL)]} {error "Set SPW_JTAG_SERIAL to the detected cable serial"}
open_hw_manager
connect_hw_server -url localhost:3121
set targets [get_hw_targets -quiet *$::env(SPW_JTAG_SERIAL)]
if {[llength $targets] != 1} {error "Expected exactly one authorized JTAG target: $targets"}
current_hw_target $targets
set_property PARAM.FREQUENCY 5000000 [current_hw_target]
open_hw_target
set device [get_hw_devices -quiet -filter {PART =~ xczu7*}]
if {[llength $device] != 1} {error "Expected one XCZU7 target: $device"}
current_hw_device $device
set_property PROGRAM.FILE $bit $device
set_property PROBES.FILE $probes $device
if {![info exists ::env(SPW_REUSE_PROGRAMMED)] || !$::env(SPW_REUSE_PROGRAMMED)} {
    program_hw_devices $device
}
refresh_hw_device $device
set vio [get_hw_vios -of_objects $device]
if {[llength $vio] != 1} {error "Expected exactly one SpaceWire VIO: $vio"}
# Use the net names verified in this design's LTX; hw_probe has no DIRECTION
# property even though the LTX pin metadata records input/output direction.
set control [get_hw_probes -of_objects $vio -filter {NAME =~ *control*}]
set status [get_hw_probes -of_objects $vio -filter {NAME =~ *status*}]
if {[llength $control] != 1 || [llength $status] != 1} {error "Unexpected VIO interface"}
# Enable link start/autostart at the 200 Mbit/s Run divider; test payload off.
set_property OUTPUT_VALUE 010C $control
commit_hw_vio $vio
for {set n 0} {$n < 30} {incr n} {
    after 1000
    refresh_hw_vio $vio
    puts "SPACEWIRE_STATUS: [get_property INPUT_VALUE $status] CONTROL: [get_property OUTPUT_VALUE $control]"
}
set ila [get_hw_ilas -of_objects $device]
if {[llength $ila] != 1} {error "Expected one ILA"}
reset_hw_ila -reset_compare_values true $ila
set_property CONTROL.DATA_DEPTH 1024 $ila
set_property CONTROL.TRIGGER_POSITION 0 $ila
for {set n 0} {$n < 4} {incr n} {
    run_hw_ila -trigger_now $ila
    wait_on_hw_ila -timeout 0.25 $ila
    set data [upload_hw_ila_data $ila]
    write_hw_ila_data -force -csv_file [file join $build reports replacement_210299BBA502 link_diagnostic_${n}.csv] $data
    after 100
}
close_hw_target
disconnect_hw_server
close_hw_manager

