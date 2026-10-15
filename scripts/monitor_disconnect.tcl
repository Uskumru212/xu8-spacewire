# Arm the existing ILA on falling Run (status bit 2). No reprogramming/reset.
# Requires SPW_BUILD_DIR and SPW_JTAG_SERIAL. Does not explicitly stop on timeout;
# arming persistence after closing/reconnecting the debug session is unverified.
set build [file normalize $::env(SPW_BUILD_DIR)]
open_hw_manager
connect_hw_server -url localhost:3121
set target [get_hw_targets -quiet *$::env(SPW_JTAG_SERIAL)]
if {[llength $target] != 1} {error "Expected one authorized JTAG target"}
current_hw_target $target
set_property PARAM.FREQUENCY 5000000 $target
open_hw_target
set device [get_hw_devices -quiet -filter {PART =~ xczu7*}]
if {[llength $device] != 1} {error "Expected one XCZU7"}
current_hw_device $device
set_property PROBES.FILE [file join $build spacewire.ltx] $device
refresh_hw_device $device
set ila [get_hw_ilas -of_objects $device]
if {[llength $ila] != 1} {error "Expected one programmed SpaceWire ILA"}
reset_hw_ila -reset_compare_values true $ila
set status_probe [get_hw_probes -of_objects $ila -filter {NAME =~ *status*}]
if {[llength $status_probe] != 1} {error "Expected one ILA status probe"}
set_property CONTROL.DATA_DEPTH 1024 $ila
set_property CONTROL.TRIGGER_POSITION 512 $ila
set_property CONTROL.TRIGGER_CONDITION AND $ila
# Bits 15..3 and 1..0 ignored; F denotes a falling edge on bit 2.
set_property TRIGGER_COMPARE_VALUE {eq16'bXXXXXXXXXXXXXFXX} $status_probe
puts "DISCONNECT_TRIGGER: [get_property TRIGGER_COMPARE_VALUE $status_probe]"
run_hw_ila $ila
set start_ms [clock milliseconds]
set captured 0
while {[expr {[clock milliseconds] - $start_ms}] < 120000} {
    # Vivado timeout is in minutes; a bounded wait also updates ILA status.
    catch {wait_on_hw_ila -timeout 0.25 $ila} wait_message
    set state [get_property STATUS.CORE_STATUS $ila]
    puts "DISCONNECT_MONITOR: elapsed_ms=[expr {[clock milliseconds] - $start_ms}] ila=$state"
    if {[string match -nocase *full* $state]} {
        set data [upload_hw_ila_data $ila]
        write_hw_ila_data -force -csv_file [file join $build reports run_falling_edge.csv] $data
        set captured 1
        break
    }
}
puts "DISCONNECT_RESULT: captured=$captured state=[get_property STATUS.CORE_STATUS $ila]"
close_hw_target
disconnect_hw_server
close_hw_manager
