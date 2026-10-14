# Hardware notes

## Target and package pins

User-supplied module: ME-XU8-7EV-2I-D12E, revision R3. Enclustra identifies the device as XCZU7EV-2FBVB900I. Vivado part: `xczu7ev-fbvb900-2-i`.

| Signal | P pin | N pin | AMD bank/type |
| --- | --- | --- | --- |
| SpaceWire Data input | AC8 | AC7 | 66 / HP |
| SpaceWire Strobe input | AA2 | AA1 | 66 / HP |
| SpaceWire Data output | AD1 | AE1 | 66 / HP |
| SpaceWire Strobe output | AD2 | AE2 | 66 / HP |
| Onboard 100 MHz clock | AH6 | AJ6 | 65 / HP |

| Rail enable | Package pin | AMD bank/type | Intended level |
| --- | --- | --- | --- |
| +3V3_P_EN | G15 | 48 / HD | High |
| +5V_EN | K15 | 48 / HD | High |

SpaceWire and enable pins were transcribed from the user's schematics. Clock pins come from Enclustra's reference. All listed pin identities, pairs and bank types were checked against AMD's official `xczu7evfbvb900pkg.txt`. This validates package identities, not board assembly or Vivado DRC. Connector pin numbers are not FPGA package pins.

[AMD package source](https://www.amd.com/en/developer/resources/adaptive-socs-and-fpgas/package-pinout-files/zynq-ultrascale-plus-package-device-pinout-files.html), archive `zupall.zip`. Checked pin-table SHA-256: `EA168ED77CB4F433EC0D8D49598D56EA74F4A7EDCC619BF4189BA940586C2915`.

## Power outputs

The user confirms both enables are active high and the enable bank supply is 3.3 V. The board top drives both high after FPGA configuration; candidate constraints use LVCMOS33. These pins enable external circuits; they do not generate supply voltages. Pre-configuration levels depend on the carrier. No sequencing or power-good signal has been specified.

## SpaceWire interface

Bank 66 is at 1.8 V, as confirmed by the user. The schematic shows **ADN4622BRNZ**, a bidirectional LVDS isolation arrangement with two channels each way. It is not an ADN4662 and does not turn the FPGA interface into single-ended signals.

R3026/R3027 are DNP. Candidate XDC therefore requests `DIFF_TERM_ADV TERM_100` on the FPGA receive pairs with `IOSTANDARD LVDS`. This is the intended HP-bank 1.8 V configuration, subject to actual device DRC and electrical review. R3015/R3016 are drawn as 100-ohm isolator input termination; their populated state is not independently confirmed. Verify pair polarity, connectors, isolator supplies and assembly before powering the external interface.

[AMD DIFF_TERM_ADV](https://docs.amd.com/r/en-US/2026.1/ug912-vivado-properties/DIFF_TERM_ADV) and [UltraScale SelectIO guide](https://www.amd.com/content/dam/xilinx/support/documents/user_guides/ug571-ultrascale-selectio.pdf).

## Clock and remaining constraints

The XU8 onboard oscillator provides 100 MHz to PL bank 65. The [official Enclustra PE3 reference](https://github.com/enclustra/Mercury_XU8_PE3_Reference_Design/blob/10271e532b01b0304ce2f3a051721485dc38a47a/src/Mercury_XU8_PE3.tcl) assigns AH6/AJ6 and uses DIFF_SSTL12_DCI for this memory-related clock interface. The manual describes LVDS with external termination. Resolve the exact R3 bank-65 supply and oscillator input requirements before choosing the clock IOSTANDARD. Bank 66's supply is not evidence of bank 65's voltage.

The candidate XDC deliberately leaves the clock IOSTANDARD unset and is disabled in the board project recipe. Do not suppress NSTD-1. The IP recipe requests 400 MHz from the onboard 100 MHz clock; this rate has only been modeled, not achieved in FPGA timing.

The generic receiver samples asynchronous D/S on rising edges with preserved synchronizer registers. After synthesis, identify the first-stage D/S input flops, review CDC, constrain only the intended asynchronous input paths, and retain timing through all later stages. Check synchronizer placement and routing skew; do not blanket-false-path the receiver. Physical sampling margin must include isolator/PCB skew and jitter.

The PE3 reference uses G15/K15 at LVCMOS18 for different carrier functions. The user has a custom carrier and confirms 3.3 V; PE3 carrier assignments must not overwrite those facts.

## Programming

User-reported cable: Digilent "FTAG-HS3", likely JTAG-HS3. Exact model, header mapping, reference voltage and Hardware Manager detection remain unverified. The remote SpaceWire device model is unknown.
