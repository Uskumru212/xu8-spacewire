open_hw_manager
connect_hw_server -url localhost:3121
set targets [get_hw_targets -quiet]
puts "TARGET_COUNT: [llength $targets]"
foreach target $targets {
    puts "AVAILABLE_TARGET: $target"
}
disconnect_hw_server
close_hw_manager
