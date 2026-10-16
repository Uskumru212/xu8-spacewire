open_hw_manager
connect_hw_server -url localhost:3121
foreach target [get_hw_targets -quiet] {
    puts "BOARD_TARGET: $target"
    current_hw_target $target
    open_hw_target
    foreach device [get_hw_devices -quiet] {
        puts "BOARD_DEVICE: $device PART=[get_property PART $device]"
    }
    close_hw_target
}
disconnect_hw_server
close_hw_manager
