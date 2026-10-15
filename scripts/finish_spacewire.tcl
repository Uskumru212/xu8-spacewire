# Export a routed SpaceWire design only when timing and DRC gates pass.
set build [file normalize $::env(SPW_BUILD_DIR)]
open_project [file join $build xu8_spacewire.xpr]
open_run impl_1
foreach kind {max min} {
    set paths [get_timing_paths -delay_type $kind -max_paths 1]
    if {[llength $paths] != 1} {error "Missing $kind timing paths"}
    set slack [get_property SLACK $paths]
    puts "FINAL_TIMING_$kind: $slack ns"
    if {$slack < 0} {error "Negative $kind timing slack; no bitstream exported"}
}
if {[llength [get_clocks -filter {PERIOD > 2.49 && PERIOD < 2.51}]] < 1} {
    error "Expected 400 MHz core clock is missing"
}
foreach reg_name {s_spwdi1_reg s_spwdi2_reg s_spwsi1_reg s_spwsi2_reg} {
    set reg [get_cells -hier -filter "NAME =~ *$reg_name"]
    if {[llength $reg] != 1 || ![get_property ASYNC_REG $reg]} {
        error "Missing preserved input synchronizer: $reg_name"
    }
}
if {[llength [get_cells -hier -filter {REF_NAME == DCIRESET}]] != 1} {
    error "Required DCI calibration primitive missing"
}
foreach {name pin} {clk100_p AH6 clk100_n AJ6 spw_din_p AC8 spw_din_n AC7
    spw_sin_p AA2 spw_sin_n AA1 spw_dout_p AD1 spw_dout_n AE1
    spw_sout_p AD2 spw_sout_n AE2 rail_3v3_enable G15 rail_5v_enable K15} {
    if {[get_property PACKAGE_PIN [get_ports $name]] ne $pin} {error "Wrong pin for $name"}
}
report_drc -file [file join $build reports final_drc.rpt]
set violations [get_drc_violations -quiet -filter {SEVERITY == Error || SEVERITY == {Critical Warning}}]
if {[llength $violations]} {error "Critical DRC violations: $violations"}
write_debug_probes -force [file join $build spacewire.ltx]
write_bitstream -force [file join $build spacewire.bit]
puts "SPACEWIRE_BITSTREAM_READY: [file join $build spacewire.bit]"
close_project
