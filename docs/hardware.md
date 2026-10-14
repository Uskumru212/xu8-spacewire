# Hardware notes

## Schematic-transcribed signals

| Signal | FPGA package pin | Direction at FPGA |
| --- | --- | --- |
| Din_P | AC8 | Input |
| Din_N | AC7 | Input |
| Sin_P | AA2 | Input |
| Sin_N | AA1 | Input |
| Dout_P | AD1 | Output |
| Dout_N | AE1 | Output |
| Sout_P | AD2 | Output |
| Sout_N | AE2 | Output |
| +3V3_P_EN | G15 | Output |
| +5V_EN | K15 | Output |

Validate every pin against the ME-XU8-7EV-2I-D12E R3 pinout and the selected Vivado part before generating constraints. Connector pin numbers must not be confused with FPGA package pins.

## Power enables

The user confirms both enables are active high and their FPGA bank supply is 3.3 V. Intended behavior is to drive both outputs high after FPGA configuration. LVCMOS33 is the candidate standard, pending device-pin/bank validation. These outputs enable external power circuits; they do not generate the 3.3 V or 5 V rails.

Pre-configuration levels depend on board circuitry and FPGA configuration behavior. No power-good input or required rail sequencing has been established.

## SpaceWire electrical interface

Bank 66 supply is 1.8 V, per the user. The schematic shows an ADN4622BRNZ LVDS isolator with two channels in each direction. Signals remain differential on the FPGA side. Do not substitute an ADN4662 single-ended receiver model.

R3026 and R3027 on the FPGA receive pairs are DNP, explicitly confirmed by the user. Thus the schematic's drawn 100-ohm resistors are not populated. An appropriate internal differential termination is intended, but the supported standard, termination properties, common-mode range, and bank compatibility must be checked in AMD documentation and Vivado before use.

R3015 and R3016 are shown as 100-ohm resistors at the isolator inputs; their actual assembly status has not been independently confirmed. Trace polarity through the isolator and connector before hardware testing.

## Clock

The published XU8 manual describes an onboard 100 MHz LVDS oscillator connected to PL bank 65. Verify the exact R3 clock pins and oscillator implementation from the R3 module documentation/reference design. The planned clock source is this onboard oscillator, with MMCM/PLL-generated implementation clocks.

A 200 MHz transmit clock is a proposed way to emit one bit per rising edge. The asynchronous Data/Strobe receiver requires a separately justified capture architecture; 200 Mbit/s operation without DDR primitives is not yet proven.

## Programming

The user reports a Digilent "FTAG-HS3" programmer. The probable model is JTAG-HS3; confirm the label and Hardware Manager detection before documenting the cable as verified. Carrier JTAG header mapping, reference voltage, and target connection have not yet been inspected.
