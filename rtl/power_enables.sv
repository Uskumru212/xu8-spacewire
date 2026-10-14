// User-confirmed active-high external rail enables.
// FPGA configuration and external pull resistors govern pre-configuration levels.
module power_enables (
    output wire rail_3v3_enable,
    output wire rail_5v_enable
);
    assign rail_3v3_enable = 1'b1;
    assign rail_5v_enable = 1'b1;
endmodule
