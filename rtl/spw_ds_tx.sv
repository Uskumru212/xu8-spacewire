`timescale 1ns/1ps
// Single-edge Data/Strobe encoder. This is a bit-layer building block,
// not a complete SpaceWire transmitter: the caller must supply framed bits.
module spw_ds_tx #(
    parameter integer DIV_WIDTH = 8
) (
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire [DIV_WIDTH-1:0] cycles_per_bit,
    input  wire bit_valid,
    input  wire bit_data,
    output wire bit_ready,
    output reg  data_out = 1'b0,
    output reg  strobe_out = 1'b0,
    output reg  bit_sent = 1'b0
);
    reg [DIV_WIDTH-1:0] remaining = 0;
    // Zero is clamped to one cycle. Changes take effect at accepted-bit
    // boundaries; the spacing already scheduled for a bit is never shortened.
    wire [DIV_WIDTH-1:0] period_cycles =
        (cycles_per_bit == 0) ? {{(DIV_WIDTH-1){1'b0}},1'b1} : cycles_per_bit;
    assign bit_ready = enable && !reset && (remaining == 0);

    always @(posedge clk) begin
        bit_sent <= 1'b0;
        if (reset || !enable) begin
            data_out <= 1'b0;
            strobe_out <= 1'b0;
            remaining <= 0;
        end else if (remaining != 0) begin
            remaining <= remaining - 1'b1;
        end else if (bit_valid) begin
            // Exactly one wire changes for every accepted bit.
            if (bit_data == data_out)
                strobe_out <= ~strobe_out;
            data_out <= bit_data;
            bit_sent <= 1'b1;
            remaining <= period_cycles - 1'b1;
        end
    end
endmodule
