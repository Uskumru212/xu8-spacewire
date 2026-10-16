# Requires the bitstream built with SPW_TEST_10KBIT=1 and finish_spacewire.tcl.
# One 1250-byte payload (10,000 payload bits), followed by one EOP.
set build [file normalize $::env(SPW_BUILD_DIR)]
set reportdir [file normalize $::env(SPW_TEST_REPORT_DIR)]
file mkdir $reportdir
foreach file {spacewire.bit spacewire.ltx} {
    if {![file exists [file join $build $file]]} {error "Missing $file"}
}
# Verify the build configuration before enabling the packet source.
open_project [file join $build xu8_spacewire.xpr]
set generics [get_property generic [get_filesets sources_1]]
if {![regexp {TEST_PACKET_BYTES=1250} $generics] ||
    ![regexp {TEST_ONE_SHOT=true} $generics]} {error "Not the finite 10Kbit build"}
close_project
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
set_property PROGRAM.FILE [file join $build spacewire.bit] $device
set_property PROBES.FILE [file join $build spacewire.ltx] $device
program_hw_devices $device
refresh_hw_device $device
set vio [get_hw_vios -of_objects $device]
set ila [get_hw_ilas -of_objects $device]
if {[llength $vio] != 1 || [llength $ila] != 1} {error "Missing debug core"}
set control [get_hw_probes -of_objects $vio -filter {NAME =~ *control*}]
set status [get_hw_probes -of_objects $vio -filter {NAME =~ *status*}]
set status_probe [get_hw_probes -of_objects $ila -filter {NAME =~ *status*}]
if {[llength $control] != 1 || [llength $status] != 1 || [llength $status_probe] != 1} {
    error "Unexpected debug interface"
}
set_property OUTPUT_VALUE 010C $control
commit_hw_vio $vio
set_property OUTPUT_VALUE 010F $control
commit_hw_vio $vio
after 100
set_property OUTPUT_VALUE 010C $control
commit_hw_vio $vio
refresh_hw_vio $vio
if {![string equal -nocase [get_property OUTPUT_VALUE $control] 010C]} {error "200 Mbit/s control readback mismatch"}
puts "TEST_RATE: local_tx_nominal_mbps=200 divider=1 control=[get_property OUTPUT_VALUE $control] reset_applied=1"
set run_seen 0
for {set n 0} {$n < 100} {incr n} {
    after 100
    refresh_hw_vio $vio
    scan [get_property INPUT_VALUE $status] %x value
    if {$value & 4} {set run_seen 1; break}
}
if {!$run_seen} {error "No Run state; test payload not enabled"}
proc snapshot {ila filename} {
    reset_hw_ila -reset_compare_values true $ila
    set_property CONTROL.DATA_DEPTH 1024 $ila
    set_property CONTROL.TRIGGER_POSITION 0 $ila
    run_hw_ila -trigger_now $ila
    wait_on_hw_ila -timeout 0.25 $ila
    set data [upload_hw_ila_data $ila]
    write_hw_ila_data -force -csv_file $filename $data
}
proc arm_falling_run {ila status_probe} {
    reset_hw_ila -reset_compare_values true $ila
    set_property CONTROL.DATA_DEPTH 1024 $ila
    set_property CONTROL.TRIGGER_POSITION 512 $ila
    set_property CONTROL.TRIGGER_CONDITION AND $ila
    # Binary radix ('b): 13 X bits, falling running (bit 2), then two X bits.
    # F is the edge symbol for one bit; it is not hexadecimal 0xF.
    set_property TRIGGER_COMPARE_VALUE {eq16'bXXXXXXXXXXXXXFXX} $status_probe
    run_hw_ila $ila
    puts "TEST_10KBIT_TRIGGER: [get_property TRIGGER_COMPARE_VALUE $status_probe]"
}
snapshot $ila [file join $reportdir payload_start.csv]
arm_falling_run $ila $status_probe
set captured 0
set start_ms [clock milliseconds]
try {
    set_property OUTPUT_VALUE 011C $control
    commit_hw_vio $vio
    puts "TEST_10KBIT: one-shot enabled; expected 1250 data bytes plus EOP"
    while {[expr {[clock milliseconds] - $start_ms}] < 120000} {
        catch {wait_on_hw_ila -timeout 0.25 $ila} wait_message
        set state [get_property STATUS.CORE_STATUS $ila]
        refresh_hw_vio $vio
        puts "TEST_10KBIT_MONITOR: elapsed_ms=[expr {[clock milliseconds] - $start_ms}] ila=$state status=[get_property INPUT_VALUE $status]"
        if {[string match -nocase *full* $state]} {
            set data [upload_hw_ila_data $ila]
            write_hw_ila_data -force -csv_file [file join $reportdir payload_disconnect.csv] $data
            set captured 1
            break
        }
    }
} finally {
    set_property OUTPUT_VALUE 010C $control
    commit_hw_vio $vio
}
set duration [expr {[clock milliseconds] - $start_ms}]
# The immediate snapshot replaces the pending trigger after the test interval.
snapshot $ila [file join $reportdir payload_end.csv]
arm_falling_run $ila $status_probe
puts "TEST_10KBIT_RESULT: duration_ms=$duration disconnect_capture=$captured payload_disabled=1"
close_hw_target
disconnect_hw_server
close_hw_manager

