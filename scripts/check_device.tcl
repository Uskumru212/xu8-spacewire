set root [file normalize [file join [file dirname [info script]] ..]]
set part xczu7ev-fbvb900-2-i
puts "TOOL_VERSION=[version -short]"
if {[llength [get_parts -quiet $part]] != 1} {
    error "Required FPGA part is not installed: $part"
}
create_project -in_memory -part $part
set_property design_mode PinPlanning [current_fileset]
open_io_design -name pin_probe
foreach pin {AC8 AC7 AA2 AA1 AD1 AE1 AD2 AE2 G15 K15 AH6 AJ6} {
    set obj [get_package_pins -quiet $pin]
    if {[llength $obj] != 1} {error "Missing or ambiguous pin: $pin"}
    puts "PIN_CHECK $pin"
    report_property $obj
}
puts "DEVICE_PROBE_PASS: inspect the pin/bank reports before writing board constraints"
