# Inspect a currently programmed SpaceWire design without reprogramming it.
set build [file normalize $::env(SPW_BUILD_DIR)]
open_hw_manager
connect_hw_server -url localhost:3121
set target [get_hw_targets -quiet *$::env(SPW_JTAG_SERIAL)]
if {[llength $target] != 1} {error "Expected one authorized target"}
current_hw_target $target
set_property PARAM.FREQUENCY 5000000 [current_hw_target]
open_hw_target
set device [get_hw_devices -quiet -filter {PART =~ xczu7*}]
if {[llength $device] != 1} {error "Expected one XCZU7"}
current_hw_device $device
set_property PROBES.FILE [file join $build spacewire.ltx] $device
refresh_hw_device $device
set ila [get_hw_ilas -of_objects $device]
if {[llength $ila] != 1} {error "Expected one SpaceWire ILA"}
set_property CONTROL.TRIGGER_POSITION 0 $ila
set_property CONTROL.DATA_DEPTH 1024 $ila
for {set n 0} {$n < 2} {incr n} {
    run_hw_ila -trigger_now $ila
    wait_on_hw_ila -timeout 10 $ila
    set data [upload_hw_ila_data $ila]
    set filename [file join $build reports physical_capture_${n}.csv]
    write_hw_ila_data -force -csv_file $filename $data
    puts "SPACEWIRE_CAPTURE: $filename"
    after 100
}
close_hw_target
disconnect_hw_server
close_hw_manager
