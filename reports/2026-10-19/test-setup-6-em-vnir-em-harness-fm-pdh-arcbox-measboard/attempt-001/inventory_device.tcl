open_hw_manager
connect_hw_server -url localhost:3121
set target [get_hw_targets -quiet *210299BFE5B4]
if {[llength $target] != 1} {error "Expected current Setup 6 target"}
current_hw_target $target
open_hw_target
foreach device [get_hw_devices -quiet] {
    puts "BOARD_DEVICE: $device PART=[get_property PART $device]"
}
close_hw_target
disconnect_hw_server
close_hw_manager
